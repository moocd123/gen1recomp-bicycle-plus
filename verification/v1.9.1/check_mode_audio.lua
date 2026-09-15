-- Native Music/Hooks/Events + production audio/library in the native sandbox.
-- Playback Sources are software doubles; these are routing, not listening tests.
local T=dofile('verification/v1.9.0/support.lua').init(assert(arg[1]))
local edition=arg[2]or'red';require('src.core.GameVersion').set(edition)
local gen2=edition=='gold'or edition=='silver'or edition=='crystal'
local hooks=require('src.mods.Hooks').new();local events=require('src.mods.Events').new();T.Runtime.install(events,hooks)
package.loaded['src.render.Assets']={register=function()end}
local S={};function S.setVolumeLevel(v)S.level=v end;function S.isPlaying()return false end;function S.ducksMusic()return true end
for _,k in ipairs({'play','playStereo','playMove','playCry','playPikaCry','startLoop'})do S[k]=function()end end
package.loaded['src.core.Sound']=S
package.loaded['src.core.ChipAudio']={isSuspended=function()return false end,stopMusic=function()end,holdMusic=function()end,currentSource=function()return nil end}
package.loaded['src.core.ChipSynth']={SAMPLE_RATE=44100,getStereo=function()return false end}
local Music=require('src.core.Music');local baseline=Music.play
for _,p in ipairs({'map.wav','bike.wav','battle.wav','samegame.wav'})do T.files[p]='RIFF0000WAVE'..string.rep('tone',200)end
local data={audio={songs={Music_PalletTown={file='map.wav'},Music_BikeRiding={file='bike.wav'},Music_Battle={file='battle.wav'},Music_Test={file='samegame.wav'}},mapSongs={PALLET='Music_PalletTown'}}}
local game={data=data,save={onBike=false,options={musicVol=7,musicFilter=1,sfxVol=6}},overworld={map={id='PALLET'},player={}},stack={}}
if gen2 then data.audio.generation=2;data.audio.songs.Music_Bicycle=data.audio.songs.Music_BikeRiding;game.world={map={id='PALLET'},playerState='walk',player={}}end
function game.stack:top()return{}end
package.loaded['src.core.Game']=game
local lm=T.mod(game);local library=T.load(lm,'song_library').init(lm)
local song=assert(library.importBytes('RIFF0000WAVE'..string.rep('localtest',200),'custom track.wav'))
local settings={bike_song=song.id,bike_song_resume=true,riding_music='both',bike_volume=5,bike_filter=2,
 riding_area_volume=2,riding_area_filter=3,riding_sfx_volume=4,riding_sfx_filter=2,sfx_filter=1}
local mod={id='bicycle_plus',game=game,hooks={},events={},env=lm.env,log={warn=function()end}}
function mod.hooks:wrap(k,f,p)return hooks:wrap(k,f,p,'bicycle_plus')end
function mod.events:on(k,f,p)return events:on(k,f,p,'bicycle_plus')end
local A=T.load(mod,'audio').init(mod,settings,library)
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local function running(p)for i=#T.audio.sources,1,-1 do local s=T.audio.sources[i];if s.path==p and s.playing and not s.released then return s end end end
local function latest(p)for i=#T.audio.sources,1,-1 do local s=T.audio.sources[i];if s.path==p and not s.released then return s end end end
local function mount(on)
 game.save.onBike=on;if gen2 then game.world.playerState=on and'bike'or'walk'end
 Music.playMap(data,'PALLET',on,false);A.update(game,.016)
end
local function choose(mode)settings.riding_music=mode;events:emit('mod.options_changed',{mod='bicycle_plus',key='riding_music',value=mode})end
Music.setVolumeLevel(7);Music.setFilterLevel(1);S.setVolumeLevel(6)
local fileName='autobike-'..song.id:sub(6)..'.wav'
for _,choice in ipairs({{song.id,fileName},{'original','bike.wav'},{'game:'..edition..':Music_Test','samegame.wav'}})do
 settings.bike_song=choice[1];mount(true)
 for area=0,7 do for bike=0,7 do
  settings.riding_area_volume=area;settings.bike_volume=bike
  for _,mode in ipairs({'area','bicycle','both','bicycle','area','both'})do
   choose(mode)
   ck(settings.riding_area_volume==area and settings.bike_volume==bike,'mode rewrote gain')
   ck(settings.riding_area_filter==3 and settings.bike_filter==2 and settings.riding_sfx_filter==2,'mode rewrote filter')
   ck(settings.bike_song==choice[1]and settings.bike_song_resume,'mode rewrote song/resume')
   local s=running(choice[2]);local audible=mode~='area'and bike>0
   ck((s~=nil)==audible,'wrong bicycle routing '..mode)
   if s then ck(math.abs(s.volume-.7*bike/7)<1e-10 and s.filter.highgain==.16,'custom gain/filter not retained')end
   local expected=mode=='bicycle'and 0 or .7*area/7
   ck(math.abs(latest('map.wav').volume-expected)<1e-10,'wrong area routing '..mode)
   local status=A.status()
   ck(status.effectiveSfxVolume==4 and status.effectiveSfxFilter==2,'SFX profile changed with mode')
  end
 end end
 settings.riding_area_volume=2;settings.bike_volume=5
 for _,mode in ipairs({'area','bicycle','both'})do
  choose(mode);mount(false)
  ck(not running(choice[2])and latest('map.wav').volume==.7,'walking did not restore normal music')
  ck(A.status().effectiveSfxVolume==6 and A.status().effectiveSfxFilter==1,'walking SFX profile wrong')
  mount(true);Music.play(data,'Music_Battle',true,{reason='battle'});A.update(game,.016)
  ck(not running(choice[2])and running('battle.wav').volume==.7,'mode muted battle or leaked song')
  mount(true)
 end
end
-- SAME is a live inheritance rule, never flattened into a numerical preference.
settings.riding_area_volume=-1;settings.riding_area_filter=-1;settings.riding_sfx_volume=-1;settings.riding_sfx_filter=-1
settings.bike_volume=5;Music.setVolumeLevel(4)
for _,mode in ipairs({'bicycle','area','both'})do choose(mode)
 ck(settings.riding_area_volume==-1 and settings.riding_area_filter==-1 and settings.riding_sfx_volume==-1 and settings.riding_sfx_filter==-1,'SAME overwritten')
 ck(math.abs(latest('map.wav').volume-(mode=='bicycle'and 0 or .4))<1e-10,'SAME gain inheritance')
end
A.dispose();ck(Music.play==baseline,'unload did not restore native audio')
print(('PASS %d routing/mix checks for %s; modes preserve gains/filters/song/resume. Audio output is simulated.'):format(n,edition))
