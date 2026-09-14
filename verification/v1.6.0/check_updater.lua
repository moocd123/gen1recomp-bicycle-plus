local engine=assert(arg[1]);package.path=engine..'/?.lua;'..engine..'/?/init.lua;'..package.path
package.preload.bit=function()return require('bit32')end
local Json=require('src.link.Json');local Manifest=require('src.mods.Manifest');local Semver=require('src.mods.Semver')
local Version=require('src.core.Version');local Launcher=require('src.mods.LauncherMods');local Update=require('src.mods.ModUpdate')
local Importer=require('src.import.RomImporter');local Save=require('src.core.SaveData');local Platform=require('src.core.Platform')
-- Source trees carry a development version; this is an explicit version-check input.
local originalVersion=Version.engine;Version.engine='0.2.60'
local f=assert(io.open('manifest.json'));local raw=assert(Json.decode(f:read('*a')));f:close()
local m=Manifest.validate(raw,'mods/bicycle_plus/manifest.json');local n=0
local function check(v,s)assert(v,s);n=n+1 end
local function clone(t)return Json.decode(Json.encode(t))end
check(m.version=='1.6.0'and m.id=='bicycle_plus'and m.github=='moocd123/gen1recomp-bicycle-plus','version and update source')
check(raw.game_version=='>=0.2.59'and m.api==2,'minimum and API unchanged')
for _,game in ipairs({'red','blue','yellow','gold','silver','crystal'})do
 check(Launcher.deriveList({m},{mods={bicycle_plus=true}},game)[1].status=='ok','native game eligibility')
end
local release={tag_name='v1.6.0',assets={{name='source.zip',browser_download_url='https://example.invalid/source.zip'},
 {name='bicycle_plus-1.6.0.zip',browser_download_url='https://github.com/'..m.github..'/releases/download/v1.6.0/bicycle_plus-1.6.0.zip'}}}
local parsed=assert(Update.parseRelease(release,m.id))
check(parsed.zip.name=='bicycle_plus-1.6.0.zip','correct release asset')
local options={mods={bicycle_plus=true},marker='retain',modUpdateCache={}}
Save.loadOptions=function()return options end;Save.saveOptions=function(t)options=t;return true end
Platform.canFetchRemote=function()return true end
local installs={};local offline=false
package.loaded['src.net.Fetch']={get=function(url)return{url=url}end,
 poll=function()if offline then return{status='error',err='offline fixture'}end;return{status='ok',body=Json.encode({release})}end,release=function()end}
local function importer(v)
 local r=clone(raw);r.version=v;local row=Launcher.deriveList({Manifest.validate(r,'mods/bicycle_plus/manifest.json')},{mods={bicycle_plus=true}},'red')[1]
 return setmetatable({mods={row},modUpdateInfo={},modCartPlan=function()end,_updateAllCartRows=function()return{}end,
 _ensureFind=function()end,_setBusy=function()end,_clearBusy=function()end,_refreshMods=function()end,
 _beginModInstall=function(self,spec)installs[#installs+1]=spec;spec.done(true,'simulated install boundary')end},{__index=Importer})
end
local function run(v)
 local imp=importer(v);check(imp:pressUpdateAllMods(),'Update All starts')
 for i=1,12 do imp:_pumpModInfoFetch();imp:_pumpUpdateAll()end
 return imp
end
for _,v in ipairs({'1.4.2','1.5.0'})do
 local before=#installs;run(v);check(#installs==before+1 and installs[#installs].release.zip.name=='bicycle_plus-1.6.0.zip','old installed version queues new asset')
end
local before=#installs;run('1.6.0');run('1.6.1');check(#installs==before,'no reinstall or downgrade')
options.modUpdateCache={};offline=true;run('1.5.0');check(#installs==before,'offline no installation')
check(options.marker=='retain','preferences unaffected')
Version.engine=originalVersion
print(('PASS: %d native updater/manifest checks; 1.4.2 and 1.5.0 -> 1.6.0, current/newer/offline cases; transport/install simulated.'):format(n))
