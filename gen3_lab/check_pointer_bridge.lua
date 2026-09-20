local Bridge=dofile('gen3_lab/pointer_bridge.lua')
local calls={mousePress=0,mouseMove=0,mouseRelease=0,touchPress=0,touchMove=0,touchRelease=0,page=0,key=0};local page={_autobikeGen3Pointer=true}
function page:pointer(phase,x,y,id)calls.page=calls.page+1;calls.last={phase,x,y,id};return true end
function page:rawKey(key)calls.key=calls.key+1;calls.lastKey=key;return true end
local layer={mod=page};local Stack={top=function()return layer end};local picker={active=function()return page end};local game={}
function game:mousepressed(...)calls.mousePress=calls.mousePress+1;return'mouse-press-chain'end;function game:mousemoved(...)calls.mouseMove=calls.mouseMove+1;return'mouse-move-chain'end
function game:mousereleased(...)calls.mouseRelease=calls.mouseRelease+1;return'mouse-release-chain'end;function game:touchpressed(...)calls.touchPress=calls.touchPress+1;return'touch-press-chain'end
function game:touchmoved(...)calls.touchMove=calls.touchMove+1;return'touch-move-chain'end;function game:touchreleased(...)calls.touchRelease=calls.touchRelease+1;return'touch-release-chain'end
local original={mousepressed=game.mousepressed,mousemoved=game.mousemoved,mousereleased=game.mousereleased,touchpressed=game.touchpressed,touchmoved=game.touchmoved,touchreleased=game.touchreleased}
local releases={};local Assets={register=function(v)releases[#releases+1]=v end};local Display={W=240,H=160,fit=function()return2,10,20,480,320,2 end};local keyHook
local mod={game=game,hooks={wrap=function(_,name,fn)if name=='input.key'then keyHook=fn end end}}
local b=Bridge.attach(mod,picker,{Display=Display,Stack=Stack,graphics={getDimensions=function()return640,480 end},Assets=Assets})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local gx,gy,inside=b.coordinates(30,60);ck(inside and gx==10 and gy==20,'coordinate conversion failed')
local used=game:mousepressed(30,60,1,false);ck(used==true and calls.page==1 and calls.mousePress==0,'inside mouse press not routed');ck(calls.last[1]=='pressed'and calls.last[2]==10 and calls.last[3]==20,'mouse payload wrong')
ck(game:mousemoved(110,120,80,60,false)==true and calls.last[1]=='moved','captured move not routed');ck(game:mousemoved(650,500,540,380,false)==true and calls.last[2]==320,'outside captured move lost');ck(game:mousereleased(650,500,1,false)==true and calls.last[1]=='released','release not routed');ck(game:mousemoved(110,120,0,0,false)=='mouse-move-chain','capture did not end')
ck(game:mousepressed(2,2,1,false)=='mouse-press-chain','outside mouse should chain');ck(game:mousepressed(30,60,1,true)=='mouse-press-chain','istouch mouse should chain')
ck(game:touchpressed('finger',50,80,0,0,1)==true and calls.last[4]=='finger','touch press not routed');ck(game:touchmoved('finger',70,100,20,20,1)==true and calls.last[1]=='moved','touch move not routed');ck(game:touchreleased('finger',70,100,0,0,1)==true and calls.last[1]=='released','touch release not routed')
local chained=0;local next=function()chained=chained+1;return'next'end;ck(keyHook and keyHook(next,game,{phase='pressed',key='a'})==true and calls.key==1 and calls.lastKey=='a','raw pressed key not routed');ck(keyHook(next,game,{phase='released',key='a'})=='next'and chained==1,'key release must retain native chain')
layer=nil;picker.active=function()return nil end;ck(game:touchpressed('finger',50,80,0,0,1)=='touch-press-chain','inactive modal should chain')
ck(#releases==1 and releases[1].release,'cleanup registration missing');releases[1].release();for name,fn in pairs(original)do ck(game[name]==fn,'dispose did not restore '..name)end
print('PASS '..n..' FireRed modal pointer/raw-key bridge assertions.')
