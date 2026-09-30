-- Read the CURRENT game's native sound choice. Never write a native option.
local M={}
function M.mono(game)
 local V=require('src.core.GameVersion');local g=V.generation()
 local o=game and(game.options or(game.save and game.save.options))or{}
 if g==3 then
  local s=game and game.session and game.session.options
  local block=type(o[V.get()])=='table'and o[V.get()]or{}
  local value=type(s)=='table'and s.sound
  if value==nil then value=block.sound end
  return tonumber(value or 0)==0
 elseif g==2 then return o.sound~='STEREO'end
 -- Gen 1 has no MONO/STEREO option here. Keep a GBA track's own channel mix.
 return false
end
function M.fold(data)
 if not(data and data.getChannelCount and data:getChannelCount()==2)then return data end
 for i=0,data:getSampleCount()-1 do
  local sample=(data:getSample(i,1)+data:getSample(i,2))*.5
  data:setSample(i,1,sample);data:setSample(i,2,sample)
 end
 return data
end
return M
