package.path=assert(arg[1])..'/?.lua;'..package.path
local Json=require('src.link.Json');local Manifest=require('src.mods.Manifest');local Update=require('src.mods.ModUpdate')
local f=assert(io.open(arg[2]..'/manifest.json'));local m=Json.decode(f:read('*a'));f:close()
local validated=Manifest.validate(m,'bicycle_plus')
assert(validated.id=='bicycle_plus'and validated.version=='2.0.0')
assert(m.name=='AUTOBIKE+'and m.api==2 and m.game_version=='>=0.3.36'and m.github=='moocd123/gen1recomp-bicycle-plus')
assert(#m.games==8 and m.permissions[1]=='engine_internals'and m.permissions[2]=='compute')
assert(m.conflicts[1]=='autobike_plus_test'and m.conflicts[2]=='autobike_plus_firered_beta')
local r=assert(Update.parseRelease({tag_name='v2.0.0',prerelease=false,assets={{name='bicycle_plus-2.0.0.zip',browser_download_url='https://example.invalid/bicycle_plus-2.0.0.zip'}}},m.id))
for _,v in ipairs({'1.4.2','1.7.0','1.8.0','1.9.3'})do assert(Update.statusFor(v,{r})=='available')end
assert(Update.statusFor('2.0.0',{r})=='current')
print('PASS native public identity, conflicts, version and updater asset recognition')
