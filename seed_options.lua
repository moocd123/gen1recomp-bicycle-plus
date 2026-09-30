-- Read-only copy of existing stable preferences into this test mod's bucket.
-- Runs once per game. Existing test choices always win. No stable key is edited.
local M={}
function M.init(mod)
 local Runtime=require('src.mods.Runtime')
 local function copy(t,depth)
  if type(t)~='table'then return t end
  if (depth or 0)>8 then return nil end
  local out={};for k,v in pairs(t)do if type(k)=='string'or type(k)=='number'then out[k]=copy(v,(depth or 0)+1)end end;return out
 end
 return function(game)
  if Runtime.safeMode or mod.id=='bicycle_plus' or not game or not game.mods then return false end
  local o=game.options or(game.save and game.save.options);if type(o)~='table'then return false end
  o.modOptions=o.modOptions or{};game.mods.modOptions=game.mods.modOptions or{}
  local s=o.modOptions[mod.id]or{};local l=game.mods.modOptions[mod.id]or{}
  if s._unified_test_seeded or l._unified_test_seeded then return false end
  local old=o.modOptions.bicycle_plus or game.mods.modOptions.bicycle_plus or{}
  -- Paint and cycling audio now migrate through the shared profile journal.
  for _,k in ipairs({'auto_mount','sfx_filter','spelling'})do local v=old[k]
   if v~=nil and s[k]==nil and l[k]==nil then s[k]=copy(v);l[k]=copy(v)end
  end
  s._unified_test_seeded=true;l._unified_test_seeded=true
  o.modOptions[mod.id]=s;game.mods.modOptions[mod.id]=l
  if game.writeOptions then game:writeOptions()end
  return true
 end
end
return M
