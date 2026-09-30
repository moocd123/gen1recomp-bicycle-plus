-- Native GBA windows/font with the same row order, labels and controls as
-- AUTOBIKE+'s GB/GBC pages. No font assets or global font overrides bundled.
local M={}
function M.init(mod)
 local Stack=require('src.ui.game3.stack')
 local Window=require('src.ui.game3.window')
 local Font=require('src.ui.game3.frlg_font')
 local Options=require('src.core.game3.options')
 local Bus=require('src.mods.Runtime')
 local G=love.graphics
 local U={pages={},serial=0}
 local hooks,events=Bus.hooks,Bus.events
 local function safeText(s)return tostring(s or''):upper():gsub('[%c]',' '):gsub('[^A-Z0-9 :/#%.%+%-%?!]',' ')end
 function U.width(s)return Font.measure(safeText(s),{small=true})end
 function U.text(s,x,y,opts)
  opts=opts or{};opts.small=true;opts.colors=Font.COLOR.NORMAL
  G.setColor(1,1,1,1);Font.draw(safeText(s),math.floor(x),math.floor(y),opts)
 end
 function U.centre(s,y)U.text(s,(240-U.width(s))/2,y)end
 function U.clip(x,y,w,h,fn)
  G.push('all')
  local x1,y1=G.transformPoint(x,y);local x2,y2=G.transformPoint(x+w,y+h)
  G.intersectScissor(math.floor(x1),math.floor(y1),math.max(1,math.ceil(x2)-math.floor(x1)),math.max(1,math.ceil(y2)-math.floor(y1)))
  local ok,err=pcall(fn);G.pop();if not ok then error(err,0)end
 end
 function U.marquee(s,x,y,w,timer)
  s=safeText(s);local excess=math.max(0,U.width(s)-w);local offset=0
  if excess>0 then
   local travel=excess/24;local t=(timer or 0)%(2*travel+2.4)
   if t>1.2 and t<1.2+travel then offset=(t-1.2)*24
   elseif t>=1.2+travel and t<2.4+travel then offset=excess
   elseif t>=2.4+travel then offset=excess-(t-2.4-travel)*24 end
  end
  U.clip(x,y,w,14,function()U.text(s,x-math.floor(offset),y)end)
 end
 function U.background(game)
  G.setColor(0,123/255,197/255,1);G.rectangle('fill',0,0,240,160)
  local frame=Options.block(game.options or{}).frameType or 0
  G.setColor(1,1,1,1);Window.userFrame(Window.template(1,1,28,18),frame)
 end
 function U.focus(x,y,w,h)
  G.setColor(.77,.87,.98,1);G.rectangle('fill',x,y,w,h);G.setColor(1,1,1,1)
 end
 function U.marker(x,y)
  G.setColor(.25,.25,.25,1)
  for i=0,3 do G.rectangle('fill',x+i,y+i,1,7-i*2)end
  G.setColor(1,1,1,1)
 end
 function U.border(x,y,w,h)
  G.setColor(.27,.4,.52,1)
  G.rectangle('fill',x,y,w,1);G.rectangle('fill',x,y+h-1,w,1)
  G.rectangle('fill',x,y,1,h);G.rectangle('fill',x+w-1,y,1,h)
  G.setColor(1,1,1,1)
 end
 function U.button(label,r,selected)
  if selected then U.focus(r[1],r[2],r[3],r[4])else G.setColor(1,1,1,1);G.rectangle('fill',unpack(r))end
  U.border(unpack(r));U.text(label,r[1]+math.floor((r[3]-U.width(label))/2),r[2]+math.floor((r[4]-13)/2))
 end
 function U.hit(x,y,r)return x>=r[1]and x<r[1]+r[3]and y>=r[2]and y<r[2]+r[4]end
 function U.tap(s)
  for _,k in ipairs({'up','down','left','right'})do if s.game.input:wasPressed(k)then return k end end
 end
 function U.direction(s,dt)
  local key=U.tap(s)
  if key then s._repeatKey=key;s._repeatLeft=.28;return key end
  key=s._repeatKey
  if key and s.game.input:isDown(key)then
   s._repeatLeft=(s._repeatLeft or .28)-(dt or 0)
   if s._repeatLeft<=0 then s._repeatLeft=.035;return key end
  else s._repeatKey=nil end
 end
 function U.top()
  local layer=Stack.top();return layer and layer.mod and layer.mod._autobikePage or nil
 end
 function U.push(s)
  U.serial=U.serial+1;s.id=mod.id..':page:'..U.serial;s._bicycleUI=U;s.closed=false
  U.pages[s]=true
  local wrapper={_autobikePage=s,game=s.game}
  function wrapper.update(dt)
   s.timer=(s.timer or 0)+(dt or 0);s.rowTimer=(s.rowTimer or 0)+(dt or 0)
   if s.tick then s:tick(dt)end
   if s._close then U.pop(s)end
  end
  function wrapper.handleInput(input)
   if s.handleInput then s:handleInput(input,s._lastDt or 1/60)end
  end
  function wrapper.draw()G.push('all');s:draw();G.pop()end
  Stack.push(s.id,wrapper,{hideBelow=true,fullscreen=true});return s
 end
 function U.pop(s)
  s=s or U.top();if not s or s.closed then return false end
  s.closed=true;Stack.pop(s.id);U.pages[s]=nil
  if s.exit then s:exit()end;return true
 end
 function U.update(dt)
  if hooks~=Bus.hooks or events~=Bus.events then U.dispose();return end
  local missing={}
  for s in pairs(U.pages)do s._lastDt=dt;if not Stack.has(s.id)then missing[#missing+1]=s end end
  for _,s in ipairs(missing)do U.pop(s)end
 end
 function U.dispose()
  local p={};for s in pairs(U.pages)do p[#p+1]=s end;for _,s in ipairs(p)do U.pop(s)end
 end
 local function val(v,s)return type(v)=='function'and v(s)or v end
 function U.open(game,opts)
  local s={game=game,rows=opts.rows or{},index=1,scroll=0,timer=0,rowTimer=0,
   tag=opts.tag,title=opts.title,_bicycleMusic=opts.music,bicycleMusicPreview=opts.preview==true}
  function s:visible()
   self.index=math.max(1,math.min(self.index,math.max(1,#self.rows)))
   if self.index<=self.scroll then self.scroll=self.index-1 end
   if self.index>self.scroll+8 then self.scroll=self.index-8 end
  end
  function s:tick(dt)if opts.update then opts.update(self)end;self:visible()end
  function s:exit()if opts.exit then opts.exit(self)end end
  function s:activate(d)
   local r=self.rows[self.index];if not r then return end
   if d and r.step then r.step(d,self)
   elseif r.action then r.action(self)
   elseif r.step then r.step(1,self)end
  end
  function s:handleInput(input)
   if input:wasPressed('b')or input:wasPressed('start')then U.pop(self);return end
   if input:wasPressed('a')then self:activate();return end
   local before=self.index;local k=U.tap(self)
   if #self.rows>0 then
    if k=='up'then self.index=(self.index-2)%#self.rows+1
    elseif k=='down'then self.index=self.index%#self.rows+1
    elseif k=='left'or k=='right'then
     local d=k=='left'and -1 or 1;local r=self.rows[self.index]
     if r and r.step then self:activate(d)
     elseif opts.pages then self.index=math.max(1,math.min(#self.rows,self.index+d*8))end
    end
   end
   if self.index~=before then self.rowTimer=0 end;self:visible()
  end
  function s:pointer(e,x,y)
   if e.phase~='pressed'and e.phase~='moved'then return true end
   for i=1,8 do
    local index=self.scroll+i;local row=self.rows[index]
    if row and U.hit(x,y,{10,31+(i-1)*14,220,14})then
     if self.index~=index then self.rowTimer=0 end;self.index=index
     if e.phase=='pressed'then self:activate(row.step and x<190 and -1 or nil)end
     return true
    end
   end
   if e.phase=='pressed'then
    if U.hit(x,y,{186,145,50,15})then U.pop(self)
    elseif opts.pages and U.hit(x,y,{10,145,42,15})then self.index=math.max(1,self.index-8);self:visible()
    elseif opts.pages and U.hit(x,y,{56,145,42,15})then self.index=math.min(#self.rows,self.index+8);self:visible()end
   end
   return true
  end
  function s:draw()
   self:visible();U.background(game)
   U.marquee(val(opts.title,self),12,3,216,self.timer)
   U.marquee(self.notice or val(opts.subtitle,self)or'',12,17,216,self.timer)
   for i=1,8 do
    local row=self.rows[self.scroll+i]
    if row then
     local y=31+(i-1)*14;local sel=self.index==self.scroll+i
     if sel then U.focus(10,y,220,14);U.marker(13,y+4)end
     local right=val(row.value,self);local width=202
     if right~=nil then
      right=tostring(right);local x=225-U.width(right);width=math.max(8,x-27);U.text(right,x,y)
     end
     U.marquee(val(row.label,self),22,y,width,sel and self.rowTimer or 0)
    end
   end
   if opts.pages then U.text('PREV',12,145);U.text('NEXT',58,145)
   else U.text(opts.footer or'A:PICK',12,145)end
   U.text('B:BACK',190,145)
  end
  return U.push(s)
 end
 function U.confirm(game,title,detail,yes)
  return U.open(game,{title=title,subtitle=detail,rows={
   {label='CANCEL',action=function(s)U.pop(s)end},
   {label='RESET',action=function(s)if yes()~=false then U.pop(s)end end}}})
 end
 return U
end
return M
