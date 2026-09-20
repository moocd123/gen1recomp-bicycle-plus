local Picker=dofile('gen3_lab/colour_picker.lua')
local layers={};local Stack={}
function Stack.push(id,mod)layers[#layers+1]={id=id,mod=mod}end
function Stack.pop(id)for i=#layers,1,-1 do if not id or layers[i].id==id then table.remove(layers,i);return true end end end
function Stack.top()return layers[#layers]end
local noop=function()end
local G={push=noop,pop=noop,setColor=noop,rectangle=noop}
local W={template=function(...)return{...}end,userFrame=noop,printPx=noop}
local hooks={};local mod={hooks={wrap=function(_,name,fn)hooks[name]=fn end}}
local values={bike_frame_colour='original'};local remembered='#336699';local writes={}
local settings={get=function(k)return values[k]end,set=function(_,k,v)values[k]=v;writes[#writes+1]={k,v};return true end,
 getRememberedColour=function()return remembered end,rememberColour=function(_,k,v)remembered=v;return true end}
local p=Picker.new(mod,settings,{Stack=Stack,Window=W,Chrome={fixedStdFrame=noop},
 Font={measure=function(s)return#s*6 end,COLOR={NORMAL={}}},Options={block=function(o)return o end},graphics=G,
 keyboard={isDown=function()return false end},system={getClipboardText=function()return'112233'end}})
local game={options={frameType=0}};local page=p.open(game,'bike_frame_colour','FRAME')
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
ck(Stack.top().mod==page and page._autobikeGen3Picker,'picker did not use native Gen3 stack')
ck(page.r==0x33 and page.g==0x66 and page.b==0x99 and page.originalDraft,'remembered custom colour not restored behind Original')
local input={pressed={},down={}}
function input:wasPressed(k)return self.pressed[k]==true end
function input:isDown(k)return self.down[k]==true end
local function tap(k)input.pressed={[k]=true};page.handleInput(input);input.pressed={}end
-- Continuous colour adjustment is deliberate: edge first, then held repeat.
local before=page.h;input.down.right=true;tap('right');for i=1,20 do page.update(.02)end;input.down.right=false;page.update(.02)
ck(page.h~=before and not page.originalDraft,'HSV adjustment did not clear Original/use held repeat')
-- Select through to HEX, open editor, raw keyboard entry, commit and apply.
for i=1,5 do tap('select')end
ck(page.focus=='hex','Select focus order did not reach HEX')
tap('a');ck(page.edit and page.edit.field=='hex','HEX keypad/editor not opened')
page.rawKey('delete');for _,ch in ipairs({'a','1','b','2','c','3'})do page.rawKey(ch)end
ck(page.commitEdit() and page.r==0xA1 and page.g==0xB2 and page.b==0xC3,'raw RGB/hex keyboard editing failed')
page.focus='apply';tap('a');ck(values.bike_frame_colour=='#a1b2c3'and remembered=='#a1b2c3','Apply did not persist exact custom and remembered value')
ck(Stack.top()==nil,'Apply did not close picker')
-- Reopen, choose Original, ensure remembered custom survives.
page=p.open(game,'bike_frame_colour','FRAME');page.focus='original';tap('a');page.focus='apply';tap('a')
ck(values.bike_frame_colour=='original'and remembered=='#a1b2c3','Original should not erase remembered custom')
-- Keyboard hook consumes editing keys only while the picker is active.
page=p.open(game,'bike_frame_colour','FRAME');page.beginEdit('hex');local chained=false
local result=hooks['input.key'](function()chained=true end,game,{phase='pressed',key='1'})
ck(result==true and not chained,'raw input.key edit was not isolated from game hotkeys')
page.close()
print('PASS '..n..' native Gen3 colour-picker state/input assertions.')
