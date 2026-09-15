local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
package.preload.bit=function()return bit32 end
local T=dofile('verification/v1.8.0/support.lua');local R=T.install()
local m=T.mod();local GV=require('src.core.GameVersion')
-- This test uses the real entrypoint and mod sandbox, but isolates unchanged
-- graphics/movement/native-option screen services to exercise the new wiring.
local rawRead=m.read
local service='return{init=function()return{update=function()end,stop=function()end,status=function()return{}end}end}'
local colourService='return{init=function()return{update=function()end,status=function()end,artStyle=function()return"GEN 2"end,previewZones=function()return{}end,needsColourMode=function()return false end,drawPreview=function()end}end}'
local audioMenu='return{init=function(m,c)return{update=function()end,open=function(g)return c.openSongs(g)end}end}'
function m:read(p)
 if p=='automount.lua'then return service elseif p=='colours.lua'then return colourService elseif p=='audio_menu.lua'then return audioMenu end
 return T.read(p)
end
package.loaded['src.render.PaletteFX']={wholeNamed=function()return{}end}
package.loaded['src.ui.Theme']={cursor=1}
package.loaded['src.core.Sound']={setVolumeLevel=function()end,isPlaying=function()return false end}
package.loaded['src.core.ChipAudio']={isSuspended=function()return false end}
package.loaded['src.core.ChipSynth']={SAMPLE_RATE=44100,getStereo=function()return false end}
local Stack=require('src.core.StateStack');local Screens=require('src.ui.Screens')
local g={data={screens={},audio={songs={}}},mods={modOptions={bicycle_plus={_audio_layout=2,bike_centres_colour='original'}}},save={options={modOptions={bicycle_plus={_audio_layout=2,bike_centres_colour='original'}},musicVol=7,sfxVol=7}},stack=setmetatable({},{__index=Stack})}
g.stack:init();g.input={wasPressed=function()return false end};function g:writeOptions()end;m.game=g
local defs={};function m.options:define(t)defs=t end
function m.options:get(k)local s=g.mods.modOptions.bicycle_plus;if s[k]~=nil then return s[k]end;for _,o in ipairs(defs)do if o.key==k then return o.default end end end
function m.content.screens:register(id,def)g.data.screens[id]=def end
local Compat=require('src.mods.LegacyCompat').new({modId=m.id,modPath=m.path,fs=T.fs(),game=function()return g end})
local Sandbox=require('src.mods.Sandbox');local env=Sandbox.envFor({modId=m.id,permissions={engine_internals=true},compat=Compat})
local main=assert(Sandbox.compile(T.read('main.lua'),'@bicycle_plus/main.lua',env))();main(m)
T.eq(m.exports.getSetting('bike_song'),'original','default song changed')
T.check(m.exports.setSetting(g,'bike_song','game:red:Music_PalletTown'),'entrypoint rejected song')
T.eq(g.save.options.modOptions.bicycle_plus.bike_song,'game:red:Music_PalletTown')
T.check(not m.exports.setSetting(g,'bike_song','game:bad:../../evil'),'entrypoint accepted arbitrary path')
T.check(m.exports.setSetting(g,'bike_song_restart','resume'),'restart choice rejected')
m.exports.openSongs(g);T.check(g.stack:top(),'song menu unavailable through sandbox')
local id,err=m.exports.songLibrary.importBytes('RIFFxxxxWAVEaudio sample data','sandbox.wav')
T.check(id,err or 'fileData facade unavailable')
T.check(m.exports.songLibrary.resolve(g,id).def.file,'fileData lookup failed in sandbox')
m.exports.songAudio.dispose();g.stack:clear()
print(('PASS %d entrypoint, settings validation and library import checks under actual Sandbox/LegacyCompat with service doubles.'):format(T.count))
