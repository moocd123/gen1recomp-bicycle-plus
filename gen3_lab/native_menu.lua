-- Gen 3-only menu scaffold using native ROM-derived font/window chrome.
-- Development component, not a complete mod or a replacement global font.
local Menu={}
function Menu.new(services)
 local S=services or{}
 local Stack=S.Stack or require('src.ui.game3.stack')
 local Window=S.Window or require('src.ui.game3.window')
 local Chrome=S.Chrome or require('src.ui.game3.chrome')
 local Font=S.Font or require('src.ui.game3.frlg_font')
 local Options=S.Options or require('src.core.game3.options')
 local G=S.graphics or love.graphics
 local api={serial=0}
 local function value(v)return type(v)=='function'and v()or v end
 function api.open(game,title,rows)
  assert(game and type(rows)=='table','Menu context required')
  api.serial=api.serial+1
  local id='autobike-gen3-lab-'..api.serial
  local m={index=1,scroll=0,timer=0,rows=rows}
  local function close()Stack.pop(id)end
  local function visible()
   m.index=math.max(1,math.min(m.index,#rows+1))
   if m.index<=m.scroll then m.scroll=m.index-1 end
   if m.index>m.scroll+7 then m.scroll=m.index-7 end
  end
  function m.update(dt)m.timer=m.timer+math.min(0.2,math.max(0,dt or 0));visible()end
  function m.handleInput(input)
   if input:wasPressed('b')or input:wasPressed('start')then close();return end
   local before=m.index
   if input:wasPressed('up')then m.index=(m.index-2)%(#rows+1)+1
   elseif input:wasPressed('down')then m.index=m.index%(#rows+1)+1
   else
    local row=rows[m.index]
    if input:wasPressed('a')then
     if not row then close()elseif row.activate then row.activate()elseif row.step then row.step(1)end
    elseif row and row.step then
     if input:wasPressed('left')then row.step(-1)elseif input:wasPressed('right')then row.step(1)end
    end
   end
   if before~=m.index then m.timer=0 end;visible()
  end
  local function clipText(text,x,y,width,selected)
   text=tostring(text or'')
   local excess=math.max(0,Font.measure(text)-width);local shift=0
   if selected and excess>0 then
    local travel=excess/25;local t=m.timer%(2*travel+2.4)
    if t<1.2 then shift=0 elseif t<1.2+travel then shift=(t-1.2)*25
    elseif t<2.4+travel then shift=excess else shift=excess-(t-2.4-travel)*25 end
   end
   G.push('all')
   local x1,y1=G.transformPoint(x,y);local x2,y2=G.transformPoint(x+width,y+14)
   G.intersectScissor(math.floor(x1),math.floor(y1),math.ceil(x2-x1),math.ceil(y2-y1))
   Window.printPx(text,x-math.floor(shift),y,{colors=Font.COLOR.NORMAL});G.pop()
  end
  function m.draw()
   visible();G.push('all')
   G.setColor(0,0,0,1);G.rectangle('fill',0,0,240,160)
   G.setColor(0,123/255,197/255,1);G.rectangle('fill',0,0,240,16)
   G.setColor(1,1,1,1)
   Window.printPx('A: PICK   B: BACK',8,1,{colors=Font.COLOR.NORMAL})
   Chrome.fixedStdFrame(2,3,26,2);clipText(title,24,25,192,false)
   local frame=tonumber(Options.block(game.options or{}).frameType)or 0
   Window.userFrame(Window.template(2,7,26,12),frame)
   for slot=1,7 do
    local i=m.scroll+slot
    if i<=#rows+1 then
     local row=rows[i];local y=58+(slot-1)*13;local selected=i==m.index
     local right=row and value(row.value)
     local col=right and(216-Font.measure(tostring(right)))or 216
     if right then clipText(right,col,y,216-col,selected)end
     clipText(row and value(row.label)or'CANCEL',24,y,math.max(12,col-30),selected)
    end
   end
   local top=58+(m.index-m.scroll-1)*13;local bottom=top+14
   G.setColor(0,0,0,2/16)
   if top>56 then G.rectangle('fill',16,56,208,top-56)end
   if bottom<152 then G.rectangle('fill',16,bottom,208,152-bottom)end
   G.pop()
  end
  Stack.push(id,m,{hideBelow=true});m.close=close;return m
 end
 return api
end
return Menu
