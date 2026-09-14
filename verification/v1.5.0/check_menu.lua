-- Native Screens + StateStack; input, graphics and unchanged audio/movement
-- modules are test doubles. Covers real main.lua persistence and picker input.
local engine=assert(arg[1],"engine path required")
package.path=engine.."/?.lua;"..engine.."/?/init.lua;"..package.path
local H=assert(loadfile("verification/v1.5.0/support.lua"))();H.install()
local Runtime=require("src.mods.Runtime")
local Screens=require("src.ui.Screens")
local Stack=require("src.core.StateStack")
package.loaded["src.render.PaletteFX"]={wholeNamed=function()return {}end}
local n=0
local function check(v,s)assert(v,s);n=n+1 end
local function read(path)local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s end
local noops='return {init=function()return {update=function()end,stop=function()end,open=function()end,status=function()return {}end}end}'
local previewMock=[[return {init=function()return {
 update=function()end,status=function()return 'test double' end,
 previewZones=function()return {{colors=false,x=16,y=24,w=128,h=32}}end,
 needsColourMode=function(g)return g.wantRetro==true end,
 colourModeName=function()return 'ADVANCED'end,
 enableColourMode=function(g)g.wantRetro=false;return true end,
 drawPreview=function(g,x,y,s,t,overrides)g.lastPreview=overrides;return true end,
 drawSidePreview=function(g,x,y,s,t,overrides)g.lastPreview=overrides;return true end
}end}]]
local keys={"bike_colour","bike_stripes_colour","bike_centres_colour","bike_tyres_colour","bike_frame_colour"}
for _,edition in ipairs({"red","blue","yellow","gold","silver","crystal"}) do
  Screens.invalidate();Runtime.safeMode=false
  local game={data={screens={},edition=edition},save={options={modOptions={bicycle_plus={}}}},
    mods={modOptions={bicycle_plus={}}},writes=0,input={pressed={},held={}}}
  if edition=="gold" or edition=="silver" or edition=="crystal" then game.data.gen2Sprites={}end
  function game:writeOptions()self.writes=self.writes+1 end
  function game.input:wasPressed(key)return self.pressed[key]==true end
  function game.input:isDown(key)return self.held[key]==true end
  game.stack=setmetatable({},{__index=Stack});game.stack:init()
  local save,live=game.save.options.modOptions.bicycle_plus,game.mods.modOptions.bicycle_plus
  for _,t in ipairs({save,live})do
    t._audio_layout=2;t.bike_volume=4;t.bike_filter=2;t.spelling="uk"
    t.riding_music="both";t.riding_area_volume=2;t.riding_area_filter=1
    for _,key in ipairs(keys)do t[key]="blue"end
  end
  local mod={id="bicycle_plus",exports={},hooks={},events={},options={},content={screens={}}}
  local schema={}
  function mod.options:define(rows)schema=rows end
  function mod.options:get(key)
    if live[key]~=nil then return live[key]end
    for _,row in ipairs(schema)do if row.key==key then return row.default end end
  end
  function mod.content.screens:register(id,factory)game.data.screens[id]=factory end
  function mod.hooks:wrap()end
  function mod.events:on()end
  function mod:read(path)
    if path=="audio.lua" or path=="audio_menu.lua" or path=="automount.lua" then return noops end
    if path=="colours.lua" then return previewMock end
    return read(path)
  end
  assert(loadfile("main.lua"))()(mod)
  local P=mod.exports.hardwareColours
  for _,row in ipairs(schema)do
    if row.key=="bike_colour" then
      local found=false
      for _,choice in ipairs(row.choices)do if choice[2]=="blue" then found=true end end
      check(found,"native manager can display pre-upgrade alias")
    end
  end
  local function tap(key)
    game.input.pressed={[key]=true};game.input.held={}
    game.stack:update(1/60);game.input.pressed={}
  end
  mod.exports.openSettings(game);game.stack:top():draw();tap("b")
  mod.exports.openColours(game);local parts=game.stack:top();parts:draw()
  check(game.writes==0,"opening menus does not rewrite settings")
  tap("a");local picker=game.stack:top()
  check(picker.screenId=="BicyclePlusPicker" and picker.isModOptions,"A opens native mod picker")
  check(picker.draft==P.canonical("blue"),"old preset retained")
  tap("right");picker:draw()
  check(game.writes==0 and live.bike_colour=="blue","browsing only previews")
  check(game.lastPreview.bike_colour==picker.draft,"preview receives staged part only")
  tap("b");check(game.stack:top()==parts and live.bike_colour=="blue","cancel preserves selected appearance")
  tap("a");picker=game.stack:top();tap("select")
  check(picker.mode=="rgb" and picker.focus=="grid","SELECT opens RGB555 grid")
  picker:draw();local firstImage=picker.gridImage
  tap("right");picker:draw();check(picker.gridImage==firstImage,"red movement reuses 32x32 grid")
  local r=picker.r
  game.input.pressed={right=true};game.input.held={right=true};game.stack:update(.1)
  game.input.pressed={}
  for i=1,7 do game.stack:update(.1)end
  check(picker.r~=r and picker.r~=(r+1)%32,"held D-pad repeats")
  game.input.held={};game.stack:update(.1)
  tap("select");check(picker.focus=="blue","SELECT changes blue focus")
  local oldBlue=picker.b;tap("right");picker:draw()
  check(picker.b==(oldBlue+1)%32 and picker.gridImage~=firstImage,"blue changes slice")
  for i=1,32 do tap("up");picker:draw()end
  check(picker.b==(oldBlue+1)%32,"all 32 blue slices wrap exactly")
  local picked=picker.draft;local selectedImage=picker.gridImage
  tap("a")
  check(game.stack:top()==parts,"confirm returns to component menu")
  check(game.writes==1 and save.bike_colour==picked and live.bike_colour==picked,"one commit persists both native stores")
  check(selectedImage.released,"picker texture released on exit")
  check(live.bike_volume==4 and live.bike_filter==2 and live.riding_area_volume==2,"audio preferences untouched")
  for _,key in ipairs(keys)do
    check(mod.exports.setSetting(game,key,P.id(0)),"true hardware black accepted for "..key)
    check(mod.exports.getSetting(key)==P.id(0),"black is not Original")
    check(mod.exports.setSetting(game,key,"original"),"Original remains selectable for every part")
    check(mod.exports.getSetting(key)=="original","Original round trip")
    check(not mod.exports.setSetting(game,key,"gbc:FFFF"),"out-of-range code rejected")
  end
  tap("a");picker=game.stack:top()
  check(picker.index==1 and picker.draft=="original","Original is first swatch")
  local writes=game.writes
  -- All preset labels/pages are checked against native 8px glyph bounds.
  for i,row in ipairs(picker.rows)do
    picker.index=i;picker.draft=row.id;H.resetDraws();picker:draw()
  end
  check(game.writes==writes,"drawing every swatch never saves")
  tap("start");check(game.stack:top()==parts,"START cancels directly")
  game.wantRetro=true;tap("select");check(not game.wantRetro,"explicit colour-mode shortcut retained")
  Runtime.safeMode=true
  check(not mod.exports.openColourPicker(game,"bike_colour","WHEEL"),"safe mode prevents opening editor")
  check(not mod.exports.setSetting(game,"bike_colour",P.id(1)),"safe mode protects saved preferences")
  Runtime.safeMode=false
  mod.exports.setSetting(game,"spelling","us");parts:draw()
  tap("a");game.stack:top():draw();tap("b");tap("b")
  check(game.stack:top()==nil,"clean menu stack on exit")
end
print(("PASS: %d main/menu/persistence checks across six edition contexts; native Screens/StateStack, simulated input/graphics and unchanged services."):format(n))
