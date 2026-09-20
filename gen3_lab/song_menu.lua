-- Gen 3-native FireRed song browser. Current FireRed songs, already-imported
-- Gen 1/2 soundtracks and this beta's isolated local files share one selector.
local SongMenu={}
function SongMenu.new(mod,settings,menu,Catalog,services)
 local S=services or{}
 local Audio=S.Audio or require('src.core.game3.audio')
 local Legacy=S.Legacy
 local Local=S.Local
 local api={}
 local function selected(game)return settings.get('bike_song',game)or'original'end
 local function choose(game,key)return settings.set(game,'bike_song',key)end
 function api.describe(game)
  local key=selected(game)
  if key=='original'or key:match('^firered:%d+$')or key:match('^fr:%d+$')then
   return Catalog.describe(key)
  end
  if Legacy and Legacy.describe then local v=Legacy.describe(key);if v then return v end end
  if Local and Local.describe then local v=Local.describe(key);if v then return v end end
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
 function api.openLocal(game)
  local rows={}
  if Local and Local.files then
   for _,entry in ipairs(Local.files())do
    local row=entry
    rows[#rows+1]={label=(row.missing and'MISSING: 'or'')..row.name,
     value=function()return selected(game)==row.id and'ON'or nil end,
     activate=not row.missing and function()return choose(game,row.id)end or nil}
   end
  end
  if #rows==0 then rows[1]={label='NO IMPORTED AUDIO'}end
  return menu.open(game,'IMPORTED SONGS',rows)
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
  if Local then
   rows[#rows+1]={label='IMPORTED SONGS',activate=function()return api.openLocal(game)end}
  end
  return menu.open(game,'BIKE SONG',rows)
 end
 mod.exports.gen3SongMenu=api
 return api
end
return SongMenu
