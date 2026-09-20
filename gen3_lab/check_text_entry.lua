local Entry=dofile('gen3_lab/text_entry.lua')
local layers={};local Stack={push=function(id,mod)layers[#layers+1]={id=id,mod=mod}end,pop=function(id)for i=#layers,1,-1 do if layers[i].id==id then table.remove(layers,i);return true end end end,top=function()return layers[#layers]end}
local function noop()end;local G={push=noop,pop=noop,setColor=noop,rectangle=noop}
local saved;local mod={exports={}}
local api=Entry.new(mod,{Stack=Stack,Window={printPx=noop,template=function(...)return{...}end,userFrame=noop},Chrome={fixedStdFrame=noop},Font={COLOR={NORMAL={}}},Options={block=function(o)return o end},graphics=G,keyboard={isDown=function()return false end},system={getClipboardText=function()return'Pasted Song' end}})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local page=api.open({options={frameType=2}},'SONG NAME','OLD NAME',24,function(name)saved=name;return true end)
ck(Stack.top().mod==page and page._autobikeGen3Pointer,'text editor did not use modal native stack')
page:rawKey('a');ck(page.buffer=='A','raw keyboard did not replace selected initial text')
page:rawKey('b');page:rawKey('space');page:rawKey('1');ck(page.buffer=='AB 1','raw keyboard entry failed')
page:rawKey('backspace');ck(page.buffer=='AB ','backspace failed')
local input={pressed={}};function input:wasPressed(k)return self.pressed[k]==true end
input.pressed={start=true};page.handleInput(input);ck(saved=='AB'and Stack.top()==nil,'START did not trim/save/close')
page=api.open({options={}},'SONG NAME','SECOND',24,function(name)saved=name;return true end)
page:pointer('pressed',15,55);ck(page.buffer=='A','touch first key did not replace initial text')
page:rawKey('escape');ck(Stack.top()==nil,'escape did not cancel')
ck(mod.exports.gen3TextEntry==api,'text editor diagnostic export missing')
print('PASS '..n..' FireRed native song-name editor keyboard/controller/touch assertions.')
