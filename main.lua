-- Public unified package. Lazy dispatch keeps GBA code out of GB/GBC sessions.
return function(mod)
  local Version=require('src.core.GameVersion')
  local function module(name)return assert(load(assert(mod:read(name..'.lua')),'@'..mod.id..'/'..name))()end
  local H=module('colour_values').extend(module('hardware_colours'))
  local upgrade=module('public_upgrade').init(mod,H)
  assert(upgrade.prepare(), 'AUTOBIKE+ upgrade failed; previous settings are retained')
  mod.exports.publicUpgrade=upgrade
  upgrade.options(mod.game)
  mod.events:on('game.ready',function(e)upgrade.options(e and e.game or mod.game)end,1000)
  local profiles=module('profiles').init(mod,H)
  mod.exports.profiles=profiles
  local seed=assert(load(assert(mod:read('seed_options.lua')),'@'..mod.id..'/seed_options.lua'))().init(mod)
  mod.exports.seedForTest=seed
  seed(mod.game)
  local id=Version.get()
  local generation=Version.generation()
  local entry=generation==3 and 'g3/main.lua' or 'legacy_main.lua'
  if generation==3 and id~='firered' and id~='leafgreen' then
    error('AUTOBIKE+ supports FireRed and LeafGreen, not '..tostring(id),0)
  end
  local body=assert(mod:read(entry))
  return assert(load(body,'@'..mod.id..'/'..entry))()(mod)
end
