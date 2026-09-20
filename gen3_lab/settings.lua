-- Isolated FireRed beta settings. Uses the beta mod id's own options bucket;
-- never reads or writes bicycle_plus's Gen 1/2 bucket.
local Settings={}
local DEFAULTS={
 auto_mount=true,sfx_filter=0,riding_music='bicycle',bike_volume=7,bike_filter=0,
 riding_area_volume=-1,riding_area_filter=-1,riding_sfx_volume=-1,riding_sfx_filter=-1,
 bike_song='original',bike_song_resume=false,spelling='uk',
 bike_frame_colour='original',bike_tyres_colour='original',bike_rims_colour='original',
 bike_spokes_colour='original',bike_handlebars_colour='original',
}
local CUSTOM_DEFAULTS={bike_frame_colour='#c53a3a',bike_tyres_colour='#3a3a7b',
 bike_rims_colour='#b5b5d6',bike_spokes_colour='#efefff',bike_handlebars_colour='#b5b5d6'}
local COLOURS={bike_frame_colour=true,bike_tyres_colour=true,bike_rims_colour=true,
 bike_spokes_colour=true,bike_handlebars_colour=true}
local MODES={area=true,bicycle=true,both=true}
local function finite(v)
 v=tonumber(v);return v and v==v and v~=math.huge and v~=-math.huge and v or nil
end
local function integer(v,lo,hi,fallback)
 v=finite(v);if not v then v=fallback end
 v=math.floor(v);return math.max(lo,math.min(hi,v))
end
local function colour(v)
 if v==nil or v=='original' then return 'original' end
 if type(v)~='string' then return nil end
 local h=v:lower():gsub('^#','')
 if h:match('^%x%x%x%x%x%x$') then return '#'..h end
 return nil
end
function Settings.init(mod,services)
 local Runtime=services and services.Runtime or require('src.mods.Runtime')
 mod.options:define({
  {key='auto_mount',type='toggle',label='AUTO BIKE',default=true},
  {key='sfx_filter',type='choice',label='SFX FILTER',default=0,
   choices={{'OFF',0},{'1X',1},{'2X',2},{'3X',3}}},
  {key='riding_music',type='choice',label='MUSIC ON BIKE',default='bicycle',
   choices={{'AREA','area'},{'BICYCLE','bicycle'},{'BOTH','both'}}},
  {key='bike_volume',type='number',label='BIKE VOLUME',default=7,min=0,max=7,step=1},
  {key='bike_filter',type='choice',label='BIKE FILTER',default=0,
   choices={{'OFF',0},{'1X',1},{'2X',2},{'3X',3}}},
  {key='riding_area_volume',type='number',label='RIDING AREA VOL',default=-1,min=-1,max=7,step=1},
  {key='riding_area_filter',type='number',label='RIDING AREA FILTER',default=-1,min=-1,max=3,step=1},
  {key='riding_sfx_volume',type='number',label='RIDING SFX VOL',default=-1,min=-1,max=7,step=1},
  {key='riding_sfx_filter',type='number',label='RIDING SFX FILTER',default=-1,min=-1,max=3,step=1},
  {key='bike_song_resume',type='toggle',label='RESUME BIKE SONG',default=false},
  {key='spelling',type='choice',label='LANGUAGE',default='uk',choices={{'ENGLISH UK','uk'},{'ENGLISH US','us'}}},
 })
 local api={defaults=DEFAULTS,colourKeys=COLOURS}
 local function saved(game,create)
  local o=game and game.options
  if type(o)~='table' then return nil end
  if create then o.modOptions=o.modOptions or {};o.modOptions[mod.id]=o.modOptions[mod.id] or{} end
  return o.modOptions and o.modOptions[mod.id] or nil
 end
 local function live(game,create)
  local mods=game and game.mods
  if type(mods)~='table' then return nil end
  if create then mods.modOptions=mods.modOptions or{};mods.modOptions[mod.id]=mods.modOptions[mod.id] or{} end
  return mods.modOptions and mods.modOptions[mod.id] or nil
 end
 local function raw(game,key)
  local l=live(game,false);if l and l[key]~=nil then return l[key] end
  local s=saved(game,false);return s and s[key] or nil
 end
 local function normalize(key,v,game)
  if key=='auto_mount' or key=='bike_song_resume' then return v==true,true end
  if key=='spelling' then return (v=='us' and 'us' or v=='uk' and 'uk' or nil),v=='us' or v=='uk' end
  if key=='riding_music' then return MODES[v] and v or nil,MODES[v]==true end
  if key=='bike_volume' then return integer(v,0,7,7),finite(v)~=nil end
  if key=='bike_filter' or key=='sfx_filter' then return integer(v,0,3,0),finite(v)~=nil end
  if key=='riding_area_volume' or key=='riding_sfx_volume' then return integer(v,-1,7,-1),finite(v)~=nil end
  if key=='riding_area_filter' or key=='riding_sfx_filter' then return integer(v,-1,3,-1),finite(v)~=nil end
  if key=='bike_song' then return type(v)=='string' and v~='' and v or nil,type(v)=='string' and v~='' end
  if COLOURS[key] then local c=colour(v);return c,c~=nil end
  return v,DEFAULTS[key]~=nil
 end
 local function persist(game,key,value)
  if game and game.writeOptions then game:writeOptions() end
  local events=game and game.mods and game.mods.events
  if events and events.emit then events:emit('mod.options_changed',{mod=mod.id,key=key,value=value}) end
 end
 function api.get(key,game)
  local v=raw(game,key)
  if v==nil then
   if key=='bike_volume' and game and game.options and game.options.musicVol~=nil then v=game.options.musicVol
   elseif COLOURS[key] then v='original'
   else v=mod.options:get(key);if v==nil then v=DEFAULTS[key] end end
  end
  local n,ok=normalize(key,v,game)
  if ok then return n end
  return DEFAULTS[key]
 end
 function api.set(game,key,value)
  if Runtime.safeMode or DEFAULTS[key]==nil then return false end
  local n,ok=normalize(key,value,game);if not ok then return false end
  local s=saved(game,true);if not s then return false end
  s[key]=n;local l=live(game,true);if l then l[key]=n end
  persist(game,key,n);return true
 end
 function api.getRememberedColour(key,game)
  if not COLOURS[key]then return nil end
  local c=colour(raw(game,key..'_custom'))
  if c and c~='original'then return c end
  c=colour(raw(game,key));if c and c~='original'then return c end
  return CUSTOM_DEFAULTS[key]
 end
 function api.rememberColour(game,key,value)
  if Runtime.safeMode or not COLOURS[key]then return false end
  local c=colour(value);if not c or c=='original'then return false end
  local s=saved(game,true);if not s then return false end
  s[key..'_custom']=c;local l=live(game,true);if l then l[key..'_custom']=c end
  persist(game,key..'_custom',c);return true
 end
 function api.ensure(game)
  if Runtime.safeMode then return false end
  local s=saved(game,true);if not s then return false end
  local l=live(game,true);local changed=false
  local function seed(key,value)
   if raw(game,key)==nil then s[key]=value;if l then l[key]=value end;changed=true end
  end
  seed('auto_mount',true)
  local mv=finite(game and game.options and game.options.musicVol)
  seed('bike_volume',integer(mv,0,7,7)) -- copy native Music exactly once, including zero
  if changed then persist(game,'_gen3_seed',true) end
  return changed
 end
 function api.raw(game,key)return raw(game,key)end
 function api.colour(value)return colour(value)end
 return api
end
return Settings
