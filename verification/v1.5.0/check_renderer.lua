-- Native SpriteRenderer with software pixel/graphics boundaries. No GPU test.
-- Optional second argument: LOCAL fixture Lua made from separately supplied art.
local engine=assert(arg[1],"engine path required")
package.path=engine.."/?.lua;"..engine.."/?/init.lua;"..package.path
local H=assert(loadfile("verification/v1.5.0/support.lua"))();H.install()
local P=assert(loadfile("hardware_colours.lua"))()
local Parts=assert(loadfile("bike_parts.lua"))()
local Runtime=require("src.mods.Runtime")
local PF={mode="redpp",honorsTrueColor=function()return true end,
  usesGbcPack=function()return true end,usesSpriteObp=function()return false end,
  darkObp=function(colors,group)return colors,group end,markTrueColor=H.noop,
  spriteObp=function()return {{255,255,255},{239,156,107},{58,189,25},{0,0,0}},"test"end}
package.loaded["src.render.PaletteFX"]=PF
package.loaded["src.render.GbcPalette"]={mode="gbc",resolve=function(c)return c end}
local Sprite=require("src.render.SpriteRenderer")
local cases={}
for _,kind in ipairs({"red","gen2"}) do
  local d=H.data(16,96)
  for y=0,95 do for x=0,15 do
    -- Non-bike fixture pixels exercise the preserved rider/transparent region.
    local shade=(x+y)%4/3;d:setPixel(x,y,shade,shade,shade,(x+y)%13==0 and 0 or 1)
  end end
  for frame=1,6 do
    local mask=Parts.masks[kind][frame]
    for j,p in ipairs(mask.rims) do local v=kind=="gen2" and j%2==0 and 1/3 or 2/3;d:setPixel(p[1],p[2]+(frame-1)*16,v,v,v,1)end
    for _,part in ipairs({"centres","tyres","frame"}) do
      for _,p in ipairs(mask[part]) do d:setPixel(p[1],p[2]+(frame-1)*16,0,0,0,1)end
    end
  end
  cases[#cases+1]={name=kind,image=kind=="red" and "sprites/red_bike.png" or "sprites/chris_bike.png",data=d,kind=kind}
end
if arg[2] then
  for _,f in ipairs(assert(loadfile(arg[2]))()) do
    local d=H.data(f.w,f.h)
    for y=0,f.h-1 do for x=0,f.w-1 do
      local i=(y*f.w+x)*8+1;local t=f.rgba
      d:setPixel(x,y,tonumber(t:sub(i,i+1),16)/255,tonumber(t:sub(i+2,i+3),16)/255,
        tonumber(t:sub(i+4,i+5),16)/255,tonumber(t:sub(i+6,i+7),16)/255)
    end end
    cases[#cases+1]={name=f.name,image=f.name.."/bike.png",data=d,kind="gen2",skin=f.skin,trueColor=f.trueColor}
  end
end
local settings={}
local map={rims="bike_colour",stripes="bike_stripes_colour",centres="bike_centres_colour",tyres="bike_tyres_colour",frame="bike_frame_colour"}
local n=0
local function check(v,s)assert(v,s);n=n+1 end
local function equal(a,b,x,y)
  local ar,ag,ab,aa=a:getPixel(x,y);local br,bg,bb,ba=b:getPixel(x,y)
  return math.abs(ar-br)<1e-9 and math.abs(ag-bg)<1e-9 and math.abs(ab-bb)<1e-9 and math.abs(aa-ba)<1e-9
end
local hooks={}
local mod={hooks={wrap=function(_,name,fn)hooks[name]=fn end}}
local baselineResolve=Sprite.resolveImage
local C=assert(loadfile("colours.lua"))().init(mod,function(k)return settings[k]end,Parts,P)
for _,case in ipairs(cases) do
  H.add(case.image,case.data)
  local def={image=case.image,frames=6,walker=true,trueColor=case.trueColor,_trainerSkinId=case.skin}
  local sprite=Sprite.new(def,"player")
  local game={data={},save={onBike=true,options={}},overworld={map={id="TEST"},player={bikeSprite=sprite,onBike=true}}}
  local base=baselineResolve(sprite)
  C.update(game)
  for _,key in pairs(map)do settings[key]="original"end
  check(Sprite.resolveImage(sprite)==base,"all Original returns the original image object")
  for part,key in pairs(map) do
    settings[key]=P.id(P.pack(31,0,31))
    local painted=Sprite.resolveImage(sprite)
    local changed=0
    for y=0,95 do for x=0,15 do
      local r,g,b,a=case.data:getPixel(x,y)
      local belongs=Parts.classify(case.kind,math.floor(y/16)%6+1,x,y%16,r,g,b,a,part=="stripes")
      if belongs==part then
        local _,_,_,alpha=base.data:getPixel(x,y)
        if alpha>0.01 then
          local rr,gg,bb,aa=painted.data:getPixel(x,y)
          check(rr==1 and gg==0 and bb==1 and aa==alpha,"target gets exact selected RGB555")
          changed=changed+1
        end
      else check(equal(base.data,painted.data,x,y),"rider, other parts and alpha unchanged") end
    end end
    -- Some actual skins intentionally occlude a component; don't invent pixels.
    if not case.skin then check(changed>0,"synthetic mask part exercised: "..case.name.."/"..part)end
    settings[key]="original"
  end
  -- A staged preview affects only its local render; no options are written.
  settings.bike_colour="green"
  local saved=Sprite.resolveImage(sprite)
  H.resetDraws()
  C.drawSidePreview(game,112,80,2,0.3,{bike_colour=P.id(31)})
  check(#H.draws==1,"single side preview")
  check(settings.bike_colour=="green","preview does not mutate saved colour")
  check(Sprite.resolveImage(sprite)==saved,"world colour unchanged by preview")
  H.resetDraws()
  C.drawPreview(game,16,24,2,0.3,{bike_colour=P.id(31)})
  check(#H.draws==3,"three-direction preview retained")
  for _,key in pairs(map)do settings[key]="original"end
  check(Sprite.resolveImage(sprite)==base,"return to Original restores exact texture")
  -- Exercise GBC render path as well as Gen 1 using the same native renderer.
  game.data.gen2Sprites={};game.world={map={id="TEST"},playerState="bike",player={sprite=sprite}}
  C.update(game);settings.bike_colour=P.id(32767)
  check(Sprite.resolveImage(sprite)~=base,"Gen2 world identifies the bicycle")
end
C.shutdown();check(Sprite.resolveImage==baselineResolve,"resolver chain restored on shutdown")
print(("PASS: %d pixel/renderer checks over %d source-sheet cases with the native SpriteRenderer and software graphics boundaries."):format(n,#cases))
