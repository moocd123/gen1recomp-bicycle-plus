-- Gen 3-native FireRed song browser. Current FireRed songs and already-imported
-- Gen 1/2 soundtracks share one selector. Local audio files are added separately.
local SongMenu={}
function SongMenu.new(mod,settings,menu,Catalog,services)
 local S=services or{}
 local Audio=S.Audio or require('src.core.game3.audio')
 local Legacy=S.Legacy
 local api={}
 local function selected(game)return settings.get('bike_song',game)or'original'end
 local function choose(game,key)return settings.set(game,'bike_song',key)end
 function api.describe(game)
  local key=selected(game)
  if key=='original'or key:match('^firered:%d+$')or key:match('^fr:%d+$')then
   return Catalog.describe(key)
  end
  if Legacy and Legacy.describe then return Legacy.describe(key)or'MISSING SONG'end
  return'MISSING SONG'
 end
 function api.openCurrent(game)
  local rows={}
  for _,song in ipairs(Catalog.available(Audio))do
   local row=song
   rows[#rows+1]={label=row.name,
    value=function()return selected(game)==row.key and'ON'or nil end,
    activate=function()return choose(game,row.key)end}
  end
  if #rows==0 then rows[1]={label='FIRERED SOUNDTRACK UNAVAILABLE'}end
  return menu.open(game,'FIRERED SOUNDTRACK',rows)
 end
 function api.openLegacyEdition(game,edition,label)
  local rows,err
  if Legacy and Legacy.gameSongs then rows,err=Legacy.gameSongs(edition,game)end
  if type(rows)~='table'then
   rows={{label=tostring(err or'SOUNDTRACK UNAVAILABLE')}}
  else
   local out={}
   for _,song in ipairs(rows)do
    local row=song
    out[#out+1]={label=row.name,
     value=function()return selected(game)==row.id and'ON'or nil end,
     activate=function()return choose(game,row.id)end}
   end
   rows=#out>0 and out or{{label='NO PLAYABLE SONGS FOUND'}}
  end
  return menu.open(game,(label or edition):upper()..' SOUNDTRACK',rows)
 end
 function api.openLegacy(game)
  local rows={}
  local editions={}
  if Legacy and Legacy.editions then editions=Legacy.editions(game)or{}end
  for _,edition in ipairs(editions)do
   local row=edition
   rows[#rows+1]={label=row.label,
    value=function()return row.available and nil or'NOT IMPORTED'end,
    activate=row.available and function()return api.openLegacyEdition(game,row.id,row.label)end or nil}
  end
  if #rows==0 then rows[1]={label='NO GEN 1 OR 2 IMPORTS FOUND'}end
  return menu.open(game,'OTHER GAME SONGS',rows)
 end
 function api.open(game)
  local rows={
   {label='ORIGINAL BICYCLE THEME',
    value=function()return selected(game)=='original'and'ON'or nil end,
    activate=function()return choose(game,'original')end},
   {label='CURRENT GAME SONGS',activate=function()return api.openCurrent(game)end},
  }
  if Legacy then
   rows[#rows+1]={label='OTHER IMPORTED GAMES',activate=function()return api.openLegacy(game)end}
  end
  return menu.open(game,'BIKE SONG',rows)
 end
 mod.exports.gen3SongMenu=api
 return api
end
return SongMenu
