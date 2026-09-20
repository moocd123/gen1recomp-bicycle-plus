local Bridge=dofile('gen3_lab/pointer_bridge.lua')
local calls={mousePress=0,mouseMove=0,mouseRelease=0,touchPress=0,touchMove=0,touchRelease=0,picker=0};local page={}
function page:pointer(phase,x,y,id)calls.picker=calls.picker+1;calls.last={phase,x,y,id};return true end
local picker={active=function()return page end}
local game={}
function game:mousepressed(...)calls.mousePress=calls.mousePress+1;return'mouse-press-chain'end
function game:mousemoved(...)calls.mouseMove=calls.mouseMove+1;return'mouse-move-chain'end
function game:mousereleased(...)calls.mouseRelease=calls.mouseRelease+1;return'mouse-release-chain'end
function game:touchpressed(...)calls.touchPress=calls.touchPress+1;return'touch-press-chain'end
function game:touchmoved(...)calls.touchMove=calls.touchMove+1;return'touch-move-chain'end
function game:touchreleased(...)calls.touchRelease=calls.touchRelease+1;return'touch-release-chain'end
local original={mousepressed=game.mousepressed,mousemoved=game.mousemoved,mousereleased=game.mousereleased,
 touchpressed=game.touchpressed,touchmoved=game.touchmoved,touchreleased=game.touchreleased}
local releases={};local Assets={register=function(v)releases[#releases+1]=v end}
local Display={W=240,H=160,fit=function()return 2,10,20,480,320,2 end}
local b=Bridge.attach({game=game},picker,{Display=Display,graphics={getDimensions=function()return 640,480 end},Assets=Assets})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local gx,gy,inside=b.coordinates(30,60);ck(inside and gx==10 and gy==20,'window to 240x160 conversion failed')
local used=game:mousepressed(30,60,1,false);ck(used==true and calls.picker==1 and calls.mousePress==0,'inside mouse press not routed to picker')
ck(calls.last[1]=='pressed'and calls.last[2]==10 and calls.last[3]==20 and calls.last[4]=='mouse','mouse press payload incorrect')
local moved=game:mousemoved(110,120,80,60,false);ck(moved==true and calls.mouseMove==0 and calls.last[1]=='moved','captured mouse move not routed')
ck(calls.last[2]==50 and calls.last[3]==50,'captured mouse move coordinates incorrect')
-- Capture remains owned by the modal picker even outside the game viewport so
-- a drag may leave and later re-enter without leaking into native touch input.
local movedOutside=game:mousemoved(650,500,540,380,false);ck(movedOutside==true and calls.mouseMove==0 and calls.last[2]==320 and calls.last[3]==240,'outside captured move was lost')
local released=game:mousereleased(650,500,1,false);ck(released==true and calls.mouseRelease==0 and calls.last[1]=='released','captured mouse release not routed')
ck(game:mousemoved(110,120,0,0,false)=='mouse-move-chain'and calls.mouseMove==1,'mouse capture did not end on release')
local outside=game:mousepressed(2,2,1,false);ck(outside=='mouse-press-chain'and calls.mousePress==1,'outside mouse press did not chain')
local fakeTouchMouse=game:mousepressed(30,60,1,true);ck(fakeTouchMouse=='mouse-press-chain'and calls.mousePress==2,'istouch mouse press should stay on native path')
ck(game:mousemoved(30,60,0,0,true)=='mouse-move-chain'and calls.mouseMove==2,'istouch mouse move should stay on native path')
ck(game:mousereleased(30,60,1,true)=='mouse-release-chain'and calls.mouseRelease==1,'istouch mouse release should stay on native path')
local touch=game:touchpressed('finger',50,80,0,0,1);ck(touch==true and calls.touchPress==0,'touch press not routed to picker')
ck(calls.last[4]=='finger'and calls.last[2]==20 and calls.last[3]==30,'touch press payload/coordinates incorrect')
local touchMove=game:touchmoved('finger',70,100,20,20,1);ck(touchMove==true and calls.touchMove==0 and calls.last[1]=='moved'and calls.last[2]==30 and calls.last[3]==40,'captured touch move not routed')
local touchRelease=game:touchreleased('finger',70,100,0,0,1);ck(touchRelease==true and calls.touchRelease==0 and calls.last[1]=='released','captured touch release not routed')
ck(game:touchmoved('finger',70,100,0,0,1)=='touch-move-chain'and calls.touchMove==1,'touch capture did not end on release')
picker.active=function()return nil end
ck(game:touchpressed('finger',50,80,0,0,1)=='touch-press-chain'and calls.touchPress==1,'inactive picker should chain touch')
ck(#releases==1 and releases[1].release,'cleanup registration missing')
releases[1].release()
for name,fn in pairs(original)do ck(game[name]==fn,'dispose did not restore Game3 '..name)end
print('PASS '..n..' FireRed picker pointer-bridge assertions.')
