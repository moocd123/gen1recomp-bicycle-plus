-- Bicycle Plus: independent wheel, stripe, centre, edge, detail and handlebar colours.
-- Pixel ownership is classified on the untouched source sheet so trainer
-- palettes cannot collapse the two wheel shades into one. Rider art stays
-- outside the verified bicycle masks; other renderers keep their full chain.
local Colours = {}
function Colours.init(mod, getSetting, Parts, Hardware)
  assert(Hardware and Hardware.canonical and Hardware.rgb, "Hardware colour catalogue required")
  assert(Parts and Parts.classify and Parts.masks, "Bicycle part masks are required")
  local SpriteRenderer = require("src.render.SpriteRenderer")
  local PaletteFX = require("src.render.PaletteFX")
  local GbcPalette = require("src.render.GbcPalette")
  local Assets = require("src.render.Assets")
  local Runtime = require("src.mods.Runtime")
  local ownedHooks, ownedEvents = Runtime.hooks, Runtime.events
  local api = {}
  api.options = Hardware.legacyOptions

  local RED, GEN2 = Parts.legacyMasks.red, Parts.legacyMasks.gen2
  local supportedSkins = {
    Brendan=true, Dawn=true, ["Dawn P"]=true, ["Green Ad"]=true,
    Hilbert=true, Hilda=true, Leaf=true, Lyra=true, May=true,
    Michael=true, Nate=true, Rosa=true, Wes=true,
  }
  -- Public pure metadata also makes the mask boundaries testable without GPU.
  api.masks = { red = RED, gen2 = GEN2 }
  api.partsMasks = Parts.masks
  local liveGame, enabled, suppress = nil, true, false
  local cache = setmetatable({}, { __mode = "k" })
  local previewCache, lastError = nil, nil
  local baseResolve, baseDraw = SpriteRenderer.resolveImage, SpriteRenderer.draw
  local baseSpriteObp, baseSetObjPalette = PaletteFX.spriteObp, SpriteRenderer.setObjPalette

  -- Trainer Skins 0.1.0 and 0.2.0 leave a once-installed palette wrapper on
  -- the engine module when returning to the launcher. That wrapper captures
  -- its FIRST loader's save, so the next game's colour picker can save RED
  -- while the renderer still reads the previous game's GREEN. Read the live
  -- trainer save only for those two verified versions and their own palette
  -- groups. Every other palette provider keeps the result of its full chain.
  local trainerPalettes010 = {
    red={248,56,8}, green={0,132,0}, blue={0,0,255},
  }
  local trainerPalettes020 = {
    red={255,0,0}, green={58,189,25}, blue={82,74,255},
    yellow={173,90,0}, purple={139,0,186}, orange={191,57,0},
    cyan={88,184,248}, pink={249,0,170}, brown={58,44,19}, gray={75,75,75},
  }
  local trainerPaletteCache = {}
  local function liveTrainerPalette(def, group, allowNativeGen2)
    if not enabled or Runtime.safeMode or not (liveGame and def and def._trainerSkinId)
        or type(group) ~= "string" then return nil end
    local trainerGroup = group:match("^trainer_skin_")
      or (allowNativeGen2 and (group:match("^gen2:") or group:match("^bicycle_plus:trainer_skin:")))
    if not trainerGroup then return nil end
    local loader = liveGame.mods
    local installed = loader and loader.mods and loader.mods.trainer_skins
    local version = installed and installed.manifest and installed.manifest.version
    local choices = version == "0.1.0" and trainerPalettes010
      or version == "0.2.0" and trainerPalettes020
    if not choices or installed.state ~= "loaded" then return nil end
    local save = loader.modSave and loader.modSave.trainer_skins or {}
    local role = def._trainerSkinRole == "rival" and "rival" or "player"
    local selected = save[role == "rival" and "rival_skin_color" or "skin_color"] or "green"
    if version == "0.2.0" and selected == "truecolor" then return nil end
    if not choices[selected] then selected = "green" end
    local accent = choices[selected]
    local key = version .. ":" .. role .. ":" .. tostring(def._trainerSkinId) .. ":" .. selected
    local colors = trainerPaletteCache[key]
    if not colors then
      colors = {{255,255,255},{239,156,107},accent,{0,0,0}}
      trainerPaletteCache[key] = colors
    end
    return colors, "bicycle_plus:trainer_skin:" .. key
  end
  local spriteObpWrapper
  if type(baseSpriteObp) == "function" then
    spriteObpWrapper = function(def, seed, ...)
      local colors, group = baseSpriteObp(def, seed, ...)
      local current, currentGroup = liveTrainerPalette(def, group)
      if current then return PaletteFX.darkObp(current,currentGroup) end
      return colors, group
    end
    PaletteFX.spriteObp = spriteObpWrapper
  end
  local setObjPaletteWrapper
  if type(baseSetObjPalette) == "function" then
    setObjPaletteWrapper = function(renderer, colors, group, ...)
      local current, currentGroup = liveTrainerPalette(renderer and renderer.def,group,true)
      return baseSetObjPalette(renderer,current or colors,currentGroup or group,...)
    end
    SpriteRenderer.setObjPalette = setObjPaletteWrapper
  end

  local partKeys = {rims="bike_colour", stripes="bike_stripes_colour",
    centres="bike_centres_colour", tyres="bike_tyres_colour", frame="bike_frame_colour", handlebars="bike_handlebars_colour"}
  local partOrder = {"rims", "stripes", "centres", "tyres", "frame", "handlebars"}
  local function settings(rimOverride)
    local choices, active = {}, false
    for _, part in ipairs(partOrder) do
      local id = getSetting(partKeys[part], "original")
      if type(rimOverride) == "table" and rimOverride[partKeys[part]] ~= nil then
        id = rimOverride[partKeys[part]]
      elseif type(rimOverride) == "string" and part == "rims" then id = rimOverride end
      choices[part] = Hardware.canonical(id) or "original"
      if choices[part] ~= "original" then active = true end
    end
    return choices, active
  end
  local function generation2(game)
    return game and game.data and game.data.gen2Sprites ~= nil
  end
  local function worldOf(game)
    return game and (game.world or game.overworld)
  end
  local function paletteAllowsColour()
    local allowed = not PaletteFX.honorsTrueColor or PaletteFX.honorsTrueColor()
    local custom = generation2(liveGame) and GbcPalette.customRamp or PaletteFX.customRamp
    return allowed and not custom
  end

  -- Retro and custom display palettes deliberately remap trainer colours in
  -- the engine itself. Offer the same full-colour mode used by native options
  -- explicitly; merely opening a preview must never change the live game.
  function api.needsColourMode(game)
    if generation2(game or liveGame) then
      return GbcPalette.mode ~= "gbc" or GbcPalette.customRamp ~= nil
    end
    return not (not PaletteFX.honorsTrueColor or PaletteFX.honorsTrueColor())
      or PaletteFX.customRamp ~= nil
  end
  function api.colourModeName(game)
    return generation2(game or liveGame) and "GBC" or "ADVANCED"
  end
  function api.enableColourMode(game)
    game = game or liveGame
    if not enabled or Runtime.safeMode or not (game and game.save and game.save.options) then
      return false
    end
    local options = game.save.options
    options.palette = ""
    if generation2(game) then
      options.color = "gbc"
      GbcPalette.applyOptions(options)
    else
      options.colors = "redpp"
      PaletteFX.applyOptions(options)
    end
    if game.writeOptions then game:writeOptions() end
    return true
  end

  -- Explicit screen zones survive the retro-mode remap. markTrueColor alone
  -- is intentionally ignored by the engine outside Advanced/GBC, which made
  -- the old preview turn every selection into the menu's red/green shade.
  function api.previewZones(game, x, y, scale)
    scale = scale or 2
    return {{colors=false,x=x or 16,y=y or 56,w=64*scale,h=16*scale}}
  end
  local function maskFor(renderer)
    if not (renderer and renderer.def and renderer.frameWidth == 16
        and renderer.frameHeight == 16) then return nil end
    local def = renderer.def
    if def._trainerSkinId then
      return supportedSkins[def._trainerSkinId] and GEN2 or nil
    end
    -- A different mod can shadow a vanilla pathname with unrelated art.
    -- There is no semantic bike-pixel API for that art, so preserve it.
    if Assets.resolve and Assets.resolve(def.image) ~= def.image then return nil end
    local path = tostring(def.image or ""):lower()
    if path:match("/red_bike%.png$") then return RED end
    if path:match("/chris_bike%.png$") or path:match("/kris_bike%.png$")
        or path:match("/sprite_chris_bike%.png$")
        or path:match("/sprite_kris_bike%.png$") then return GEN2 end
    return nil
  end
  api.maskFor = maskFor

  local function isLiveBike(renderer)
    if not enabled or not liveGame then return false end
    if Runtime.hooks ~= ownedHooks or Runtime.events ~= ownedEvents then
      api.shutdown()
      return false
    end
    if Runtime.safeMode then return false end
    local world = worldOf(liveGame)
    local p = world and world.player
    if not p or p.fishing then return false end
    if generation2(liveGame) then
      return world.playerState == "bike" and renderer == p.sprite
    end
    return not p.surfing and (p.onBike or liveGame.save and liveGame.save.onBike)
      and renderer == p.bikeSprite
  end

  -- Readback fallback for textures supplied by a different mod. Native and
  -- Trainer Skins images take the CPU path below, without a framebuffer read.
  local function imageDataOf(image)
    local G = love.graphics
    local w, h = image:getDimensions()
    local canvas = G.newCanvas(w, h, { readable = true })
    G.push("all")
    local ok, err = pcall(function()
      G.setCanvas(canvas)
      G.origin()
      G.setShader()
      G.setScissor()
      G.clear(0, 0, 0, 0)
      G.setBlendMode("replace", "premultiplied")
      G.setColor(1, 1, 1, 1)
      G.draw(image, 0, 0)
    end)
    G.pop()
    if not ok then
      if canvas.release then canvas:release() end
      error(err, 0)
    end
    local data = canvas:newImageData()
    if canvas.release then canvas:release() end
    return data
  end

  local function withFullColour(fn)
    -- This is a synchronous image lookup, not a display-mode change. Using
    -- setMode here would reload the map and break a user's manual dismount.
    local pfMode, pfRamp = PaletteFX.mode, PaletteFX.customRamp
    local gbcMode, gbcRamp = GbcPalette.mode, GbcPalette.customRamp
    PaletteFX.mode, PaletteFX.customRamp = "redpp", nil
    GbcPalette.mode, GbcPalette.customRamp = "gbc", nil
    local ok, result = pcall(fn)
    PaletteFX.mode, PaletteFX.customRamp = pfMode, pfRamp
    GbcPalette.mode, GbcPalette.customRamp = gbcMode, gbcRamp
    if not ok then error(result, 0) end
    return result
  end

  local function nativeImageData(renderer, original)
    local def = renderer.def
    local colors, group, expected
    if def.trueColor and PaletteFX.honorsTrueColor() then
      expected = Assets.image(def.image)
    else
      if renderer.objColors then
        colors, group = renderer:gen2Obp()
      elseif PaletteFX.usesGbcPack() then
        colors, group = PaletteFX.spriteObp(def,renderer.seed)
      elseif PaletteFX.usesSpriteObp() then
        colors, group = PaletteFX.ogObj()
      else
        colors, group = PaletteFX.dmgObj()
      end
      if colors then expected = SpriteRenderer.obpImage(def.image,colors,group) end
    end
    -- A different resolver can return its own texture. Keep that complete
    -- result through readback instead of reconstructing or replacing its art.
    if original ~= expected then return nil end
    local raw = Assets.imageData(def.image)
    local w, h = raw:getDimensions()
    local combined = love.image.newImageData(w, h)
    -- Retain untouched raw pixels for part classification. Palette bakes can
    -- make distinct source shades identical (or very dark); classify first.
    for y = 0, h - 1 do
      for x = 0, w - 1 do
        local r, g, b, a = raw:getPixel(x, y)
        if colors and a ~= 0 then
          if r > 0.83 then a = 0
          else
            local c = r > 0.5 and colors[2] or r > 0.17 and colors[3] or colors[4]
            r, g, b = c[1]/255, c[2]/255, c[3]/255
          end
        end
        combined:setPixel(x, y, r, g, b, a)
      end
    end
    return combined, raw
  end

  local MAX_VARIANTS = 32
  local function colourImages(renderer, original, choices, preview)
    local masks = maskFor(renderer)
    local active = false
    for _, part in ipairs(partOrder) do
      if choices[part] ~= "original" then active = true; break end
    end
    if not active or not masks then return nil end
    local kind = masks == RED and "red" or "gen2"
    local variants = cache[original]
    if not variants then variants = {items={},order={}}; cache[original] = variants end
    -- Each native palette has its own original image; image identity plus
    -- source path, mask identity and all six choices fully describe a bake.
    local key = tostring(renderer.def.image) .. ":" .. tostring(masks)
    for _, part in ipairs(partOrder) do key = key .. ":" .. choices[part] end
    if variants.items[key] ~= nil then return variants.items[key] or nil end
    local selectedRGB = {}
    for _,part in ipairs(partOrder) do selectedRGB[part] = Hardware.rgb(choices[part]) end
    local combined, raw, overlay
    local ok, result = pcall(function()
      local function sourcePixels()
        combined, raw = nativeImageData(renderer,original)
      end
      local sourceOk = pcall(function()
        if preview then withFullColour(sourcePixels) else sourcePixels() end
      end)
      if not sourceOk or not combined then
        if combined and combined.release then combined:release() end
        if raw and raw.release then raw:release() end
        combined, raw = nil, nil
        -- Preserve a different mod's resolved texture. Only classify known
        -- bike-owned coordinates using its native source sheet; never rebuild
        -- the trainer or replace the other mod's transformations.
        combined = imageDataOf(original)
        raw = Assets.imageData(renderer.def.image)
      end
      local w, h = combined:getDimensions()
      local rw, rh = raw:getDimensions()
      if w ~= 16 or h < 48 or h % 16 ~= 0 or rw ~= w or rh ~= h then return false end
      overlay = love.image.newImageData(w, h)
      for f = 0, math.floor(h / 16) - 1 do
        for y = 0, 15 do
          for x = 0, 15 do
            local row = y + f * 16
            local r, g, b, a = raw:getPixel(x, row)
            local part = Parts.classify(kind, f % 6 + 1, x, y, r, g, b, a,
              choices.stripes ~= "original")
            local c = part and selectedRGB[part]
            if c then
              local _, _, _, alpha = combined:getPixel(x, row)
              if alpha > 0.01 then
                local rr, gg, bb = c[1]/255, c[2]/255, c[3]/255
                combined:setPixel(x, row, rr, gg, bb, alpha)
                overlay:setPixel(x, row, rr, gg, bb, alpha)
              end
            end
          end
        end
      end
      local fullImage = love.graphics.newImage(combined)
      local overlayImage = love.graphics.newImage(overlay)
      fullImage:setFilter("nearest", "nearest")
      overlayImage:setFilter("nearest", "nearest")
      return { full = fullImage, overlay = overlayImage }
    end)
    for _, data in pairs({combined=combined,raw=raw,overlay=overlay}) do
      if data.release then pcall(data.release,data) end
    end
    if not ok then lastError = tostring(result); result = false end
    -- RGB555 gives each part 32,768 colours plus ORIGINAL. Keep a bounded
    -- working set while browsing, without releasing an image that a later
    -- renderer may still hold; LOVE garbage collection retires evicted ones.
    if #variants.order >= MAX_VARIANTS then
      local evicted = table.remove(variants.order,1)
      variants.items[evicted] = nil
    end
    variants.order[#variants.order+1] = key
    variants.items[key] = result
    return result or nil
  end

  local function uncolouredImage(renderer)
    local old = suppress
    suppress = true
    -- Go through today's complete wrapper chain, including wrappers loaded
    -- after this mod. Only our own recolouring is temporarily suppressed.
    local ok, result = pcall(SpriteRenderer.resolveImage, renderer)
    suppress = old
    if not ok then error(result, 0) end
    return result
  end

  local function previewImage(renderer)
    -- Resolve one image with the full-colour palette, then restore all live
    -- palette state even if a different mod's resolver raises an error. Raw
    -- assignments are intentional: setMode() reloads maps, which a preview
    -- must not do. Native bakes have distinct cache keys for each palette.
    return withFullColour(function()return uncolouredImage(renderer)end)
  end

  local resolveWrapper
  resolveWrapper = function(renderer, ...)
    local original = baseResolve(renderer, ...)
    if suppress or not isLiveBike(renderer) or not paletteAllowsColour() then
      return original
    end
    local changed = colourImages(renderer, original, (settings()))
    return changed and changed.full or original
  end
  SpriteRenderer.resolveImage = resolveWrapper

  local drawWrapper
  drawWrapper = function(renderer, px, py, camX, camY, facing, phase, flip,
      topHalf, forceFlip, frameOverride, oamRow)
    -- First preserve the whole original draw chain, including every other
    -- mod's drawing work. Then add a transparent bicycle-only overlay.
    local result = baseDraw(renderer, px, py, camX, camY, facing, phase, flip,
      topHalf, forceFlip, frameOverride, oamRow)
    if suppress or not isLiveBike(renderer) or not paletteAllowsColour() then return result end
    local choices, active = settings()
    if not active then return result end
    local changed = colourImages(renderer, uncolouredImage(renderer), choices)
    if not changed then return result end
    local geometry = renderer:getPoseGeometry(facing, phase, flip)
    local frame, mirror = geometry.frame, geometry.mirror
    if frameOverride and renderer.frames[frameOverride] then
      frame, mirror = frameOverride, false
    end
    if forceFlip then mirror = true end
    local quad = renderer.frames[frame]
    if not quad then return result end
    local x, y = renderer:getScreenOrigin(px, py, camX, camY)
    -- Mirror the engine's OAM row split exactly. Repainting a full frame over
    -- a cropped draw can otherwise reveal parts behind foreground tiles.
    if oamRow == "bottom" then topHalf = false
    elseif oamRow == "top" then topHalf = true end
    if topHalf then
      quad = renderer.halfFrames and renderer.halfFrames[frame]
      if not quad then return result end
    elseif oamRow == "bottom" then
      quad = renderer.bottomFrames and renderer.bottomFrames[frame]
      if not quad then return result end
      y = y + 8
    end
    local G = love.graphics
    G.push("all")
    G.setShader()
    G.setColor(1, 1, 1, 1)
    G.setBlendMode("alpha")
    if mirror then G.draw(changed.overlay, quad, x+16, y, 0, -1, 1)
    else G.draw(changed.overlay, quad, x, y) end
    G.pop()
    return result
  end
  SpriteRenderer.draw = drawWrapper

  function api.update(game)
    if not enabled then return end
    if Runtime.hooks ~= ownedHooks or Runtime.events ~= ownedEvents then
      api.shutdown()
      return
    end
    liveGame = game
    if generation2(game) then
      local world = worldOf(game)
      local sprite = world and world.player and world.player.sprite
      if sprite then
        local colors, group = liveTrainerPalette(sprite.def,sprite.objGroup,true)
        if colors and sprite.objGroup ~= group then sprite:setObjPalette(colors,group) end
      end
    end
  end

  local function bikeForPreview(game)
    local world = worldOf(game)
    local p = world and world.player
    if not p then return nil end
    if not generation2(game) then return p.bikeSprite end
    if world.playerState == "bike" then return p.sprite end
    local gender = world.playerGender and world:playerGender()
    local name = gender == "female" and "SPRITE_KRIS_BIKE" or "SPRITE_CHRIS_BIKE"
    local def = world.sprites and (world.sprites[name] or world.sprites.SPRITE_CHRIS_BIKE)
    if not def then return nil end
    local ref = p.sprite
    local key = tostring(def.image) .. ":" .. tostring(def.trueColor)
      .. ":" .. tostring(def._trainerSkinId) .. ":" .. tostring(ref and ref.objGroup)
    if not previewCache or previewCache.key ~= key then
      local sprite = SpriteRenderer.new(def, "player")
      if ref and ref.objColors then
        sprite:setObjPalette(ref.objColors, ref.objGroup)
      elseif world.applySpritePalette then
        world:applySpritePalette({sprite = sprite, spriteDef = def})
      end
      previewCache = {key = key, sprite = sprite}
    end
    return previewCache.sprite
  end

  -- Choose the mapping from the artwork, not just the game edition.
  function api.artStyle(game)
    local renderer=bikeForPreview(game or liveGame)
    local masks=renderer and maskFor(renderer)
    if masks==RED then return "GEN 1" end
    if masks==GEN2 then return "GEN 2" end
    return renderer and "CUSTOM" or "NONE"
  end

  function api.status(game)
    if lastError then return "Colour readback unavailable" end
    if api.needsColourMode(game) then return "Requires Advanced/GBC colour" end
    local renderer = bikeForPreview(game or liveGame)
    if not renderer then return "Load a game to preview" end
    if not maskFor(renderer) then return "Custom bike art kept original" end
    return "Bicycle colour regions"
  end

  -- Draw three live-skin directions. At scale 2 the preview occupies 128x32.
  function api.drawPreview(game, x, y, scale, timer, colourOverride)
    local renderer = bikeForPreview(game or liveGame)
    if not renderer then return false, api.status(game) end
    local original = previewImage(renderer, game or liveGame)
    local choices = settings(colourOverride)
    local changed = colourImages(renderer, original, choices, true)
    local image = changed and changed.full or original
    local phase = math.floor((timer or 0) / 0.22) % 2
    scale = scale or 2
    local G = love.graphics
    G.push("all")
    G.setShader()
    G.setColor(1, 1, 1, 1)
    for index, facing in ipairs({"down", "up", "left"}) do
      local geometry = renderer:getPoseGeometry(facing, phase, false)
      local dx = x + (index-1)*24*scale
      if geometry.mirror then
        G.draw(image, geometry.quad, dx+16*scale, y, 0, -scale, scale)
      else G.draw(image, geometry.quad, dx, y, 0, scale, scale) end
    end
    G.pop()
    if paletteAllowsColour() and PaletteFX.markTrueColor then
      PaletteFX.markTrueColor(x, y, 64*scale, 16*scale)
    end
    return true, api.status(game)
  end

  function api.drawSidePreview(game, x, y, scale, timer, overrides)
    local renderer = bikeForPreview(game or liveGame)
    if not renderer then return false, api.status(game) end
    local original = previewImage(renderer)
    local changed = colourImages(renderer, original, (settings(overrides)), true)
    local image = changed and changed.full or original
    local pose = renderer:getPoseGeometry("left", math.floor((timer or 0)/0.22)%2, false)
    scale = scale or 2
    local G=love.graphics
    G.push("all"); G.setShader(); G.setColor(1,1,1,1)
    if pose.mirror then G.draw(image,pose.quad,x+16*scale,y,0,-scale,scale)
    else G.draw(image,pose.quad,x,y,0,scale,scale) end
    G.pop()
    return true, api.status(game)
  end

  -- Gen 2's CLASSIC post-pass does not consult a screen's sgbPalettes method.
  -- Exempt only this preview from that post-pass; the rest of the menu and
  -- the live world keep the user's chosen display mode.
  mod.hooks:wrap("render.zones", function(next, game, zones)
    zones = next(game, zones)
    local top = game and game.stack and game.stack:top()
    if enabled and not Runtime.safeMode and generation2(game)
        and top and (top.screenId == "BicyclePlusColours" or top.screenId == "BicyclePlusPicker")
        and type(zones) == "table" and zones[1] then
      local out = {}
      for i, zone in ipairs(zones) do out[i] = zone end
      local rect = top.bicyclePlusPreviewRect or {x=16,y=56,scale=2}
      local zone = top.screenId == "BicyclePlusPicker"
        and {colors=false,x=0,y=0,w=160,h=144}
        or api.previewZones(game,rect.x,rect.y,rect.scale)[1]
      -- Gen 2 post-pass zones span the complete Playfield, whereas this
      -- opaque menu is drawn at the native integer letterbox fit. Convert
      -- through the actual viewport/origin/scale; a fixed extra row fails on
      -- portrait displays, touch-skin cutouts and shifted screen positions.
      if type(game.frameFit) == "function" then
        local Viewport = require("src.render.GameViewport")
        local Playfield = require("src.render.Playfield")
        local w, h = Viewport.dimensions()
        local px, py, pw, ph = Playfield.rect(w,h)
        local fit, ox, oy = game:frameFit(w,h)
        if pw > 0 and ph > 0 then
          zone.x, zone.y = (ox + zone.x*fit - px)*160/pw,
            (oy + zone.y*fit - py)*144/ph
          zone.w, zone.h = zone.w*fit*160/pw, zone.h*fit*144/ph
        end
      end
      out[#out+1] = zone
      return out
    end
    return zones
  end)

  local function clearCache()
    for _, variants in pairs(cache) do
      for _, pair in pairs(variants.items) do
        if pair then
          if pair.full.release then pcall(pair.full.release, pair.full) end
          if pair.overlay.release then pcall(pair.overlay.release, pair.overlay) end
        end
      end
    end
    cache = setmetatable({}, { __mode = "k" })
    previewCache, lastError = nil, nil
  end
  function api.shutdown()
    enabled = false
    liveGame = nil
    ownedHooks, ownedEvents = nil, nil
    -- Restore only if we are still the outermost wrapper. A later wrapper
    -- keeps its intact chain; our disabled link becomes a pure pass-through.
    if SpriteRenderer.resolveImage == resolveWrapper then
      SpriteRenderer.resolveImage = baseResolve
    end
    if SpriteRenderer.draw == drawWrapper then SpriteRenderer.draw = baseDraw end
    if spriteObpWrapper and PaletteFX.spriteObp == spriteObpWrapper then
      PaletteFX.spriteObp = baseSpriteObp
    end
    if setObjPaletteWrapper and SpriteRenderer.setObjPalette == setObjPaletteWrapper then
      SpriteRenderer.setObjPalette = baseSetObjPalette
    end
    clearCache()
  end
  Assets.register({
    invalidate = function()
      if Runtime.hooks ~= ownedHooks or Runtime.events ~= ownedEvents then
        api.shutdown()
      else clearCache() end
    end,
    release = function() api.shutdown() end,
  })
  return api
end
return Colours
