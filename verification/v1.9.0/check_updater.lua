local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
local Json=require('src.link.Json');local Manifest=require('src.mods.Manifest');local Update=require('src.mods.ModUpdate')
local f=assert(io.open('manifest.json'));local raw=assert(Json.decode(f:read('*a')));f:close()
local m=Manifest.validate(raw,'bicycle_plus')
assert(m.id=='bicycle_plus' and m.name=='AUTOBIKE+' and m.version=='1.9.0')
assert(m.github=='moocd123/gen1recomp-bicycle-plus' and raw.game_version=='>=0.2.59' and raw.api==2 and #raw.games==6)
local release=assert(Update.parseRelease({tag_name='v1.9.0',assets={
 {name='unrelated.zip',browser_download_url='https://example.invalid/no.zip'},
 {name='bicycle_plus-1.9.0.zip',browser_download_url='https://example.invalid/yes.zip'}}},m.id))
assert(release.zip.name=='bicycle_plus-1.9.0.zip')
for _,old in ipairs({'1.4.2','1.5.0','1.6.0','1.7.0','1.8.0'})do assert(Update.statusFor(old,{release})=='available')end
assert(Update.statusFor('1.9.0',{release})=='current')
print('PASS native manifest/name/identity, updater asset preference and release ordering. No live client update claimed.')
