local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
local Json=require('src.link.Json');local Manifest=require('src.mods.Manifest');local Update=require('src.mods.ModUpdate')
local f=assert(io.open('manifest.json'));local raw=Json.decode(f:read('*a'));f:close()
local m=Manifest.validate(raw,'bicycle_plus')
assert(m.id=='bicycle_plus'and m.version=='1.9.1'and m.github=='moocd123/gen1recomp-bicycle-plus')
assert(raw.name=='AUTOBIKE+'and raw.game_version=='>=0.2.59'and raw.api==2 and #raw.games==6)
local r=assert(Update.parseRelease({tag_name='v1.9.1',prerelease=false,assets={
 {name='bicycle_plus-1.9.1.zip',browser_download_url='https://example.invalid/bicycle_plus-1.9.1.zip'}}},m.id))
assert(r.zip.name=='bicycle_plus-1.9.1.zip')
for _,v in ipairs({'1.4.2','1.7.0','1.8.0','1.9.0'})do assert(Update.statusFor(v,{r})=='available')end
assert(Update.statusFor('1.9.1',{r})=='current')
print('PASS native manifest, update identity, preferred ZIP and version discovery. No live client download claimed.')
