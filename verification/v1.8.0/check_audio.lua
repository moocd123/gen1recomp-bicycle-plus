local T=dofile('verification/v1.8.0/test_support.lua').init(assert(arg[1]))
local edition=arg[2] or 'red';require('src.core.GameVersion').set(edition)
local gen2=edition=='gold'or edition=='silver'or edition=='crystal'
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local Hooks=require('src.mods.Hooks');local Events=require('src.mods.Events')
local hooks,events=Hooks.new(),Events.new();T.Runtime.install(events,hooks)
package.loaded['src.render.Assets']={register=function()end}
local fanfare=false;local Sound={level=7}
function Sound.setVolumeLevel(v)Sound.level=v end
function Sound.isPlaying()return fanfare end
function Sound.ducksMusic()return true end
for _,k in ipairs({'play','playStereo','playMove','playCry','playPikaCry','startLoop'})do Sound[k]=function()end end
package.loaded['src.core.Sound']=Sound
local suspended=false
package.loaded['src.core.ChipAudio']={isSuspended=function()return suspended end,stopMusic=function()end,holdMusic=function()end,currentSource=function()return nil end}
package.loaded['src.core.ChipSynth']={SAMPLE_RATE=44100,getStereo=function()return false end}
local Music=require('src.core.Music');local baseline=Music.play
local L=dofile('song_library.lua');local library=L.init({})
local song=assert(library.importBytes('ID3'..string.rep('audio',200),'test track.mp3'))
for _,path in ipairs({'map.wav','bike.wav','battle.wav','surf.wav'})do T.files[path]='RIFF1234WAVE'..string.rep('music',60)end
local data={audio={songs={Music_PalletTown={file='map.wav'},Music_BikeRiding={file='bike.wav'},Music_Battle={file='battle.wav'},Music_Surfing={file='surf.wav'}},mapSongs={PALLET='Music_PalletTown'}}}
local game={data=data,save={onBike=false,options={musicVol=7,sfxVol=7}},overworld={map={id='PALLET'},player={}},stack={}}
if gen2 then
 data.audio.generation=2;data.audio.songs.Music_Bicycle=data.audio.songs.Music_BikeRiding
 game.world={map={id='PALLET'},playerState='walk',player={}}
end
local top={};function game.stack:top()return top end
package.loaded['src.core.Game']=game
local settings={bike_song=song.id,bike_volume=7,bike_filter=0,riding_music='both',bike_song_resume=false}
local mod={id='bicycle_plus',game=game,hooks={},events={},log={warn=function()end}}
function mod.hooks:wrap(k,f,p)return hooks:wrap(k,f,p,'bicycle_plus')end
function mod.events:on(k,f,p)return events:on(k,f,p,'bicycle_plus')end
local A=dofile('audio.lua').init(mod,settings,library)
local function latest(path)
 for i=#T.audio.sources,1,-1 do local s=T.audio.sources[i];if s.path==path and not s.released then return s end end
end
local function running(path)for _,s in ipairs(T.audio.sources)do if s.path==path and s.playing and not s.released then return s end end end
local function mount(on)
 game.save.onBike=on;if gen2 then game.world.playerState=on and'bike'or'walk'end;Music.playMap(data,'PALLET',on,false);A.update(game,.016)
end
mount(false);ck(not running(song.path),'not playing on foot')
mount(true);ck(running(song.path),'imported audio did not start');ck(not running('bike.wav'),'default bicycle theme leaked');ck(running('map.wav'),'both lost area track')
ck(running(song.path).looping,'imported loop flag')
for area=0,7 do for bike=0,7 do
 Music.setVolumeLevel(area);settings.bike_volume=bike;A.update(game,.016)
 local s=running(song.path)
 if bike==0 then ck(not s,'bike OFF') else ck(s and math.abs(s.volume-.7*bike/7)<1e-10,'independent bike gain')end
 ck(math.abs(latest('map.wav').volume-.7*area/7)<1e-10,'independent area gain')
end end
settings.bike_volume=5;settings.bike_filter=2;Music.setVolumeLevel(7);A.update(game,.016)
ck(running(song.path).filter.highgain==.16,'file filter not applied')
settings.riding_music='bicycle';A.update(game,.016);ck(latest('map.wav').volume==0,'bicycle-only area mute')
mount(false);ck(not running(song.path),'dismount leaked song');ck(latest('map.wav').volume==.7,'normal music restored')
settings.riding_music='both';mount(true);local first=running(song.path)
mount(false);mount(true);ck(running(song.path)~=first and first.released,'restart did not replace source')
settings.bike_song_resume=true;first=running(song.path);first.position=19
mount(false);ck(first.paused and not first.released,'resume did not retain paused source')
mount(true);ck(running(song.path)==first and first.position==19,'resume lost playback position')
Music.play(data,'Music_Battle',true,{reason='battle'});A.update(game,.016)
ck(not running(song.path)and running('battle.wav'),'custom played over battle')
mount(true);ck(running(song.path)==first,'battle resume lost source')
fanfare=true;events:emit('sound.played',{kind='sfx',name='JINGLE'});A.update(game,.016);ck(not running(song.path),'fanfare did not pause')
fanfare=false;A.update(game,.016);ck(running(song.path),'fanfare did not resume')
suspended=true;A.update(game,.016);ck(not running(song.path),'suspend did not pause');suspended=false;A.update(game,.016);ck(running(song.path),'device resume')
settings.riding_music='area';A.update(game,.016);ck(not running(song.path),'AREA mode leaked song');ck(latest('map.wav').volume==.7,'AREA mode volume')
settings.riding_music='both';mount(false)
-- Audition is explicit and temporary even on foot; restores the same native song.
top={bicycleMusicPreview=true};ck(A.previewSong(song.id,game),'preview creation');A.update(game,.016)
ck(A.status().previewActive and running(song.path),'preview not playing');ck(latest('map.wav').volume==0,'preview did not quiet native track')
A.stopPreview();A.update(game,.016);ck(not running(song.path)and latest('map.wav').volume==.7,'preview stop did not restore walking music')
ck(A.previewSong(song.id,game),'second preview');A.update(game,.016);top={};A.update(game,.016);ck(not A.status().previewActive,'preview survived leaving its screen')
settings.bike_song='game:'..edition..':Music_PalletTown';mount(true)
ck(A.status().layerActive,'explicit same-song selection should keep separate gain control')
settings.bike_song='file:'..string.rep('a',64);A.update(game,.016)
ck(running('bike.wav')and A.status().songError,'missing file did not fall back')
ck(not running(song.path),'previous song leaked into fallback')
settings.bike_song=song.id;library.refresh();A.update(game,.016);ck(running(song.path),'restored song failed')
-- Purposely corrupt a stored file after validation: no crash, no retry loop.
A.stop();T.files[song.path]='CORRUPT';library.refresh();A.update(game,.016)
ck(running('bike.wav')and A.status().songError,'decoder failure fallback')
local before=#T.audio.sources
for i=1,50 do A.update(game,.016)end
ck(#T.audio.sources==before,'failed custom source retried every frame')
A.dispose();ck(Music.play==baseline,'unload did not restore native play function')
ck(not running('bike.wav')and not running(song.path),'unload leaked bicycle sources')
print(('PASS %d real Music/Hooks/Events checks with simulated playback device: gains, modes, filters, resume, battles, fanfares, preview, fallback and cleanup.'):format(n))
