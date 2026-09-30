-- AUTOBIKE+: one automatic mount opportunity per map visit, plus return
-- from Surf when it interrupted an actual bicycle ride.
-- Targets the Gen1ReComp++ 0.2.59 world implementations. This module registers
-- events but never replaces a game method, input binding, item, or map rule.
--
-- init(mod, getSetting) -> controller; call controller.update(game) from
-- input.step. The additional world.stepped listener catches the landing frame
-- when a held direction would otherwise immediately begin another step.

local GameVersion = require("src.core.GameVersion")
local M = {}

local function queued(list)
  return type(list) == "table" and next(list) ~= nil
end

local function gen1Ready(game, world)
  local stack, player, runner = game.stack, world.player, world.runner
  return stack and stack.top and stack:top() == world
    and player and not player.moving and not player.inputLocked
    and not player.spinning and not player.ledgeHop
    and not world.transitioning and not world.flyAnim and not world.flyFade
    and not world.flyArrive and not world.teleportOut and not world.spinArrive
    and not world.holeFall and not world.holeArrive
    and not world.engaging and not world.emote and not world.pikaHop
    and not world.healAnim and not world.playerHidden
    and not queued(world.scriptMoves) and not queued(world.pendingScripts)
    and not (runner and runner.isRunning and runner:isRunning())
end

local function gen2Ready(game, world)
  local stack, player = game.stack, world.player
  return game.phase == "play" and stack and stack.top and stack:top() == nil
    and player and not player.moving and not player.inputLocked
    and not world.battleActive and not world.queuedScript
    and not world.pendingSceneScript and not world.playerHidden
    and world.acceptsMenuInput and world:acceptsMenuInput()
end

local function pokemonControlled(game, world)
  -- Wilds of Kanto exposes the selected control mode before its first
  -- sprite refresh on a new map. Mounting at that point would force its
  -- Pokemon leader back into a trainer. Read the active mod's public
  -- export, never persisted options from an absent/disabled mod.
  local exports = game.mods and game.mods.exports
  local wilds = exports and exports.overworld_wild_spawns
  if wilds and type(wilds.controlMode) == "function" then
    local ok, mode = pcall(wilds.controlMode, game)
    if ok and (mode == "pokemon" or mode == "lead_trainer"
        or mode == "lead" or mode == "pack") then return true end
  end
  -- Also preserve a live Pokemon actor supplied by older follower builds.
  local player = world.player
  local def = player.sprite and player.sprite.def
  return player._pokepcAsPokemon == true
    or (def and def.id == "SPRITE_PLAYER_POKEMON") or false
end

function M.init(mod, getSetting)
  assert(mod and mod.events and mod.world, "Bicycle Plus needs the world API")
  assert(type(getSetting) == "function", "Bicycle Plus needs a settings getter")
  local controller, subscriptions = {}, {}
  local state = {}
  local active = true
  local Bike, FieldMoves

  local function reset()
    state = {
      pending = true, suppressed = false, lastRiding = nil,
      wasSurfing = false, returnFromSurf = false, dismountCandidate = false,
      mapId = nil, game = nil, save = nil, enabled = nil,
      reason = "waiting_for_world",
    }
  end
  reset()

  local function beginVisit(mapId)
    state.mapId = mapId
    state.pending = true
    state.suppressed = false
    -- A map load can legitimately dismount the rider. Do not mistake that
    -- engine transition for a manual dismount in the NEW map.
    state.lastRiding = nil
    state.wasSurfing, state.returnFromSurf, state.dismountCandidate = false, false, false
    state.reason = "entered_area"
  end

  local function worldOf(game)
    local api = mod.world
    if not (api and api.overworld) then return nil end
    local world = api:overworld()
    if world and world.map and world.player then return world end
    return nil
  end

  local function isRiding(game, world, gen2)
    if gen2 then return FieldMoves.isBiking(world.playerState) end
    return game.save and game.save.onBike == true
  end

  function controller.update(game)
    if not active then return end
    game = game or mod.game
    if not (game and game.save) then return end
    local world = worldOf(game)
    if not world then return end
    local gen2 = GameVersion.generation() == 2
    if gen2 and not Bike then
      Bike = require("src.world.gen2.Bike")
      FieldMoves = require("src.world.gen2.FieldMoves")
    end
    if state.game ~= game or state.save ~= game.save then
      reset()
      state.game, state.save = game, game.save
    end
    -- Fallback for another mod changing maps without the engine event. A
    -- graphical map.reloaded does not reset the user's manual choice.
    if state.mapId ~= world.map.id then beginVisit(world.map.id) end

    local enabled = getSetting("auto_mount") ~= false
    if state.enabled == false and enabled then
      -- Explicitly turning auto-mount back on is an intentional new request.
      beginVisit(world.map.id)
    end
    state.enabled = enabled

    local riding = isRiding(game, world, gen2)
    local surfing = gen2 and FieldMoves.isSurfing(world.playerState)
      or not gen2 and world.player.surfing == true
    local ready = gen2 and gen2Ready(game, world)
      or not gen2 and gen1Ready(game, world)

    if not enabled then
      state.pending, state.returnFromSurf, state.dismountCandidate = false, false, false
      state.lastRiding, state.wasSurfing = riding, surfing
      state.reason = "disabled"
      return
    end

    if surfing then
      -- Surf replaces the bike state; it is not a deliberate Bicycle dismount.
      -- Gen 1 clears onBike BEFORE its got-on textbox finishes, so remember a
      -- loss of the bike while control was busy until the actual Surf arrives.
      if not state.wasSurfing and not state.suppressed
          and (state.lastRiding or state.dismountCandidate) then
        state.returnFromSurf = true
      end
      if state.returnFromSurf then state.pending, state.suppressed = true, false end
      state.wasSurfing, state.lastRiding, state.dismountCandidate = true, false, false
      state.reason = "surfing"
      return
    end
    if state.wasSurfing then
      state.wasSurfing = false
      if state.returnFromSurf then
        state.pending, state.suppressed = true, false
        state.reason = "returning_from_surf"
      end
      state.returnFromSurf = false
    end

    if riding then
      state.suppressed, state.pending = false, false
      state.dismountCandidate, state.returnFromSurf = false, false
      state.reason = "already_riding"
    elseif state.lastRiding == true then
      if ready then
        state.suppressed, state.pending = true, false
        state.reason = "dismounted_for_this_visit"
      else
        state.dismountCandidate = true
        state.reason = "waiting_for_dismount_result"
      end
    elseif state.dismountCandidate and ready then
      -- No Surf followed: keep the original manual/scripted-dismount rule.
      state.suppressed, state.pending, state.dismountCandidate = true, false, false
      state.reason = "dismounted_for_this_visit"
    end
    state.lastRiding = riding
    if state.dismountCandidate or not state.pending or state.suppressed or riding then return end

    if pokemonControlled(game, world) then
      -- Keep this visit pending. Choosing trainer control later permits
      -- its original automatic mount; a deliberately mounted bike above
      -- is left alone, so the normal Bicycle item remains usable.
      state.reason = "waiting_for_trainer_control"
      return
    end

    if not ready then
      state.reason = "waiting_for_control"
      return
    end
    local owned = (game.save.inventory or {}).BICYCLE
    if type(owned) ~= "number" or owned <= 0 then
      state.pending = false
      state.reason = "no_bicycle"
      return
    end

    if gen2 then
      local environment = world.map.def and world.map.def.environment
      if not Bike.environmentAllows(environment) then
        state.pending = false
        state.reason = "area_disallows_cycling"
        return
      end
      -- Exact game's environment, tile-permission, player-state and forced
      -- bicycle checks. In particular, surfing/Lapras cannot become a bike.
      local action = Bike.tryBike({
        state = world.playerState,
        environment = environment,
        collision = world:playerCollision(),
        alwaysOnBike = world:alwaysOnBike(),
      })
      if action ~= "mount" then
        state.reason = "waiting_for_rideable_tile"
        return
      end
      -- This is the state operation in the native registered-bike script,
      -- without queueing dialogue or overwriting another queued script.
      -- Its native sprite/palette method remains in the call chain for skins.
      world:applyPlayerState(FieldMoves.PLAYER_BIKE)
      world:playBikeMusic()
    else
      if not (world.bikeAllowed and world:bikeAllowed(world.map.id)) then
        state.pending = false
        state.reason = "area_disallows_cycling"
        return
      end
      if world.player.surfing then
        state.reason = "waiting_for_rideable_tile"
        return
      end
      -- Same writes as the engine's forced-bike tile and bag entry paths.
      -- onBike is synchronized by the native world each tick; set the sprite
      -- mirror now too so a landing-frame mount renders immediately.
      game.save.onBike, world.player.onBike = true, true
      require("src.core.Music").playMap(
        game.data, world.map.id, true, false)
    end
    state.lastRiding = true
    state.pending, state.suppressed = false, false
    state.reason = "automounted"
  end

  function controller.status()
    return {
      mapId = state.mapId, pending = state.pending,
      suppressed = state.suppressed, riding = state.lastRiding,
      enabled = state.enabled, reason = state.reason,
      returningFromSurf = state.returnFromSurf, surfing = state.wasSurfing,
    }
  end

  function controller.stop()
    active = false
    for _, unsubscribe in ipairs(subscriptions) do unsubscribe() end
    subscriptions = {}
    -- Disabling a mod should not knock the player off a bicycle.
  end

  if mod.hooks and mod.hooks.wrap then
    subscriptions[#subscriptions + 1] = mod.hooks:wrap("item.use", function(nextFn, game, battle, id, ...)
      local wasOnBike = active and GameVersion.generation() == 1 and id == "BICYCLE"
        and not battle and game and game.save and game.save.onBike == true
      local function packed(...) return {n=select("#", ...), ...} end
      local results = packed(nextFn(game, battle, id, ...))
      if wasOnBike and game.save.onBike ~= true and state.game == game then
        state.suppressed, state.pending = true, false
        state.returnFromSurf, state.dismountCandidate, state.lastRiding = false, false, false
        state.reason = "manual_bicycle_dismount"
      end
      return (table.unpack or unpack)(results, 1, results.n)
    end, -20)
  end

  subscriptions[#subscriptions + 1] = mod.events:on("map.entered", function(e)
    if active and e and e.mapId then beginVisit(e.mapId) end
  end, -20)
  subscriptions[#subscriptions + 1] = mod.events:on("world.stepped", function()
    controller.update(mod.game)
  end, -20)
  subscriptions[#subscriptions + 1] = mod.events:on("save.loading", reset)
  subscriptions[#subscriptions + 1] = mod.events:on("game.ready", reset)
  return controller
end

return M
