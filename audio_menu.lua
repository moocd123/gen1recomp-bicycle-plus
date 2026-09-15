-- Add the bicycle mixer controls to the game's actual AUDIO subpage.
-- v0.2.59 groups options using private, fixed membership lists. Decorating
-- the page after its own opener runs avoids fake native ids and preserves
-- the native widgets, touch/controller handling, and other mods' rows.
local AudioMenu = {}

function AudioMenu.init(mod, settings)
  local Runtime = require("src.mods.Runtime")
  local Assets = require("src.render.Assets")
  local Version = require("src.core.GameVersion")
  local Strings = require("src.core.Strings")
  local ownedHooks, ownedEvents = Runtime.hooks, Runtime.events
  local controller, installed = {}, {}
  local enabled, liveGame = true, nil
  local readySubscription
  local FILTERS = { "OFF", "1X", "2X", "3X" }
  local RIDING_MUSIC = { "bicycle", "area", "both" }
  local RIDING_LABELS = { bicycle="BICYCLE", area="AREA", both="BOTH" }
  local ids = {
    volume = "bicycle_plus.bike_volume",
    ridingMusic = "bicycle_plus.riding_music",
    bikeFilter = "bicycle_plus.bike_filter",
    sfxFilter = "bicycle_plus.sfx_filter",
  }

  local function active()
    if not enabled then return false end
    if Runtime.hooks ~= ownedHooks or Runtime.events ~= ownedEvents then
      controller.shutdown()
      return false
    end
    return not Runtime.safeMode
  end

  local function persist(game)
    if game and game.writeOptions then game:writeOptions()
    elseif game and game.persistOptions then game:persistOptions() end
  end

  -- Our setter persists and emits the change itself. Returning false avoids
  -- the Gen 1 native page performing a second write for the same key press.
  local function change(game, key, value)
    settings.setSetting(game, key, value)
    return false
  end

  local function filterRow(key, label, inherit)
    return {
      id = "bicycle_plus." .. key, label = Strings(label), port = true,
      value = function()
        if not active() then return Strings("OFF") end
        local level = tonumber(settings.getSetting(key)) or (inherit and -1 or 0)
        if inherit and level < 0 then return Strings("SAME") end
        return Strings(FILTERS[math.max(0, math.min(3, math.floor(level))) + 1])
      end,
      step = function(game, direction)
        if not active() then return false end
        local minimum = inherit and -1 or 0
        local value = tonumber(settings.getSetting(key)) or minimum
        return change(game, key, (value - minimum + (direction or 1)) % (4 - minimum) + minimum)
      end,
    }
  end

  local function volumeRow(key, label, inherit)
    return {
      id = "bicycle_plus." .. key, label = Strings(label), port = true,
      value = function()
        if not active() then return Strings("OFF") end
        local level = tonumber(settings.getSetting(key)) or (inherit and -1 or 7)
        if inherit and level < 0 then return Strings("SAME") end
        return level == 0 and Strings("OFF") or tostring(level)
      end,
      step = function(game, direction)
        if not active() then return false end
        local minimum = inherit and -1 or 0
        local level = tonumber(settings.getSetting(key)) or (inherit and -1 or 7)
        return change(game, key, math.max(minimum, math.min(7, level + (direction or 1))))
      end,
    }
  end

  local function songRow()
    return {id="bicycle_plus.song",label=Strings("BIKE SONG"),port=true,group=true,
      value=function()return Strings("CHOOSE MUSIC")end,
      activate=function(game)if active() and settings.openSongs then return settings.openSongs(game)end end}
  end

  local function cyclingRows()
    return {
      songRow(),
      { id = ids.ridingMusic, label = Strings("ON BIKE"), port = true,
        value = function()
          if not active() then return Strings("OFF") end
          return Strings(RIDING_LABELS[settings.getSetting("riding_music")] or "BOTH")
        end,
        step = function(game, direction)
          if not active() then return false end
          local value, index = settings.getSetting("riding_music"), #RIDING_MUSIC
          for i, choice in ipairs(RIDING_MUSIC) do
            if value == choice then index = i break end
          end
          return change(game, "riding_music",
            RIDING_MUSIC[(index - 1 + ((direction or 1) < 0 and -1 or 1)) % #RIDING_MUSIC + 1])
        end },
      volumeRow("riding_area_volume", "AREA VOL", true),
      filterRow("riding_area_filter", "AREA FILTER", true),
      volumeRow("bike_volume", "BIKE VOL", false),
      filterRow("bike_filter", "BIKE FILTER", false),
      volumeRow("riding_sfx_volume", "SFX VOL", true),
      filterRow("riding_sfx_filter", "SFX FILTER", true),
    }
  end

  local function cyclingOpener(parent, gen2)
    return {
      id = "bicycle_plus.cycling", label = Strings("CYCLING"), port = true, group = true,
      value = function() return Strings("ON-BIKE AUDIO") end,
      activate = function(game)
        if not active() then return nil end
        -- This is the same native page object that the game's private group
        -- opener builds: native drawing, input, scrolling and BACK handling.
        -- Gen 2's factory lacks opts.rows, so use its existing page metatable.
        local rows = cyclingRows()
        local page = setmetatable({game=game, rows=rows, view=rows,
          options=parent.options, index=1, scroll=0, sub=true}, getmetatable(parent))
        if gen2 then
          page.view = {}
          for i, row in ipairs(rows) do page.view[i] = row end
          page.view[#page.view+1] = {id="cancel", label=Strings("BACK"), cancel=true}
        end
        game.stack:push(page)
        return page
      end,
    }
  end

  local function augment(rows, extras)
    local present, result = {}, {}
    for _, row in ipairs(rows or {}) do
      if row.id then present[row.id] = true end
    end
    local function add(row)
      if not present[row.id] then result[#result+1]=row; present[row.id]=true end
    end
    local function addMissing()
      for _, row in ipairs(extras) do add(row) end
    end
    for _, original in ipairs(rows or {}) do
      if original.cancel or original.id == "cancel" then addMissing() end
      local row = original
      if row.id == "musicVol" or row.id == "musicFilter" then
        -- Preserve each native step/cycle callback and companion mod wrapper.
        row = {}
        for key, value in pairs(original) do row[key] = value end
        row.label = Strings(row.id == "musicVol" and "AREA VOL" or "AREA FILTER")
      end
      result[#result + 1] = row
      if row.id == "sfxVol" then add(extras[1]) end
    end
    addMissing()
    return result
  end

  local function decoratePage(page, game, gen2)
    if not (active() and type(page) == "table" and type(page.rows) == "table")
        or page._bicyclePlusAudioMenu == controller then return page end
    page._bicyclePlusAudioMenu = controller
    local extras = {filterRow("sfx_filter", "SFX FILTER", false), songRow(), cyclingOpener(page, gen2)}
    local rows, view = page.rows, page.view
    page.rows = augment(rows, extras)
    page.view = view == rows and page.rows or augment(view or rows, extras)
    if gen2 and type(page.cycle) == "function" then
      local previousCycle = page.cycle
      page.cycle = function(self, row, direction)
        local result = previousCycle(self, row, direction)
        -- Gen 2 normally persists only when its parent OPTIONS closes. An
        -- AUDIO page opened from BICYCLE + has no such parent on the stack.
        -- Persist its native controls immediately, just as Gen 1 does.
        if active() and self.options == (game.save and game.save.options)
            and row and row.id ~= ids.volume and row.id ~= ids.bikeFilter
            and row.id ~= ids.sfxFilter and row.id ~= ids.ridingMusic then persist(game) end
        return result
      end
    end
    return page
  end

  local function decorateRoot(screen, game, gen2)
    if not (type(screen) == "table" and type(screen.view) == "table") then
      return screen
    end
    for _, row in ipairs(screen.view) do
      if row.id == "group.audio" and type(row.activate) == "function"
          and row._bicyclePlusAudioMenu ~= controller then
        local previousActivate = row.activate
        row._bicyclePlusAudioMenu = controller
        row.activate = function(g, ...)
          local before = g.stack and g.stack:top()
          local result = previousActivate(g, ...)
          if active() then
            local page = type(result) == "table" and result
              or (g.stack and g.stack:top())
            if page ~= before then decoratePage(page, g, gen2) end
          end
          return result
        end
        -- The old private membership count cannot include the new rows.
        -- A descriptive value stays accurate even if another mod adds rows.
        if row.value then row.value = function() return Strings("VOLUME/FILTER") end end
      end
    end
    return screen
  end

  local function install(game)
    if not active() then return nil end
    local gen2 = Version.generation() == 2
    local path = gen2 and "src.ui.gen2.OptionsMenu" or "src.ui.OptionsMenu"
    local menu = require(path)
    if not installed[menu] then
      local previousNew = menu.new
      local wrapper
      wrapper = function(g, ...)
        local screen = previousNew(g, ...)
        if active() then decorateRoot(screen, g, gen2) end
        return screen
      end
      installed[menu] = { previous = previousNew, wrapper = wrapper }
      menu.new = wrapper
    end
    return menu, gen2
  end

  function controller.update(game)
    if not active() then return nil end
    liveGame = game or liveGame
    return install(liveGame)
  end

  function controller.open(game)
    game = game or liveGame
    if not (game and game.stack) then return nil end
    local menu, gen2 = install(game)
    if not menu then return nil end
    local opts = {}
    if gen2 then
      opts.options = game.save and game.save.options or game.options
    end
    local parent = menu.new(game, opts)
    for _, row in ipairs(parent.view or {}) do
      if row.id == "group.audio" and row.activate then
        local before = game.stack:top()
        row.activate(game)
        local page = game.stack:top()
        if page ~= before then
          if gen2 then
            local previousDone = page.onDone
            page.onDone = function(options)
              if previousDone then previousDone(options) end
              if active() then persist(game) end
            end
          end
          return page
        end
      end
    end
    return nil
  end

  function controller.shutdown()
    if not enabled then return end
    enabled, liveGame = false, nil
    for menu, entry in pairs(installed) do
      if menu.new == entry.wrapper then menu.new = entry.previous end
    end
    if type(readySubscription) == "function" then pcall(readySubscription) end
    -- Assets.register callbacks live for the process. They may retain this
    -- inert controller, but must not retain an old loader/game through its
    -- settings closures, event unsubscriber or previous factory wrappers.
    readySubscription, settings, mod = nil, nil, nil
    ownedHooks, ownedEvents = nil, nil
    installed = {}
  end
  controller.stop = controller.shutdown

  readySubscription = mod.events:on("game.ready", function(ev)
    controller.update(ev.game)
  end)
  Assets.register({
    invalidate = function()
      if Runtime.hooks ~= ownedHooks or Runtime.events ~= ownedEvents then
        controller.shutdown()
      end
    end,
    release = function() controller.shutdown() end,
  })
  -- Installation during mod load also covers the first OPTIONS opening,
  -- before a core.update callback has run. Only the active generation's
  -- module is loaded, respecting the engine's Gen 2 require gate.
  install()
  return controller
end

return AudioMenu
