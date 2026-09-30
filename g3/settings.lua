-- Same setting keys/meanings as the GB/GBC UI, persisted through Game3's
-- options-only writer. No session/progress-save conversion is performed.
local M={}
function M.init(mod,H,Library)
 local Runtime=require('src.mods.Runtime')
 local keys={'bike_colour','bike_stripes_colour','bike_centres_colour','bike_tyres_colour','bike_handlebars_colour'}
 local colours={};for _,k in ipairs(keys)do colours[k]=true end
 local defaults={auto_mount=true,sfx_filter=0,riding_music='bicycle',bike_volume=7,bike_filter=0,
 riding_area_volume=-1,riding_area_filter=-1,riding_sfx_volume=-1,riding_sfx_filter=-1,
 bike_song='original',bike_song_resume=false,spelling='uk'}
 for _,k in ipairs(keys)do defaults[k]='original'end
 local Profiles=mod.exports.profiles
 local api={defaults=defaults,colourKeys=keys,rgb=H.rgb,profiles=Profiles}
 local function tables(game,make)
  local o=game and (game.options or(game.save and game.save.options))
  local m=game and game.mods
  if type(o)~='table'or type(m)~='table'then return end
  if make then
   o.modOptions=o.modOptions or{};o.modOptions[mod.id]=o.modOptions[mod.id]or{}
   m.modOptions=m.modOptions or{};m.modOptions[mod.id]=m.modOptions[mod.id]or{}
  end
  return o.modOptions and o.modOptions[mod.id],m.modOptions and m.modOptions[mod.id],o
 end
 function api.raw(game,key)
  local s,l=tables(game,false)
  if l and l[key]~=nil then return l[key]end
  if s and s[key]~=nil then return s[key]end
 end
 local function number(v,lo,hi)
  v=tonumber(v);if not v or v~=v or v==math.huge or v==-math.huge then return end
  return math.max(lo,math.min(hi,math.floor(v)))
 end
 local function normal(key,v)
  if colours[key]then return H.canonical(v)end
  if key=='auto_mount'or key=='bike_song_resume'then if type(v)=='boolean'then return v end;return nil end
  if key=='spelling'then return(v=='uk'or v=='us')and v or nil end
  if key=='riding_music'then return(v=='area'or v=='bicycle'or v=='both')and v or nil end
  if key=='bike_song'then return Library.valid(v)and v or nil end
  if key=='bike_volume'then return number(v,0,7)end
  if key=='bike_filter'or key=='sfx_filter'then return number(v,0,3)end
  if key=='riding_area_volume'or key=='riding_sfx_volume'then return number(v,-1,7)end
  if key=='riding_area_filter'or key=='riding_sfx_filter'then return number(v,-1,3)end
 end
 function api.get(key,game)
  if Profiles and Profiles.managed(key)then return Profiles.get(key,game)end
  local v=api.raw(game,key)
  if v~=nil then local n=normal(key,v);if n~=nil then return n end end
  if key=='bike_volume'then local _,_,o=tables(game,false);if o then return number(o.musicVol,0,7)or 7 end end
  return defaults[key]
 end
 local function persist(game,key,value)
  if game.writeOptions then game:writeOptions()end
  if game.mods.events then game.mods.events:emit('mod.options_changed',{mod=mod.id,key=key,value=value})end
 end
 function api.ensure(game)
  if Profiles then Profiles.ensure(game);return end
  if Runtime.safeMode then return end
  local s,l,o=tables(game,true);if not s then return end
  local changed=false
  for _,key in ipairs({'auto_mount','riding_music','bike_volume','bike_song'})do
   if api.raw(game,key)==nil then
    local v=key=='bike_volume'and(number(o.musicVol,0,7)or 7)or defaults[key]
    s[key]=v;l[key]=v;changed=true
   end
  end
  if changed then persist(game,'_initialised',true)end
 end
 function api.set(game,key,v)
  if Profiles and Profiles.managed(key)then return Profiles.set(game,key,v)end
  if Runtime.safeMode or defaults[key]==nil then return false end
  local n=normal(key,v);if n==nil then return false end
  local s,l=tables(game,true);if not s then return false end
  s[key]=n;l[key]=n
  if colours[key]and n~='original'then s[key..'_custom']=n;l[key..'_custom']=n end
  persist(game,key,n);return true
 end
 function api.remembered(game,key)
  if Profiles then return Profiles.remembered(game,key)end
  local v=H.canonical(api.raw(game,key..'_custom'))
  if v and v~='original'then return v end
  v=api.get(key,game);if v~='original'then return v end
  return H.canonical('green')
 end
 function api.reset(game)
  if Profiles then return Profiles.resetColours(game)end
  if Runtime.safeMode then return false end
  local s,l=tables(game,true);if not s then return false end
  for _,k in ipairs(keys)do
   local v=api.get(k,game)
   if v~='original'then s[k..'_custom']=v;l[k..'_custom']=v end
   s[k]='original';l[k]='original'
  end
  persist(game,'reset_colours',true);return true
 end
 function api.word(game)return api.get('spelling',game)=='us'and'COLOR'or'COLOUR'end
 function api.centre(game)return api.get('spelling',game)=='us'and'CENTER'or'CENTRE'end
 local fs={{'OFF',0},{'1X',1},{'2X',2},{'3X',3}}
 local schema={
  {key='auto_mount',type='toggle',label='AUTO BIKE',default=true},
  {key='sfx_filter',type='choice',label='SFX FILTER',default=0,choices=fs},
  {key='riding_music',type='choice',label='MUSIC ON BIKE',default='bicycle',choices={{'AREA','area'},{'BICYCLE','bicycle'},{'BOTH','both'}}},
  {key='bike_volume',type='number',label='BIKE VOLUME',default=7,min=0,max=7,step=1},
  {key='bike_filter',type='choice',label='BIKE FILTER',default=0,choices=fs},
  {key='bike_song_resume',type='toggle',label='RESUME BIKE SONG',default=false},
  {key='spelling',type='choice',label='LANGUAGE',default='uk',choices={{'ENGLISH UK','uk'},{'ENGLISH US','us'}}},
 }
 for _,entry in ipairs({{'riding_area_volume',7},{'riding_area_filter',3},{'riding_sfx_volume',7},{'riding_sfx_filter',3}})do
  schema[#schema+1]={key=entry[1],label=entry[1]:upper():gsub('_',' '),type='number',default=-1,min=-1,max=entry[2],step=1}
 end
 mod.options:define(schema)
 return api
end
return M
