local Settings=dofile('gen3_lab/settings.lua')
local defs,stored={},{}
local mod={id='autobike_plus_firered_beta',options={}}
function mod.options:define(rows)for _,r in ipairs(rows)do defs[r.key]=r end end
function mod.options:get(k)return stored[k]~=nil and stored[k]or(defs[k]and defs[k].default)end
local emitted={};local writes=0
local game={options={musicVol=0,modOptions={bicycle_plus={auto_mount=false,bike_volume=6}}},
 mods={modOptions={},events={emit=function(_,n,p)emitted[#emitted+1]={n,p}end}},writeOptions=function()writes=writes+1 end}
local s=Settings.init(mod,{Runtime={safeMode=false}})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
ck(s.get('auto_mount',game)==true,'default Auto Bike not ON')
ck(s.ensure(game)==true,'first-run seed did not run')
ck(s.raw(game,'bike_volume')==0,'native zero Music volume was not copied exactly')
ck(s.raw(game,'auto_mount')==true,'Auto Bike seed missing')
ck(writes==1,'first-run seed should persist once')
ck(game.options.modOptions.bicycle_plus.auto_mount==false and game.options.modOptions.bicycle_plus.bike_volume==6,
 'stable Gen1/2 options bucket was altered')
ck(s.set(game,'auto_mount',false)and s.get('auto_mount',game)==false,'explicit Auto Bike OFF not retained')
ck(s.set(game,'bike_volume',0)and s.get('bike_volume',game)==0,'explicit zero bike volume not retained')
local before=writes;ck(s.ensure(game)==false and writes==before,'ensure overwrote existing values')
ck(s.set(game,'riding_area_volume',99)and s.get('riding_area_volume',game)==7,'volume clamp failed')
ck(s.set(game,'riding_area_filter',-5)and s.get('riding_area_filter',game)==-1,'inherited filter clamp failed')
ck(s.set(game,'bike_frame_colour','#Aa10fF')and s.get('bike_frame_colour',game)=='#aa10ff','hex normalisation failed')
ck(not s.set(game,'bike_frame_colour','orange-ish')and s.get('bike_frame_colour',game)=='#aa10ff','invalid colour accepted')
ck(s.rememberColour(game,'bike_frame_colour','#123ABC')and s.getRememberedColour('bike_frame_colour',game)=='#123abc','remembered custom colour failed')
ck(s.set(game,'bike_frame_colour','original')and s.get('bike_frame_colour',game)=='original','Original bypass setting failed')
ck(s.getRememberedColour('bike_frame_colour',game)=='#123abc','Original erased remembered custom colour')
ck(not s.rememberColour(game,'bike_frame_colour','original'),'Original must not replace remembered custom colour')
ck(#emitted>=1 and emitted[#emitted][1]=='mod.options_changed','options-changed event missing')
print('PASS '..n..' isolated FireRed settings/persistence assertions.')
