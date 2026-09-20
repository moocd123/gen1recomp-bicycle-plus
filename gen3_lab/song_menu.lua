-- Gen 3-native FireRed song browser. This milestone intentionally exposes
-- only Original + current FireRed songs; foreign-game and local-file sources
-- plug into the same root in later lab milestones.
local SongMenu={}
function SongMenu.new(mod,settings,menu,Catalog,services)
 local S=services or{}
 local Audio=S.Audio or require('src.core.game3.audio')
 local api={}
 local function selected(game)return settings.get('bike_song',game)or'original'end
 local function choose(game,key)return settings.set(game,'bike_song',key)end
 function api.describe(game)return Catalog.describe(selected(game))end
 function api.openCurrent(game)
  local rows={}
  for _,song in ipairs(Catalog.available(Audio))do local row=song
   rows[#rows+1]={label=row.name,
    value=function()return selected(game)==row.key and'ON'or nil end,
    activate=function()return choose(game,row.key)end}
  end
  if #rows==0 then rows[1]={label='FIRERED SOUNDTRACK UNAVAILABLE'}end
  return menu.open(game,'FIRERED SOUNDTRACK',rows)
 end
 function api.open(game)
  return menu.open(game,'BIKE SONG',{
   {label='ORIGINAL BICYCLE THEME',
    value=function()return selected(game)=='original'and'ON'or nil end,
    activate=function()return choose(game,'original')end},
   {label='CURRENT GAME SONGS',activate=function()return api.openCurrent(game)end},
  })
 end
 mod.exports.gen3SongMenu=api
 return api
end
return SongMenu
