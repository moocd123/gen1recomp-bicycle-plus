-- Real OptionsMenu construction; font, GPU and settings writes are isolated.
local T=dofile('verification/v1.8.0/test_support.lua').init(assert(arg[1]))
local Runtime=T.Runtime;local Stack=require('src.core.StateStack')
local noop=function()end
love.graphics={setColor=noop,rectangle=noop,getDimensions=function()return 160,144 end}
love.keyboard={isDown=function()return false end}
package.loaded['src.render.Assets']={register=noop}
package.loaded['src.render.Font']={draw=noop,drawBox=noop,drawCode=noop}
package.loaded['src.render.PaletteFX']={mode='redpp',setMode=noop,wholeNamed=function()return{}end}
package.loaded['src.render.GbcPalette']={mode='gbc',setMode=noop}
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
for _,edition in ipairs({'red','blue','yellow','gold','silver','crystal'})do
 require('src.core.GameVersion').set(edition)
 local g={data={},mods={modOptions={bicycle_plus={}}},save={options={musicVol=7,sfxVol=7}},options={},stack=setmetatable({},{__index=Stack}),input={}}
 g.stack:init();g.options=g.save.options;function g:writeOptions()end
 function g.input:wasPressed()return false end
 local selections=0;local values={};local mod={game=g,hooks={wrap=function()return noop end},events={on=function()return noop end}}
 local A=dofile('audio_menu.lua').init(mod,{getSetting=function(k)return values[k]end,setSetting=function(_,k,v)values[k]=v end,
  openSong=function(game)ck(game==g,'wrong song game');selections=selections+1 end})
 local page=A.open(g);ck(page,'native Audio page not opened '..edition)
 local songs,cycling=0
 for _,row in ipairs(page.view)do
  if row.id=='bicycle_plus.song'then songs=songs+1;row.activate(g)end
  if row.id=='bicycle_plus.cycling'then cycling=row end
 end
 ck(songs==1 and selections==1,'native song opener missing/duplicate')
 ck(cycling,'cycling opener missing');cycling.activate(g);local riding=g.stack:top();songs=0
 for _,row in ipairs(riding.view)do
  if row.id=='bicycle_plus.song'then songs=songs+1;row.activate(g)end
 end
 ck(songs==1 and selections==2,'cycling song opener missing/duplicate')
 ck(page~=riding,'opener did not push a submenu')
 A.shutdown()
end
print(('PASS %d native Audio/Cycling page integration checks over six editions.'):format(n))
