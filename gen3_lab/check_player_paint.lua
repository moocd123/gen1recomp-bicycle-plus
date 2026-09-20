local Shade=dofile('gen3_lab/shading.lua');local Paint=dofile('gen3_lab/player_paint.lua')
local N=32*32*9*4;local src=string.char(197,58,58,255)..string.rep('\0',N-4)
local imageData={getString=function()return src end,release=function()end}
local source={newImageData=function()return imageData end}
local spr={image=source,width=32,height=32,frameCount=9,quads={[0]='q0'}}
local original=0;local Ow={}
function Ow.get(id)return id==1 and spr or nil end
function Ow.playerGraphicsId()return 1 end
function Ow.pose()return 0,false end
function Ow.draw(...)original=original+1;return true end
local oldDraw=Ow.draw
local draws=0;local madeBytes
local G={setColor=function()end,newImage=function(data)return{setFilter=function()end,release=function()end,tag='paint'}end,
 draw=function(image,q,x,y)assert(image.tag=='paint'and q=='q0');draws=draws+1 end}
local I={newImageData=function(w,h,fmt,bytes)madeBytes=bytes;return{release=function()end}end}
local P={biking=true,px=100,py=50,facing='down',spriteXOffset=0,spriteYOffset=0,jumpSpriteY=function()return 0 end}
local game={};local values={bike_frame_colour='#0080ff',bike_tyres_colour='original',bike_rims_colour='original',
 bike_spokes_colour='original',bike_handlebars_colour='original'}
local settings={get=function(k)return values[k]end}
local Parts={verify=function(bytes,gid,sha)return#bytes==N and gid==1 and sha(bytes)=='ok'end,
 sheet=function(x,y,r,g,b,a)if x==0 and y==0 and a>0 then return'frame'end end}
local releases={};local Runtime={safeMode=false};local api=Paint.attach({game=game},Parts,Shade,settings,{OwSprites=Ow,Player=P,Runtime=Runtime,
 GameRuntime={_game=game},Assets={register=function(v)releases[#releases+1]=v end},Love={graphics=G,image=I},sha256=function()return'ok'end})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
ck(Ow.draw~=oldDraw,'draw wrapper not installed')
ck(Ow.draw(1,100,50,0,0,'down',0,false)==true and draws==1 and original==0,'player bike did not use private painted image')
ck(type(madeBytes)=='string'and#madeBytes==N and madeBytes:sub(1,4)~=src:sub(1,4),'paint transform not applied')
Ow.draw(1,116,50,0,0,'down',0,false);ck(original==1 and draws==1,'same bike graphics on non-player position was recoloured')
P.biking=false;Ow.draw(1,100,50,0,0,'down',0,false);ck(original==2,'walking player intercepted')
P.biking=true;values.bike_frame_colour='original';Ow.draw(1,100,50,0,0,'down',0,false);ck(original==3,'all-Original did not use exact vanilla path')
values.bike_frame_colour='#ff0000';Ow.draw(1,100,50,0,0,'up',0,false);ck(original==4,'different actor/facing was intercepted')
P.facing='up';Ow.draw(1,100,50,0,0,'up',0,false);ck(draws==2,'valid changed facing did not paint')
ck(api.status().error==nil and api.status().paintedPixels==1,'paint status incorrect')
api.dispose();ck(Ow.draw==oldDraw,'draw wrapper not restored')
ck(#releases==1,'asset cleanup not registered')
print('PASS '..n..' player-only private bicycle paint interception assertions.')
