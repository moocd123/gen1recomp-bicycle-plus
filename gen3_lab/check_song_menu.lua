local Catalog=dofile('gen3_lab/song_catalog.lua')
local SongMenu=dofile('gen3_lab/song_menu.lua')
local opened={};local menu={open=function(game,title,rows,opts)local page={game=game,title=title,rows=rows,opts=opts};opened[#opened+1]=page;return page end}
local value='original';local settings={get=function()return value end,set=function(_,key,v)assert(key=='bike_song');value=v;return true end}
local Audio={songInfo=function(id)if id==282 or id==300 or id==340 then return{kind='bgm'}end end}
local Legacy={}
function Legacy.editions()return{{id='red',label='RED',available=true},{id='blue',label='BLUE',available=false}}end
function Legacy.gameSongs(edition)
 assert(edition=='red');return{{id='game:red:Music_Bicycle',name='BICYCLE'},{id='game:red:Music_Route1',name='ROUTE1'}}
end
function Legacy.describe(key)
 if key=='game:red:Music_Route1'then return'RED: ROUTE1'end
end
local mod={exports={}}
local api=SongMenu.new(mod,settings,menu,Catalog,{Audio=Audio,Legacy=Legacy})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
api.open({});ck(opened[#opened].title=='BIKE SONG'and#opened[#opened].rows==3,'song root missing imported-games route')
local root=opened[#opened].rows;ck(root[1].value()=='ON','Original selection marker missing')
root[2].activate();local current=opened[#opened];ck(current.title=='FIRERED SOUNDTRACK'and#current.rows==3,'current soundtrack page incorrect')
ck(current.rows[1].label=='Bicycle'and current.rows[2].label=='Pallet Town'and current.rows[3].label=='Mewtwo Battle','current song labels incorrect')
current.rows[2].activate();ck(value=='firered:300'and current.rows[2].value()=='ON','current song selection did not persist')
ck(api.describe({})=='Pallet Town','current song description incorrect')
api.open({});root=opened[#opened].rows;root[3].activate();local games=opened[#opened]
ck(games.title=='OTHER GAME SONGS'and#games.rows==2,'imported-game edition browser incorrect')
ck(games.rows[2].value()=='NOT IMPORTED'and games.rows[2].activate==nil,'unavailable edition must not open')
games.rows[1].activate();local red=opened[#opened]
ck(red.title=='RED SOUNDTRACK'and#red.rows==2 and red.rows[2].label=='ROUTE1','legacy soundtrack page incorrect')
red.rows[2].activate();ck(value=='game:red:Music_Route1'and red.rows[2].value()=='ON','legacy song selection did not persist')
ck(api.describe({})=='RED: ROUTE1','legacy song description incorrect')
api.open({});opened[#opened].rows[1].activate();ck(value=='original'and api.describe({})=='ORIGINAL BICYCLE','Original restore failed')
ck(mod.exports.gen3SongMenu==api,'song menu diagnostic export missing')
print('PASS '..n..' FireRed current/imported-song menu assertions.')
