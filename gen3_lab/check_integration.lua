local Integration=dofile('gen3_lab/integration.lua')
local rowsModule={};local baseBuild=function()return{{id='vanilla',label='VANILLA'}}end;rowsModule.build=baseBuild
local releases={};local Assets={register=function(v)releases[#releases+1]=v end}
local bus={safeMode=false,hooks={},events={}}
local opened={};local menu={open=function(game,title,rows)opened[#opened+1]={game=game,title=title,rows=rows};return rows end}
local values={auto_mount=true,sfx_filter=0,riding_music='bicycle',riding_area_volume=-1,riding_area_filter=-1,
 riding_sfx_volume=-1,riding_sfx_filter=-1,bike_volume=4,bike_filter=0,bike_song='original',bike_song_resume=false,
 spelling='uk',bike_frame_colour='original',bike_tyres_colour='original',bike_rims_colour='original',bike_spokes_colour='original',bike_handlebars_colour='original'}
local ensured,setCalls=0,{}
local settings={get=function(k)return values[k]end,ensure=function()ensured=ensured+1;return true end,
 set=function(_,k,v)values[k]=v;setCalls[#setCalls+1]={k,v};return true end}
local mountDisposed=false;local NativeMount={attach=function(mod,machine,get)
 assert(get('auto_mount')==true);return{dispose=function()mountDisposed=true end}end}
local callbacks={};local hooks={};local pickerCalls={};local invalidated=0
local game={options={frameType=0}}
local mod={id='autobike_plus_firered_beta',game=game,exports={},events={on=function(_,name,fn)callbacks[name]=fn end},
 hooks={wrap=function(_,name,fn)hooks[name]=fn end}}
local api=Integration.attach(mod,{Version={get=function()return'firered'end,generation=function()return 3 end},Runtime=bus,
 Rows=rowsModule,Assets=Assets,settings=settings,menu=menu,NativeMount=NativeMount,Machine={},
 openColourPart=function(g,k,l)pickerCalls[#pickerCalls+1]={g,k,l}end,invalidatePaint=function()invalidated=invalidated+1 end})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local built=rowsModule.build({game=game});ck(#built==2 and built[2].id=='autobike_plus_firered_beta.settings','Options row not injected')
built[2].activate({game=game});ck(opened[#opened].title=='AUTOBIKE+'and#opened[#opened].rows==5,'native settings page not opened')
local top=opened[#opened].rows;top[1].step(1);ck(values.auto_mount==false,'Auto Bike row did not persist')
top[2].step(1);ck(values.sfx_filter==1,'off-bike SFX filter row did not step')
top[3].activate();ck(opened[#opened].title=='BIKE APPEARANCE'and#opened[#opened].rows==6,'Bike Appearance page incomplete')
local appearance=opened[#opened].rows;appearance[1].activate();ck(#pickerCalls==1 and pickerCalls[1][2]=='bike_frame_colour','part row did not open colour picker')
values.bike_frame_colour='#123456';appearance[6].activate();ck(values.bike_frame_colour=='original'and invalidated==1,'paint-only reset failed')
top[4].activate();ck(opened[#opened].title=='BIKE AUDIO'and#opened[#opened].rows==9,'Bike Audio page incomplete')
local audio=opened[#opened].rows;audio[1].step(1);ck(values.riding_music=='both','AREA/BICYCLE/BOTH cycle failed')
audio[2].step(1);ck(values.riding_area_volume==0,'inherited riding area volume did not step from SAME to OFF')
audio[9].step(1);ck(values.bike_song_resume==true,'restart/resume row failed')
callbacks['game.ready']({game=game});ck(ensured>=2,'game.ready did not seed settings')
ck(type(hooks['core.quit_to_launcher'])=='function','quit cleanup hook missing')
ck(#releases==1 and type(releases[1].release)=='function','asset cleanup registration missing')
releases[1].release();ck(rowsModule.build==baseBuild and mountDisposed,'dispose did not restore engine wrappers')
ck(mod.exports.openSettings==api.openSettings and mod.exports.gen3Settings==settings,'diagnostic exports missing')
print('PASS '..n..' FireRed lifecycle/native-menu integration assertions.')
