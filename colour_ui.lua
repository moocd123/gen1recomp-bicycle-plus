-- Compact, deterministic 5x7 UI. No external font or missing cursor glyph.
-- All positions are native 160x144 pixels; game sprite scale stays unchanged.
local UI={}
local glyphs={
 A={'01110','10001','10001','11111','10001','10001','10001'},
 B={'11110','10001','10001','11110','10001','10001','11110'},
 C={'01111','10000','10000','10000','10000','10000','01111'},
 D={'11110','10001','10001','10001','10001','10001','11110'},
 E={'11111','10000','10000','11110','10000','10000','11111'},
 F={'11111','10000','10000','11110','10000','10000','10000'},
 G={'01111','10000','10000','10111','10001','10001','01111'},
 H={'10001','10001','10001','11111','10001','10001','10001'},
 I={'111','010','010','010','010','010','111'},
 J={'00111','00010','00010','00010','10010','10010','01100'},
 K={'10001','10010','10100','11000','10100','10010','10001'},
 L={'10000','10000','10000','10000','10000','10000','11111'},
 M={'10001','11011','10101','10101','10001','10001','10001'},
 N={'10001','11001','10101','10011','10001','10001','10001'},
 O={'01110','10001','10001','10001','10001','10001','01110'},
 P={'11110','10001','10001','11110','10000','10000','10000'},
 Q={'01110','10001','10001','10001','10101','10010','01101'},
 R={'11110','10001','10001','11110','10100','10010','10001'},
 S={'01111','10000','10000','01110','00001','00001','11110'},
 T={'11111','00100','00100','00100','00100','00100','00100'},
 U={'10001','10001','10001','10001','10001','10001','01110'},
 V={'10001','10001','10001','10001','10001','01010','00100'},
 W={'10001','10001','10001','10101','10101','10101','01010'},
 X={'10001','10001','01010','00100','01010','10001','10001'},
 Y={'10001','10001','01010','00100','00100','00100','00100'},
 Z={'11111','00001','00010','00100','01000','10000','11111'},
 ['0']={'01110','10001','10011','10101','11001','10001','01110'},
 ['1']={'00100','01100','00100','00100','00100','00100','01110'},
 ['2']={'01110','10001','00001','00010','00100','01000','11111'},
 ['3']={'11110','00001','00001','01110','00001','00001','11110'},
 ['4']={'00010','00110','01010','10010','11111','00010','00010'},
 ['5']={'11111','10000','10000','11110','00001','00001','11110'},
 ['6']={'01110','10000','10000','11110','10001','10001','01110'},
 ['7']={'11111','00001','00010','00100','01000','01000','01000'},
 ['8']={'01110','10001','10001','01110','10001','10001','01110'},
 ['9']={'01110','10001','10001','01111','00001','00001','01110'},
 [':']={'0','1','1','0','1','1','0'},['-']={'000','000','000','111','000','000','000'},
 ['/']={'00001','00001','00010','00100','01000','10000','10000'},
 ['#']={'01010','11111','01010','01010','11111','01010','00000'},
 ['.']={'0','0','0','0','0','1','1'},['?']={'01110','10001','00001','00010','00100','00000','00100'},
 ['+']={'00000','00100','00100','11111','00100','00100','00000'},
}
function UI.init(mod)
 local U={}
 function U.white()love.graphics.setColor(1,1,1,1)end
 function U.ink()love.graphics.setColor(0,0,0,1)end
 function U.background()U.white();love.graphics.rectangle('fill',0,0,160,144)end
 function U.width(s,scale)return math.max(0,#tostring(s)*6-1)*(scale or 1)end
 function U.text(s,x,y,scale)
  s=tostring(s):upper();scale=scale or 1;U.ink()
  for i=1,#s do
   local ch=s:sub(i,i);local glyph=glyphs[ch]or(ch~=' 'and glyphs['?'])
   if glyph then
    local offset=math.floor((5-#glyph[1])/2)
    for row,bits in ipairs(glyph)do for col=1,#bits do if bits:sub(col,col)=='1'then
     love.graphics.rectangle('fill',x+((i-1)*6+offset+col-1)*scale,y+(row-1)*scale,scale,scale)
    end end end
   end
  end
 end
 function U.centre(s,y,scale)U.text(s,math.floor((160-U.width(s,scale))/2),y,scale)end
 function U.border(x,y,w,h)
  U.ink();local G=love.graphics
  G.rectangle('fill',x,y,w,1);G.rectangle('fill',x,y+h-1,w,1)
  G.rectangle('fill',x,y,1,h);G.rectangle('fill',x+w-1,y,1,h)
 end
 function U.focus(x,y,w,h)love.graphics.setColor(0.78,0.88,0.97,1);love.graphics.rectangle('fill',x,y,w,h);U.ink()end
 function U.marker(x,y)
  U.ink();for i=0,3 do love.graphics.rectangle('fill',x+i,y+i,1,7-i*2)end
 end
 function U.button(s,r,selected)
  if selected then U.focus(r[1],r[2],r[3],r[4])end
  U.border(r[1],r[2],r[3],r[4]);U.text(s,r[1]+math.floor((r[3]-U.width(s))/2),r[2]+math.floor((r[4]-7)/2))
 end
 function U.hit(x,y,r)return type(x)=='number'and type(y)=='number'and x>=r[1]and x<r[1]+r[3]and y>=r[2]and y<r[2]+r[4]end
 function U.tapDirection(self)
  for _,key in ipairs({'up','down','left','right'})do
   if self.game.input:wasPressed(key)then return key end
  end
 end
 function U.marquee(s,x,y,columns,timer)
  s=tostring(s or ''):upper():gsub('[^A-Z0-9 :/#%.%+%-]',' ')
  if #s<=columns then U.text(s,x,y);return end
  local span=#s-columns
  local travel=span/5
  local t=(timer or 0)%(2*travel+2.4)
  local offset
  if t<1.2 then offset=0
  elseif t<1.2+travel then offset=math.floor((t-1.2)*5)
  elseif t<2.4+travel then offset=span
  else offset=math.max(0,span-math.floor((t-2.4-travel)*5))end
  U.text(s:sub(offset+1,offset+columns),x,y)
 end
 function U.direction(self,dt)
  local input=self.game.input
  for _,k in ipairs({'up','down','left','right'})do
   if input:wasPressed(k)then self.repeatKey=k;self.repeatClock=0.28;return k end
  end
  local k=self.repeatKey
  if k and input.isDown and input:isDown(k)then
   self.repeatClock=(self.repeatClock or 0.28)-(dt or 0)
   if self.repeatClock<=0 then self.repeatClock=0.035;return k end
  else self.repeatKey=nil end
 end
 function U.preview(C,game,x,y,scale,timer,overrides,facing)
  -- Use the published renderer unchanged: crop its native three-view preview.
  -- Scissor coordinates are transformed to the current target, including Gen 2's fit.
  local G=love.graphics;G.push("all")
  local ok,result=pcall(function()
    local x1,y1=G.transformPoint(x,y);local x2,y2=G.transformPoint(x+16*scale,y+16*scale)
    G.intersectScissor(math.floor(x1),math.floor(y1),math.ceil(x2)-math.floor(x1),math.ceil(y2)-math.floor(y1))
    return C.drawPreview(game,x-(facing=="down"and 0 or 48*scale),y,scale,timer,overrides)
  end)
  G.pop();if not ok then error(result,0)end;return result
 end
 function U.zones()return{{colors=false,x=0,y=0,w=160,h=144}}end
 local Viewport=require('src.render.GameViewport');local latest=setmetatable({},{__mode='k'})
 mod.hooks:wrap('render.hud',function(next,game,view)
  if type(view)=='table'then latest[game]=view end
  return next(game,view)
 end)
 function U.coordinates(game,e)
  if e.phase=='cancelled'then return 0,0,true end
  local x,y=e.gameX,e.gameY
  if type(x)~='number'or type(y)~='number'then
   if type(e.x)~='number'or type(e.y)~='number'then return nil end
   x,y=Viewport.toLocal(e.x,e.y)
  end
  local view=latest[game]
  if game.frameFit then
   local w,h=Viewport.dimensions();local scale,ox,oy=game:frameFit(w,h)
   if not scale or scale<=0 then return nil end
   x,y=(x-ox)/scale,(y-oy)/scale
  elseif view and view.gameWidth and view.gameHeight and view.gameWidth>0 and view.gameHeight>0 then
   x,y=(x-view.gameX)*160/view.gameWidth,(y-view.gameY)*144/view.gameHeight
  else return nil end
  return x,y,x>=0 and y>=0 and x<160 and y<144
 end
 mod.hooks:wrap('input.pointer',function(next,game,e)
  local top=game and game.stack and game.stack:top()
  if top and top._bicycleUI==U and top.pointer then
   local x,y,inside=U.coordinates(game,e)
   if x and(inside or top.drag or e.phase=='released'or e.phase=='cancelled')then
    if top:pointer(e,x,y)then return true end
   end
  end
  return next(game,e)
 end)
 mod.hooks:wrap('input.key',function(next,game,e)
  local top=game and game.stack and game.stack:top()
  if top and top._bicycleUI==U and top.rawKey and e.phase=='pressed'then
   if top:rawKey(e.key)then return true end
  end
  -- Always forward key releases so a key held before editing cannot stick.
  return next(game,e)
 end)
 mod.hooks:wrap('render.zones',function(next,game,zones)
  zones=next(game,zones)
  local top=game and game.stack and game.stack:top()
  if not(top and top._bicycleUI==U)or type(zones)~='table'then return zones end
  local zone={colors=false,x=0,y=0,w=160,h=144}
  if game.frameFit then
   local w,h=Viewport.dimensions();local px,py,pw,ph=require('src.render.Playfield').rect(w,h)
   local s,ox,oy=game:frameFit(w,h)
   if pw>0 and ph>0 then zone.x=(ox-px)*160/pw;zone.y=(oy-py)*144/ph;zone.w=160*s*160/pw;zone.h=144*s*144/ph end
  end
  local out={};for i,z in ipairs(zones)do out[i]=z end;out[#out+1]=zone;return out
 end)
 return U
end
return UI
