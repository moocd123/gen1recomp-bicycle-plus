local root=arg[1]or'gen3_lab'
local Layer=assert(loadfile(root..'/audio_layer.lua'))()
local function check(v,msg)if not v then error(msg or'check failed',2)end end
local function near(a,b,msg)check(math.abs((a or0)-(b or0))<1e-8,msg or(tostring(a)..' ~= '..tostring(b)))end
local values={riding_music='bicycle',bike_volume=7,bike_filter=0,riding_area_volume=-1,riding_area_filter=-1,
 riding_sfx_volume=-1,riding_sfx_filter=-1,sfx_filter=0,bike_song='original',bike_song_resume=false}
local settings={get=function(key)return values[key]end}
local Runtime={safeMode=false,hooks={},events={}};local Version={get=function()return'firered'end,generation=function()return3 end}
local PlayerState={biking=true};local registered={};local Assets={register=function(v)registered[#registered+1]=v end}
local function soundSource()
 local s={playing=false,paused=false,queues=0,volume=1,filter=nil,released=false,looping=false}
 function s:getFreeBufferCount()return1 end;function s:queue(_)self.queues=self.queues+1;return true end
 function s:play()self.playing=true;self.paused=false end;function s:pause()self.playing=false;self.paused=true end
 function s:stop()self.playing=false;self.paused=false end;function s:isPlaying()return self.playing end
 function s:setLooping(v)self.looping=v==true end;function s:setVolume(v)self.volume=v end
 function s:setFilter(v)self.filter=v end;function s:getFilter()return self.filter end;function s:release()self.released=true end
 return s
end
local se=soundSource();local cry=soundSource();local nativeUpdates,restores,gains,bgmFilters=0,0,0,0
local Audio={_pack={},_cache={},_bgmVolume=5/7,_sfxVolume=4/7,_filterLevel=1,_seSources={se},_crySource=cry,_fanfareActive=false}
local originalUpdate=function()nativeUpdates=nativeUpdates+1 end;Audio.update=originalUpdate
function Audio.role(name)return name=='cycling'and282 or nil end
function Audio.songInfo(id)if id==282 or id==300 then return{id=id,kind='bgm',loop=true}end end
function Audio.applyEngineOptions(o)restores=restores+1;Audio._bgmVolume=(o.musicVol or7)/7;Audio._sfxVolume=(o.sfxVol or7)/7;Audio._filterLevel=(o.musicFilter or0)>0 and o.musicFilter or nil end
function Audio.applyGain()gains=gains+1 end;function Audio.applyBgmFilter()bgmFilters=bgmFilters+1 end
local starts,renders=0,0;local Player={SAMPLE_RATE=44100,BUFFER_SAMPLES=8192}
function Player.start(_,_,slot,id)starts=starts+1;slot.songId=id;slot.voices={};return id==282 or id==300 end
function Player.renderBuffered(slot,n,opts)renders=renders+1;return{slot=slot,n=n,rate=opts.sampleRate}end
local chipStarts,chipRenders=0,0;local ChipSynth={SAMPLE_RATE=32768}
function ChipSynth.newEngine(data,def,opts)chipStarts=chipStarts+1;check(data.tag=='red'and def.label=='Music_Route1'and opts.allowLoops==true,'legacy ChipSynth inputs incorrect');return{finished=function()return false end}end
function ChipSynth.soundData(_,n,channels)chipRenders=chipRenders+1;check(n==64 and channels==2,'legacy buffer settings incorrect');return{release=function()end}end
local Legacy={resolve=function(key)if key=='game:red:Music_Route1'then return{kind='chip',label='Music_Route1',data={tag='red'},def={label='Music_Route1'}}end;return nil,'missing legacy song'end}
local localOpens=0;local localSources={};local Local={resolve=function(key)
 if key~='file:'..string.rep('a',64)then return nil,'missing local song'end
 return{kind='file',key=key,name='LOCAL TEST',openSource=function()localOpens=localOpens+1;local s=soundSource();localSources[#localSources+1]=s;return s end}
end}
local made={};local madeRates={};local function newQueueableSource(rate)local s=soundSource();made[#made+1]=s;madeRates[#madeRates+1]=rate;return s end
local game={phase='field',options={musicVol=5,sfxVol=4,musicFilter=1}}
local mod={id='autobike_plus_firered_beta',game=game,exports={},events={on=function()end},hooks={wrap=function()end}}
local api=Layer.attach(mod,settings,{Version=Version,Audio=Audio,Player=Player,ChipSynth=ChipSynth,Legacy=Legacy,Local=Local,PlayerState=PlayerState,
 Runtime=Runtime,Assets=Assets,newQueueableSource=newQueueableSource,bufferSamples=128,chipBufferSamples=64,maxFill=1})
check(Audio.update~=originalUpdate,'layer wraps native Audio.update')
Audio.update(1/60);check(nativeUpdates==1,'native Audio.update still runs');check(starts==1 and renders==1,'independent M4A slot starts and renders')
check(api.status().songId==282 and api.status().songKind=='m4a'and api.status().ready,'original resolves to FireRed cycling role')
near(Audio._bgmVolume,0,'bicycle-only suppresses area only after overlay is ready');near(Audio._sfxVolume,4/7,'inherited riding SFX volume uses native option')
near(made[1].volume,1,'bike volume 7 is full overlay gain');check(made[1].playing,'overlay source plays');check(madeRates[1]==44100,'FireRed overlay uses M4A sample rate')
values.riding_music='both';values.riding_area_volume=3;values.bike_volume=2;values.bike_filter=2;Audio.update(1/60)
near(Audio._bgmVolume,3/7,'both preserves riding area volume');near(made[1].volume,2/7,'bike volume is independent');check(made[1].filter and made[1].filter.highgain==0.16,'bike filter applies only to overlay')
values.riding_music='bicycle';values.bike_song='missing';Audio.update(1/60);check(not api.status().ready and api.status().error,'invalid song reports unavailable overlay');near(Audio._bgmVolume,3/7,'invalid bicycle song fails open to area music')
values.bike_song='original';values.bike_song_resume=true;PlayerState.biking=true;Audio.update(1/60);local resumeStarts=starts;local resumeSource=made[#made]
PlayerState.biking=false;Audio.update(1/60);check(resumeSource.paused,'resume mode pauses on dismount');near(Audio._bgmVolume,5/7,'dismount restores native music option')
PlayerState.biking=true;Audio.update(1/60);check(starts==resumeStarts,'resume mode does not restart M4A sequencer');check(resumeSource.playing,'paused overlay resumes')
values.bike_song_resume=false;PlayerState.biking=false;Audio.update(1/60);local beforeRestart=starts;PlayerState.biking=true;Audio.update(1/60);check(starts==beforeRestart+1,'restart mode creates a new M4A slot')
values.bike_song_resume=true;Audio._fanfareActive=true;local fanfareSource=made[#made];Audio.update(1/60);check(fanfareSource.paused,'fanfare suspends overlay');near(Audio._bgmVolume,5/7,'fanfare restores native music gain')
Audio._fanfareActive=false;local beforeFanfareResume=starts;Audio.update(1/60);check(starts==beforeFanfareResume and fanfareSource.playing,'overlay resumes after fanfare')
values.bike_song_resume=false;values.bike_song='game:red:Music_Route1';PlayerState.biking=true;Audio.update(1/60)
check(api.status().ready and api.status().songKind=='chip'and api.status().songId=='Music_Route1','legacy song did not select chip backend');check(chipStarts==1 and chipRenders==1,'legacy song did not start/render exactly once');check(madeRates[#madeRates]==32768,'legacy overlay does not use ChipSynth sample rate');near(Audio._bgmVolume,0,'legacy bicycle-only playback suppresses area after ready')
local chipSource=made[#made];values.bike_song_resume=true;PlayerState.biking=false;Audio.update(1/60);check(chipSource.paused,'legacy overlay pauses for resume');PlayerState.biking=true;Audio.update(1/60);check(chipStarts==1 and chipSource.playing,'legacy sequencer resumes without restart')
local localKey='file:'..string.rep('a',64);values.bike_song_resume=false;values.bike_song=localKey;PlayerState.biking=true;local queuesBefore=#made;Audio.update(1/60)
local fileSource=localSources[#localSources];check(api.status().ready and api.status().songKind=='file'and api.status().songId==localKey,'local song did not select file backend');check(localOpens==1 and fileSource and fileSource.playing and fileSource.looping,'local source did not open/play/loop');check(#made==queuesBefore,'local song incorrectly allocated queueable source');near(fileSource.volume,2/7,'local song did not share bicycle volume')
values.bike_song_resume=true;PlayerState.biking=false;Audio.update(1/60);check(fileSource.paused,'local source did not pause for resume');PlayerState.biking=true;Audio.update(1/60);check(localOpens==1 and fileSource.playing,'local source did not resume without reopening')
values.bike_song_resume=false;PlayerState.biking=false;Audio.update(1/60);PlayerState.biking=true;Audio.update(1/60);check(localOpens==2 and localSources[#localSources]~=fileSource,'local restart did not reopen source')
-- Preview uses a second private renderer, restores native area gain and pauses
-- rather than destroys the current cycling source so it can resume afterwards.
values.bike_song='original';values.bike_song_resume=true;values.riding_music='bicycle';PlayerState.biking=true;Audio.update(1/60)
local cycling=made[#made];local beforePreviewStarts=starts;local ok,err=api.previewSong('firered:300',game);check(ok,err)
local ps=api.status();check(ps.preview and ps.previewReady and ps.previewKey=='firered:300'and ps.previewKind=='m4a','FireRed preview did not start');check(starts==beforePreviewStarts+1,'preview did not create independent M4A slot');check(cycling.paused,'preview did not pause cycling source');near(Audio._bgmVolume,5/7,'preview did not restore native map gain')
local previewSrc=made[#made];check(previewSrc~=cycling and previewSrc.playing,'preview source was not independent/playing')
Audio._fanfareActive=true;Audio.update(1/60);check(previewSrc.paused,'fanfare did not pause preview');Audio._fanfareActive=false;Audio.update(1/60);check(previewSrc.playing,'preview did not resume after fanfare')
local startAfterPreview=starts;api.stopPreview();Audio.update(1/60);check(cycling.playing and starts==startAfterPreview,'stopping preview did not resume existing cycling source')
PlayerState.biking=false;values.sfx_filter=2;Audio.update(1/60);check(se.filter and se.filter.highgain==0.16,'off-bike SFX filter applies');se.filter={type='lowpass',volume=1,highgain=0.9};values.sfx_filter=0;Audio.update(1/60);check(se.filter and se.filter.highgain==0.9,'newer external SFX filter wins during restore')
api.dispose();check(Audio.update==originalUpdate,'dispose restores native Audio.update');check(not api.status().overlay and not api.status().preview,'dispose removes private sources');check(#registered>=1,'asset lifecycle owns disposal');check(gains>0 and bgmFilters>0 and restores>0,'native runtime profiles were actively managed')
print('PASS independent FireRed cycling audio, song preview, fanfare safety, resume/restart and SFX filter ownership')
