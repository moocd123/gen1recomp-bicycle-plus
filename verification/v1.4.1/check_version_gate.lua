-- Uses the actual supplied v0.2.59 launcher/manifest/range-check modules.
-- Version.engine is a test input; this is NOT a v0.2.60 gameplay run.
local engine=arg[1] or 'runtime'
package.path=engine..'/?.lua;'..engine..'/?/init.lua;'..package.path
package.preload.bit=function() return require('bit32') end
local Json=require('src.link.Json')
local Semver=require('src.mods.Semver')
local Manifest=require('src.mods.Manifest')
local Version=require('src.core.Version')
local function read(path)
 local f=assert(io.open(path,'rb')); local text=f:read('*a'); f:close(); return text
end
local before=assert(Json.decode(read('verification/v1.4.1/original-v1.4.0-manifest.json')))
local after=assert(Json.decode(read('manifest.json')))
local n=0
local function check(value,label)
 assert(value,label); n=n+1
end
check(before.id==after.id,'same mod id, hence same settings namespace')
check(after.version=='1.4.1','new mod version')
check(Semver.validRange(after.game_version),'valid range')
check(Semver.satisfies('0.2.59',before.game_version),'old package accepts .59')
check(not Semver.satisfies('0.2.60',before.game_version),'old package rejects .60')
for _,version in ipairs({'0.2.59','0.2.60'}) do
 check(Semver.satisfies(version,after.game_version),'new package accepts '..version)
end
for _,version in ipairs({'0.2.10','0.2.58','0.2.61','0.3.0','1.0.0','0.2.60-dev'}) do
 check(not Semver.satisfies(version,after.game_version),'does not blanket-approve '..version)
end
local oldM=Manifest.validate(before,'mods/bicycle_plus/manifest.json')
local newM=Manifest.validate(after,'mods/bicycle_plus/manifest.json')
check(#newM.games==6,'six editions retained')
check(newM.api==oldM.api,'mod API retained')
local LauncherMods=require('src.mods.LauncherMods')
for _,v in ipairs({'0.2.59','0.2.60','0.2.61','0.2.58'}) do
 Version.engine=v
 for _,edition in ipairs({'red','blue','yellow','gold','silver','crystal'}) do
  local old=LauncherMods.deriveList({oldM},{mods={bicycle_plus=true}},edition)[1]
  local new=LauncherMods.deriveList({newM},{mods={bicycle_plus=true}},edition)[1]
  local expected=(v=='0.2.59' or v=='0.2.60') and 'ok' or 'warn'
  check(new.status==expected,'launcher status: '..v..' '..edition..': '..tostring(new.statusDetail))
  if v=='0.2.60' then check(old.status=='warn','reproduced old .60 warning') end
  print(string.format('%s / %s: old=%s (%s); new=%s (%s)',v,edition,old.status,old.statusDetail,new.status,new.statusDetail))
 end
end
print('PASS '..n..' manifest and real launcher version-gate assertions')
