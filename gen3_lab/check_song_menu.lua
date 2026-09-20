local Catalog=dofile('gen3_lab/song_catalog.lua')
local SongMenu=dofile('gen3_lab/song_menu.lua')
local opened={};local menu={open=function(game,title,rows,opts)local page={game=game,title=title,rows=rows,opts=opts};opened[#opened+1]=page;return page end}
local value='original';local settings={get=function()return value end,set=function(_,key,v)assert(key=='bike_song');value=v;return true end}
local Audio={songInfo=function(id)if id==282 or id==300 or id==340 then return{kind='bgm'}end end}
local mod={exports={}}
local api=SongMenu.new(mod,settings,menu,Catalog,{Audio=Audio})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
api.open({});ck(opened[#opened].title=='BIKE SONG'and#opened[#opened].rows==2,'song root missing')
local root=opened[#opened].rows;ck(root[1].value()=='ON','Original selection marker missing')
root[2].activate();local current=opened[#opened];ck(current.title=='FIRERED SOUNDTRACK'and#current.rows==3,'current soundtrack page incorrect')
ck(current.rows[1].label=='Bicycle'and current.rows[2].label=='Pallet Town'and current.rows[3].label=='Mewtwo Battle','current song labels incorrect')
current.rows[2].activate();ck(value=='firered:300'and current.rows[2].value()=='ON','song selection did not persist')
ck(api.describe({})=='Pallet Town','selected song description incorrect')
api.open({});opened[#opened].rows[1].activate();ck(value=='original'and api.describe({})=='ORIGINAL BICYCLE','Original restore failed')
ck(mod.exports.gen3SongMenu==api,'song menu diagnostic export missing')
print('PASS '..n..' FireRed current-song menu assertions.')
