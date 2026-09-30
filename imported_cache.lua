-- Exact, read-only, edition-qualified soundtrack access. No active cartridge
-- change, global prefix mutation or fallback to another game's unqualified cache.
local M={}
function M.init(mod)
 local Cache=require('src.import.CacheFs');local Save=require('src.core.SaveData')
 local V=require('src.core.GameVersion')
 local GBA={firered=true,leafgreen=true,emerald=true};local GB={red=true,blue=true,yellow=true,gold=true,silver=true,crystal=true}
 local api={}
 local function allowed(g,p)
  if not(GBA[g]or GB[g])or type(p)~='string'or p:find('..',1,true)or p:find('\\',1,true)then return false end
  return p=='data/generated/audio.lua'or p=='assets/generated/audio/programs.bin'
   or(GBA[g]and(p=='data/generated/gba/audio/index.lua'or p=='data/generated/gba/audio/samples.bin'
     or p:match('^data/generated/gba/audio/songs/%d+%.bin$')))
 end
 function api.read(g,rel)
  if not allowed(g,rel)then return nil,'Invalid soundtrack path'end
  local path=V.cachePrefix(g)..rel
  local ok,b=pcall(Cache.readAt,path)
  if ok and type(b)=='string'and #b>0 then return b end
  -- Portable/persistent storage can be readable even when the mounted virtual
  -- search path does not expose another generation's directory.
  local made,fs=pcall(Save.persistenceFs)
  if made and fs and fs.read then
   local good,value=pcall(fs.read,path)
   if good and type(value)=='string'and #value>0 then return value end
  end
  -- Dataset owns additional native GBA lookup paths. Only use it for the
  -- matching active game; it must never hand Red a different cartridge's data.
  if GBA[g]and V.get()==g and V.generation()==3 then
   local yes,value=pcall(function()return require('src.core.game3.dataset').cache():read(rel)end)
   if yes and type(value)=='string'and #value>0 then return value end
  end
  return nil,'IMPORT '..g:upper()..' IN THE LAUNCHER FIRST'
 end
 api.gba=GBA
 return api
end
return M
