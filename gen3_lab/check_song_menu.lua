local Catalog=dofile('gen3_lab/song_catalog.lua');local SongMenu=dofile('gen3_lab/song_menu.lua')
local opened={};local menu={open=function(game,title,rows,opts)local p={game=game,title=title,rows=rows,opts=opts,close=function()end};opened[#opened+1]=p;return p end}
local value='original';local settings={get=function()return value end,set=function(_,key,v)assert(key=='bike_song');value=v;return true end}
local Audio={songInfo=function(id)if id==282 or id==300 or id==340 then return{kind='bgm'}end end}
local Legacy={};function Legacy.editions()return{{id='red',label='RED',available=true},{id='blue',label='BLUE',available=false}}end
function Legacy.gameSongs(edition)assert(edition=='red');return{{id='game:red:Music_Bicycle',name='BICYCLE'},{id='game:red:Music_Route1',name='ROUTE1'}}end
function Legacy.describe(key)if key=='game:red:Music_Route1'then return'RED: ROUTE1'end end
local fileKey='file:'..string.rep('a',64);local importedKey='file:'..string.rep('c',64)
local Local={removed=nil,renamed=nil};function Local.files()return{{id=fileKey,name='MY ROAD SONG',missing=false},{id='file:'..string.rep('b',64),name='MISSING SONG',missing=true}}end
function Local.describe(key)if key==fileKey then return'MY ROAD SONG'elseif key==importedKey then return'NEW IMPORT'end end
function Local.remove(id)Local.removed=id;return true end;function Local.rename(id,name)Local.renamed={id,name};return true end
local previewKey=nil;local previewCalls=0;local Preview={};function Preview.status()return{preview=previewKey~=nil,previewKey=previewKey}end
function Preview.previewSong(key)previewKey=key;previewCalls=previewCalls+1;return true end;function Preview.stopPreview()previewKey=nil;return true end
local TextEntry={open=function(game,title,initial,max,save)assert(title=='SONG NAME'and max==24);return save('RENAMED SONG')end}
local pending=false;local mode='direct';local cancelled=0;local Importer={}
function Importer.choose()if mode=='pending'then pending=true;return'pending'end;return{id=importedKey,name='NEW IMPORT'},'IMPORTED'end
function Importer.hasWork()return pending end;function Importer.poll()if pending then pending=false;return{id=fileKey,name='MY ROAD SONG'},'IMPORTED'end end
function Importer.cancel()cancelled=cancelled+1 end
local mod={exports={}};local api=SongMenu.new(mod,settings,menu,Catalog,{Audio=Audio,Legacy=Legacy,Local=Local,Importer=Importer,Preview=Preview,TextEntry=TextEntry})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
api.open({});local root=opened[#opened].rows;ck(opened[#opened].title=='BIKE SONG'and#root==5,'song root missing routes');ck(root[1].value()=='ON','Original marker missing')
root[2].activate();local current=opened[#opened];ck(current.title=='FIRERED SOUNDTRACK'and#current.rows==3,'current soundtrack page incorrect');current.rows[2].activate();local detail=opened[#opened]
ck(detail.title=='SONG OPTIONS'and detail.rows[1].label()=='PREVIEW SONG','current song detail/preview missing');detail.rows[1].activate();ck(previewKey=='firered:300'and previewCalls==1 and detail.rows[1].label()=='STOP PREVIEW','preview toggle failed');detail.rows[2].activate();ck(value=='firered:300','current song selection failed');ck(api.describe({})=='Pallet Town','current description incorrect')
api.open({});root=opened[#opened].rows;root[3].activate();local games=opened[#opened];ck(games.rows[2].value()=='NOT IMPORTED'and games.rows[2].activate==nil,'unavailable edition must not open');games.rows[1].activate();local red=opened[#opened];red.rows[2].activate();detail=opened[#opened];detail.rows[2].activate();ck(value=='game:red:Music_Route1'and api.describe({})=='RED: ROUTE1','legacy song detail/use failed')
api.open({});root=opened[#opened].rows;root[4].activate();local localPage=opened[#opened];ck(localPage.rows[2].activate==nil and localPage.rows[2].label:find('MISSING:',1,true),'missing local song should be disabled');localPage.rows[1].activate();detail=opened[#opened]
ck(#detail.rows==4,'local detail must expose preview/use/rename/remove');detail.rows[3].activate();ck(Local.renamed and Local.renamed[1]==fileKey and Local.renamed[2]=='RENAMED SONG','local rename not wired');detail.rows[2].activate();ck(value==fileKey,'local use failed');detail.rows[4].activate();local confirm=opened[#opened];ck(confirm.title=='REMOVE LOCAL SONG?'and#confirm.rows==2,'remove confirmation missing');confirm.rows[2].activate();ck(Local.removed==fileKey and value=='original','confirmed remove did not restore Original')
api.open({});root=opened[#opened].rows;root[5].activate();ck(value==importedKey and api.importStatus()=='SELECTED: NEW IMPORT','direct import failed');mode='pending';root[5].activate();ck(api.importStatus()=='CHOOSING AUDIO FILE','pending status missing');api.poll({},.1);ck(value==fileKey and api.importStatus()=='SELECTED: MY ROAD SONG','pending import completion failed')
local rootPage=api.open({});rootPage.opts.exit();ck(cancelled>=1 and previewKey==nil,'root exit did not cancel picker/preview');rootPage.rows[1].activate();ck(value=='original'and api.describe({})=='ORIGINAL BICYCLE','Original restore failed');ck(mod.exports.gen3SongMenu==api,'diagnostic export missing')
print('PASS '..n..' FireRed song browse/preview/rename/remove/import assertions.')
