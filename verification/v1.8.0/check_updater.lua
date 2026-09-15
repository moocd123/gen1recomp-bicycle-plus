local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
local Json=require('src.link.Json');local Manifest=require('src.mods.Manifest');local Update=require('src.mods.ModUpdate')
local f=assert(io.open('manifest.json'));local raw=assert(Json.decode(f:read('*a')));f:close()
local m=Manifest.validate(raw,'bicycle_plus')
assert(m.id=='bicycle_plus'and m.version=='1.8.0'and m.github=='moocd123/gen1recomp-bicycle-plus')
assert(raw.game_version=='>=0.2.59'and raw.api==2 and #raw.games==6)
local doc={tag_name='v1.8.0',prerelease=false,assets={
 {name='source.zip',browser_download_url='https://example.invalid/not-the-mod.zip'},
 {name='bicycle_plus-1.8.0.zip',browser_download_url='https://example.invalid/bicycle_plus-1.8.0.zip'}},body='TEST FIXTURE'}
local rel=assert(Update.parseRelease(doc,m.id));assert(rel.zip.name=='bicycle_plus-1.8.0.zip')
for _,v in ipairs({'1.4.2','1.5.0','1.6.0','1.7.0'})do assert(Update.statusFor(v,{rel})=='available')end
assert(Update.statusFor('1.8.0',{rel})=='current')
print('PASS: native update metadata, preferred release ZIP and 1.4.2/1.5.0/1.6.0/1.7.0 -> 1.8.0 version discovery. Network/install not exercised.')
