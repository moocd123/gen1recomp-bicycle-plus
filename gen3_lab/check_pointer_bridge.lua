local Bridge=dofile('gen3_lab/pointer_bridge.lua')
local calls={mouse=0,touch=0,picker=0};local page={}
function page:pointer(phase,x,y,id)calls.picker=calls.picker+1;calls.last={phase,x,y,id};return true end
local picker={active=function()return page end}
local game={}
function game:mousepressed(...)calls.mouse=calls.mouse+1;return'mouse-chain'end
function game:touchpressed(...)calls.touch=calls.touch+1;return'touch-chain'end
local originalMouse,originalTouch=game.mousepressed,game.touchpressed
local releases={};local Assets={register=function(v)releases[#releases+1]=v end}
local Display={W=240,H=160,fit=function()return 2,10,20,480,320,2 end}
local b=Bridge.attach({game=game},picker,{Display=Display,graphics={getDimensions=function()return 640,480 end},Assets=Assets})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local gx,gy,inside=b.coordinates(30,60);ck(inside and gx==10 and gy==20,'window to 240x160 conversion failed')
local used=game:mousepressed(30,60,1,false);ck(used==true and calls.picker==1 and calls.mouse==0,'inside mouse press not routed to picker')
ck(calls.last[1]=='pressed'and calls.last[2]==10 and calls.last[3]==20 and calls.last[4]=='mouse','mouse payload incorrect')
local outside=game:mousepressed(2,2,1,false);ck(outside=='mouse-chain'and calls.mouse==1,'outside mouse press did not chain')
local fakeTouchMouse=game:mousepressed(30,60,1,true);ck(fakeTouchMouse=='mouse-chain'and calls.mouse==2,'istouch mouse event should stay on native path')
local touch=game:touchpressed('finger',50,80,0,0,1);ck(touch==true and calls.picker==2 and calls.touch==0,'touch press not routed to picker')
ck(calls.last[4]=='finger'and calls.last[2]==20 and calls.last[3]==30,'touch payload/coordinates incorrect')
picker.active=function()return nil end
ck(game:touchpressed('finger',50,80,0,0,1)=='touch-chain'and calls.touch==1,'inactive picker should chain touch')
ck(#releases==1 and releases[1].release,'cleanup registration missing')
releases[1].release();ck(game.mousepressed==originalMouse and game.touchpressed==originalTouch,'dispose did not restore Game3 methods')
print('PASS '..n..' FireRed picker pointer-bridge assertions.')
