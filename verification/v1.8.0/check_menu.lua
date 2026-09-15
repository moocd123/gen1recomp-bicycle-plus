local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
local T=dofile('verification/v1.8.0/support.lua');T.install()
local Screens=require('src.ui.Screens');local Stack=require('src.core.StateStack');local GV=require('src.core.GameVersion')
local function noop()end
for _,ed in ipairs({'red','blue','yellow','gold','silver','crystal'})do
 Screens.invalidate();GV.set(ed)
 local g={data={screens={}},input={pressed={}},stack=setmetatable({},{__index=Stack}),writes=0}
 g.stack:init();function g.input:wasPressed(k)return self.pressed[k]end;function g.input:isDown()return false end
 local m=T.mod();function m.content.screens:register(id,def)g.data.screens[id]=def end
 local U=dofile('colour_ui.lua').init(m)
 local draw=U.text;local texts={}
 U.text=function(s,x,y,scale)T.check(x>=0 and x+U.width(s,scale)<=160 and y>=0 and y+7*(scale or 1)<=144,'menu text offscreen: '..s);texts[#texts+1]={s=s,x=x,y=y,w=U.width(s,scale),h=7*(scale or 1)};return draw(s,x,y,scale)end
 local set={bike_song='original',bike_song_restart='restart'}
 local id='file:'..string.rep('a',64);local exists=true;local plays=0;local selection
 local L={title=function(x)return x==id and 'A LONG PERSONAL TRACK TITLE TO SCROLL ACROSS THE DISPLAY' or 'ORIGINAL BICYCLE'end,
  resolve=function(_,x)return{def={},label=x}end,
  myAudio=function()return exists and{{id=id,title='IMPORTED SONG'}}or{}end,
  gameList=function(_,v)local rows={};for i=1,12 do rows[i]={id='game:'..ed..':Music_'..i,title='GAME SONG '..i}end;return rows end,
  editions=function()return{{version='red',title='RED',available=true},{version='blue',title='BLUE',available=false}}end,
  remove=function(x)T.eq(x,id);exists=false;return true end,
  rename=function(x,name)T.eq(x,id);T.eq(name,'HELLO');return true end}
 local A={stopPreview=function()selection=nil end,isPreviewing=function()return selection~=nil end,stop=function()selection=nil end,
  preview=function(_,x)selection=x;plays=plays+1;return true end,refresh=noop}
 local I={inboxLabel='mods/bicycle_plus/baseroms/audio_inbox',inbox=function()return{{name='a.wav'}}end,
  fromInbox=function()return id end,start=function()I.pending=true;return true end,poll=noop,cancel=function()I.pending=false end}
 -- Lua's local scope begins after its initializer; closures use a separate declaration.
 I.start=function()I.pending=true;return true end;I.cancel=function()I.pending=false end
 local Menu=dofile('song_menu.lua').init(m,{ui=U,library=L,audio=A,importer=I,getSetting=function(k)return set[k]end,setSetting=function(_,k,v)set[k]=v;g.writes=g.writes+1;return true end})
 local function tap(k)g.input.pressed={[k]=true};g.stack:update(.016);g.input.pressed={}end
 local function frame()
  texts={};local s=g.stack:top();s:draw()
  for i,a in ipairs(texts)do for j=1,i-1 do local b=texts[j];T.check(not(a.x<b.x+b.w and b.x<a.x+a.w and a.y<b.y+b.h and b.y<a.y+a.h),'overlapping text '..a.s..'/'..b.s)end end
 end
 Menu.open(g);local root=g.stack:top();frame();T.eq(#root.rows,8)
 root.index=2;tap('a');local list=g.stack:top();frame();T.eq(#list.rows,12)
 tap('select');T.eq(selection,'game:'..ed..':Music_1');tap('down');T.check(not selection,'preview persists during navigation')
 tap('right');frame();T.eq(list.index,8,'paging')
 tap('a');frame();tap('a');T.eq(set.bike_song,'game:'..ed..':Music_8','song not applied')
 tap('b');T.eq(g.stack:top(),root)
 root.index=3;tap('a');frame();tap('down');tap('a');frame();tap('b');tap('b');T.eq(g.stack:top(),root)
 root.index=4;tap('a');frame();tap('a');frame();local detail=g.stack:top()
 detail.index=3;tap('a');frame();local name=g.stack:top();for ch in ('hello'):gmatch('.')do name:rawKey(ch)end;name:rawKey('return');T.eq(g.stack:top(),detail)
 detail.index=4;tap('a');frame();tap('a');T.check(exists,'default REMOVE confirmation deleted file')
 detail.index=4;tap('a');tap('down');tap('a');T.check(not exists,'confirmed delete failed');frame()
 while g.stack:top()~=root do tap('b')end
 root.index=5;tap('a');frame();T.check(I.pending,'native importer not started');I.result=id;I.pending=false;g.stack:update(.016);frame()
 while g.stack:top()~=root do tap('b')end
 root.index=6;tap('a');frame();tap('a');frame();tap('b');tap('b');T.eq(g.stack:top(),root)
 root.index=7;root:clamp();frame();tap('a');T.eq(set.bike_song_restart,'resume')
 root.index=8;root:clamp();frame();tap('a');T.check(not g.stack:top(),'song stack did not unwind')
end
print(('PASS %d menu text/layout, six-context controls, preview, import, rename/remove and navigation checks with native Screens/StateStack.'):format(T.count))
