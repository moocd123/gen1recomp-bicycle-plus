local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
local Stack=require('src.ui.game3.stack');local Menu=dofile('gen3_lab/native_menu.lua')
local draws={};local function noop()end
local G={setColor=noop,rectangle=noop,push=noop,pop=noop,transformPoint=function(x,y)return x,y end,intersectScissor=function(x,y,w,h)assert(x>=0 and x+w<=240 and y>=0 and y+h<=160)end}
local W={template=function(...)return{...}end,userFrame=function(t,f)assert(f==4)end,printPx=function(s,x,y)draws[#draws+1]={s=s,x=x,y=y}end}
local m=Menu.new({Stack=Stack,Window=W,Chrome={fixedStdFrame=noop},Font={measure=function(s)return#s*6 end,COLOR={NORMAL={}}},Options={block=function(o)return o end},graphics=G})
local n=0;local function ck(v,t)assert(v,t);n=n+1 end
local rows={};local chosen=0;for i=1,10 do rows[i]={label='ROW '..i,value=function()return'ON'end,step=function(d)chosen=chosen+d end}end
local page=m.open({options={frameType=4}},'AUTOBIKE+ LAB',rows);local input={pressed={}};function input:wasPressed(k)return self.pressed[k]==true end
local function tap(k)input.pressed={[k]=true};page.handleInput(input);input.pressed={}end
ck(Stack.top().mod==page and page._autobikeGen3Pointer,'native stack/pointer flag missing');page.draw();tap('right');ck(chosen==1,'right did not adjust')
for i=1,60 do page.update(1/60);page.handleInput(input)end;ck(chosen==1,'holding caused repeat')
page.pointer('pressed',40,58);ck(chosen==0 and page.index==1,'left-side touch did not decrement row');page.pointer('pressed',180,58);ck(chosen==1,'right-side touch did not increment row')
for i=1,9 do tap('down');page.draw()end;ck(page.index==10 and page.scroll==3,'all rows not reachable');tap('down');ck(page.index==11,'CANCEL missing');tap('a');ck(Stack.top()==nil,'CANCEL failed')
local preview={count=0};page=m.open({options={frameType=4}},'EXACT LONG TITLE FOR SCROLL TEST',rows,{preview=function(game,x,y,scale,timer)preview.count=preview.count+1;preview.x,preview.y,preview.scale,preview.timer=x,y,scale,timer end});page.update(.25);page.draw();ck(preview.count==1 and preview.x==164 and preview.y==72 and preview.scale==2 and preview.timer>0,'appearance preview callback wrong');ck(page.previewError==nil,'preview callback failed');tap('b');ck(not Stack.top(),'B back failed')
print('PASS '..n..' native Stack/menu/touch/preview assertions; fonts, graphics and windows are doubled.')
