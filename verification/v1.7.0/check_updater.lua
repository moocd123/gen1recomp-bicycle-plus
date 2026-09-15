local engine=assert(arg[1],'engine path required');package.path=engine..'/?.lua;'..package.path
local Json=require('src.link.Json');local Manifest=require('src.mods.Manifest');local Update=require('src.mods.ModUpdate')
local f=assert(io.open('manifest.json'));local raw=Json.decode(f:read('*a'));f:close()
local m=Manifest.validate(raw,'bicycle_plus')
assert(m.id=='bicycle_plus'and m.version=='1.7.0'and m.github=='moocd123/gen1recomp-bicycle-plus')
assert(raw.game_version=='>=0.2.59'and raw.api==2 and #raw.games==6)
local release={tag_name='v1.7.0',name='Bicycle Plus v1.7.0',prerelease=false,assets={
 {name='some-other-source.zip',browser_download_url='https://example.invalid/not-the-mod.zip'},
 {name='bicycle_plus-1.7.0.zip',browser_download_url='https://example.invalid/bicycle_plus-1.7.0.zip'}},body='Local test fixture'}
local parsed=assert(Update.parseRelease(release,m.id))
assert(parsed.zip.name=='bicycle_plus-1.7.0.zip')
for _,version in ipairs({'1.4.2','1.5.0','1.6.0'})do assert(Update.statusFor(version,{parsed})=='available')end
assert(Update.statusFor('1.7.0',{parsed})=='current')
assert(Update.statusFor('9.9.9',{parsed})=='current')
assert(Update.statusFor('1.5.0',{})=='unknown')
print('PASS: native manifest validation, retained update source, preferred ZIP selection and version discovery. No network or installation was simulated as a live update.')
