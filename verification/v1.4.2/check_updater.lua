-- Run from the repository root: texlua verification/v1.4.2/check_updater.lua /path/to/engine
-- Uses native engine modules. UI, transport and installation boundaries are
-- simulated; synthetic version inputs are not gameplay tests of future engines.
local engine = assert(arg[1], 'Pass the directory containing the supplied engine src/')
package.path = engine .. '/?.lua;' .. engine .. '/?/init.lua;' .. package.path
package.preload.bit = function() return require('bit32') end
local Json = require('src.link.Json')
local Manifest = require('src.mods.Manifest')
local Semver = require('src.mods.Semver')
local Version = require('src.core.Version')
local LauncherMods = require('src.mods.LauncherMods')
local ModUpdate = require('src.mods.ModUpdate')
local RomImporter = require('src.import.RomImporter')
local SaveData = require('src.core.SaveData')
local Platform = require('src.core.Platform')
local function read(path)
  local f = assert(io.open(path, 'rb')); local s = f:read('*a'); f:close(); return s
end
local function clone(t) return assert(Json.decode(Json.encode(t))) end
local n = 0
local function check(value, label) assert(value, label); n = n + 1 end
local raw = assert(Json.decode(read('manifest.json')))
local current = Manifest.validate(raw, 'mods/bicycle_plus/manifest.json')
check(current.version == '1.4.2', 'release version')
check(current.id == 'bicycle_plus', 'settings namespace retained')
check(current.github == 'moocd123/gen1recomp-bicycle-plus', 'native GitHub field')
check(current.api == 2, 'API 2 still required')
check(raw.game_version == '>=0.2.59', 'no upper range limit')
check(Semver.validRange(raw.game_version), 'valid native range')
local savedEngine, savedAPI = Version.engine, Version.modApi
for _, v in ipairs({'0.2.59','0.2.60','0.2.61','0.2.99','0.3.0','1.0.0','10.0.0'}) do
  Version.engine = v
  check(Semver.satisfies(v, raw.game_version), 'range accepts ' .. v)
  for _, edition in ipairs({'red','blue','yellow','gold','silver','crystal'}) do
    local row = LauncherMods.deriveList({current}, {mods={bicycle_plus=true}}, edition)[1]
    check(row.status == 'ok', 'launcher eligible ' .. v .. '/' .. edition)
    check(row.github == current.github, 'GitHub reaches launcher row')
  end
end
for _, v in ipairs({'0.2.58','0.1.99','0.2.59-dev'}) do
  Version.engine = v
  check(not Semver.satisfies(v, raw.game_version), 'minimum excludes ' .. v)
  check(LauncherMods.deriveList({current},{mods={bicycle_plus=true}},'red')[1].status == 'warn', 'old engine warning')
end
Version.modApi = 1
local ok, err = pcall(Manifest.validate, raw, 'mods/bicycle_plus/manifest.json')
check(not ok and tostring(err):find('requires mod API 2',1,true), 'minimum API check retained')
Version.engine, Version.modApi = savedEngine, savedAPI
print('PASS: open engine range, six-game launcher eligibility, minimum engine and API checks')

-- Future release 1.4.3 below is a TEST FIXTURE, not an actual published version.
local repo, id = current.github, current.id
local release = {
  tag_name='v1.4.3', name='Synthetic updater fixture', prerelease=false,
  assets={
    {name='source-code.zip',browser_download_url='https://example.invalid/source.zip'},
    {name='SHA256SUMS.txt',browser_download_url='https://example.invalid/hashes.txt'},
    {name='bicycle_plus-1.4.3.zip',browser_download_url='https://github.com/'..repo..'/releases/download/v1.4.3/bicycle_plus-1.4.3.zip'}
  }
}
local parsed = assert(ModUpdate.parseRelease(release,id))
check(parsed.zip.name == 'bicycle_plus-1.4.3.zip', 'correct installable asset selected over unrelated ZIP')
check(parsed.version == '1.4.3', 'tag parsed')
check(ModUpdate.statusFor('1.4.2',{parsed}) == 'available', 'new release offered')
check(ModUpdate.statusFor('1.4.3',{parsed}) == 'current', 'no reinstall of current release')
check(ModUpdate.statusFor('1.5.0',{parsed}) == 'current', 'no downgrade')
check(ModUpdate.apiReleasesUrl(repo) == 'https://api.github.com/repos/'..repo..'/releases?per_page=100','correct release endpoint')
check(ModUpdate.pickBest({{prerelease=true,version='1.5.0'},parsed}) == parsed,'stable release preferred')
print('PASS: native GitHub release parsing, exact asset preference and version comparison')

local options = {mods={bicycle_plus=true}, marker='preserve preferences',modUpdateCache={}}
local settingsBefore = options.marker
SaveData.loadOptions = function() return options end
SaveData.saveOptions = function(t) options=t; return true end
Platform.canFetchRemote = function() return true end
local requests = {}
local responseBody = Json.encode({release})
local networkFailure = false
package.loaded['src.net.Fetch'] = {
  get = function(url, opts) requests[#requests+1]=url; return {url=url} end,
  poll = function(job)
    if networkFailure then return {status='error',err='simulated offline'} end
    return {status='ok',body=responseBody}
  end,
  release = function() end
}
local installs = {}
local function importer(manifest)
  local row=LauncherMods.deriveList({manifest},{mods={bicycle_plus=true}},'red')[1]
  return setmetatable({mods={row}, modUpdateInfo={},
    modCartPlan=function() return nil end,
    _updateAllCartRows=function() return {} end,
    _ensureFind=function() end, _setBusy=function() end,
    _clearBusy=function() end, _refreshMods=function() end,
    _beginModInstall=function(self,spec)
      installs[#installs+1]=spec
      spec.done(true,'simulated installer boundary')
    end,
  }, {__index=RomImporter})
end
local function drive(imp)
  for _=1,12 do imp:_pumpModInfoFetch(); imp:_pumpUpdateAll() end
end
-- Old package: an update cannot be discovered with a missing GitHub field.
local oldRaw=clone(raw);oldRaw.version='1.4.1';oldRaw.github=nil
local old=importer(Manifest.validate(oldRaw,'mods/bicycle_plus/manifest.json'))
old:_syncModUpdateInfo(true)
check(old._modInfoFetch == nil, 'old package has no update lookup')
check(#requests == 0, 'old package makes no GitHub request')
-- New package: press the native Update All action, drive its real state machine.
local imp=importer(current)
check(imp:pressUpdateAllMods(), 'native Update All starts')
check(imp._modInfoFetch[1].h.opts.force == true, 'Update All bypasses stale cache')
drive(imp)
check(#requests == 1 and requests[1] == ModUpdate.apiReleasesUrl(repo), 'native discovery requests correct GitHub repo')
check(#installs == 1 and installs[1].modId == id, 'native Update All reaches installer for this mod')
check(installs[1].release.zip.name == 'bicycle_plus-1.4.3.zip','native install request selects exact ZIP')
check(imp.modNotice.ok and imp.modNotice.text:find('1',1,true),'native update completion')
check(options.marker == settingsBefore and options.mods.bicycle_plus == true, 'update discovery preserves preferences')
-- Already up to date must not schedule another install.
local same=clone(raw);same.version='1.4.3'
local impSame=importer(Manifest.validate(same,'mods/bicycle_plus/manifest.json'))
check(impSame:pressUpdateAllMods(),'current release check starts');drive(impSame)
check(#installs == 1,'current mod not reinstalled')
-- An offline transport without cached releases does not install arbitrary data.
options.modUpdateCache={};networkFailure=true
local offline=importer(current)
check(offline:pressUpdateAllMods(),'offline check starts');drive(offline)
check(#installs == 1,'offline failure does not install')
check(offline:_modUpdateInfo(id).status == 'error','offline failure reported for mod')
print('PASS: native Update All discovery/queue/completion; old-package bootstrap; current/offline cases')
print('PASS '..n..' assertions. UI, network, filesystem install boundaries simulated; no full-device gameplay claim.')
