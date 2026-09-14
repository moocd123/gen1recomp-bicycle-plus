-- Real source sprites, native SpriteRenderer; software graphics boundaries.
local engine=assert(arg[1]);package.path=engine..'/?.lua;'..engine..'/?/init.lua;'..package.path
local H=dofile('verification/v1.6.0/support.lua');H.install()
local P=dofile('hardware_colours.lua');local Parts=dofile('bike_parts.lua')
local Runtime=require('src.mods.Runtime')
local PF={mode='redpp',honorsTrueColor=function()return true end,usesGbcPack=function()return true end,
 usesSpriteObp=function()return false end,darkObp=function(c,g)return c,g end,markTrueColor=H.noop,
 spriteObp=function()return {{255,255,255},{239,156,107},{58,189,25},{0,0,0}},'test'end}
package.loaded['src.render.PaletteFX']=PF
package.loaded['src.render.GbcPalette']={mode='gbc',resolve=function(c)return c end}
local Sprite=require('src.render.SpriteRenderer')
local cases=assert(loadfile(assert(arg[2])))();assert(#cases>=29,'actual native and trainer fixtures required')
local keys={rims='bike_colour',stripes='bike_stripes_colour',centres='bike_centres_colour',tyres='bike_tyres_colour',frame='bike_frame_colour',handlebars='bike_handlebars_colour'}
local settings={};local n=0
local function check(v,s)assert(v,s);n=n+1 end
local function equal(a,b,x,y)
 local r,g,bb,aa=a:getPixel(x,y);local r2,g2,b2,a2=b:getPixel(x,y)
 return math.abs(r-r2)<1e-9 and math.abs(g-g2)<1e-9 and math.abs(bb-b2)<1e-9 and aa==a2
end
local baseline=Sprite.resolveImage
local C=dofile('colours.lua').init({hooks={wrap=function()end}},function(k)return settings[k]end,Parts,P)
for _,case in ipairs(cases)do
 local d=H.data(16,96);local t=case.rgba
 for y=0,95 do for x=0,15 do
  local i=(y*16+x)*8+1
  d:setPixel(x,y,tonumber(t:sub(i,i+1),16)/255,tonumber(t:sub(i+2,i+3),16)/255,tonumber(t:sub(i+4,i+5),16)/255,tonumber(t:sub(i+6,i+7),16)/255)
 end end
 local image=case.skin and case.name..'/bike.png' or 'native/'..case.name..'_bike.png'
 H.add(image,d)
 local sprite=Sprite.new({image=image,frames=6,walker=true,trueColor=case.trueColor,_trainerSkinId=case.skin},'player')
 local game={data={},save={onBike=true,options={}},overworld={map={},player={bikeSprite=sprite,onBike=true}}}
 local base=baseline(sprite);C.update(game)
 for _,key in pairs(keys)do settings[key]='original'end
 check(Sprite.resolveImage(sprite)==base,'Original preserves native image identity')
 check(C.artStyle(game)==(case.kind=='red'and'GEN 1'or'GEN 2'),'artwork-based family')
 -- Independent geometry specification, not constructed from production masks.
 for f=1,6 do
  local down=f==1 or f==4;local side=f==3 or f==6
  local dx=case.kind=='red' and f>3 and -1 or 0
  local barY=case.kind=='red'and 9 or 10;local sideX=case.kind=='red'and 3 or 2
  for y=0,15 do for x=0,15 do
   local r,g,b,a=d:getPixel(x,y+16*(f-1));local part=Parts.classify(case.kind,f,x,y,r,g,b,a,true)
   local bar=(down and(y==barY or y==barY+1)and x>=4+dx and x<=11+dx)
      or(side and y==10 and(x==sideX+dx or x==sideX+dx+1))
   local exposed=bar and math.max(r,g,b)<=.06 and a>.01
   check((part=='handlebars')==exposed,'bar geometry/foreground protection '..case.name)
   if (not down or y<barY)and y<10 then check(part==nil,'head/face/back untouched')end
   if side and x>=sideX+dx+2 and x<=sideX+dx+3 and(y==10 or y==11)then check(part==nil,'side hand untouched')end
   if down and(y==barY or y==barY+1)and(x==2+dx or x==3+dx or x==12+dx or x==13+dx)then check(part==nil,'front hands untouched')end
   if side and((x==9+dx and y==12)or(f==6 and x==10+dx and y==14))then check(part==nil,'shared shoe border untouched')end
   if part=='frame'then check(side and x==sideX+dx+1 and y==11,'small stem detail only')end
  end end
 end
 for part,key in pairs(keys)do
  settings[key]=P.id(P.pack(31,0,31));local painted=Sprite.resolveImage(sprite);local changed=0
  for y=0,95 do for x=0,15 do
   local r,g,b,a=d:getPixel(x,y)
   local owner=Parts.classify(case.kind,math.floor(y/16)+1,x,y%16,r,g,b,a,part=='stripes')
   if owner==part then
    local _,_,_,alpha=base.data:getPixel(x,y)
    if alpha>.01 then
     local rr,gg,bb,aa=painted.data:getPixel(x,y)
     check(rr==1 and gg==0 and bb==1 and aa==alpha,'exact chosen RGB555 and source alpha');changed=changed+1
    end
   else check(equal(base.data,painted.data,x,y),'all non-selected pixels preserved')end
  end end
  if part=='handlebars'then
   check(changed==((case.skin=='Dawn'or case.skin=='Hilda')and 32 or 36),'coloured clothing occludes four bar pixels on Dawn/Hilda')
  end
  if part=='frame'then check(changed==2,'one retained stem-detail pixel per side pose')end
  settings[key]='original'
 end
 H.clear();C.drawPreview(game,16,24,2,.3,{bike_handlebars_colour=P.id(31)})
 check(#H.draws==3 and settings.bike_handlebars_colour=='original','preview does not commit')
 check(Sprite.resolveImage(sprite)==base,'all Original restores exact texture')
 game.data.gen2Sprites={};game.world={map={},playerState='bike',player={sprite=sprite}}
 C.update(game);settings.bike_handlebars_colour=P.id(31)
 check(Sprite.resolveImage(sprite)~=base,'Gen2 world also recolours the bike')
 game.world.playerState='walk';check(Sprite.resolveImage(sprite)==base,'walking sprite unchanged')
end
C.shutdown();check(Sprite.resolveImage==baseline,'renderer chain restored')
local accents=arg[2]:gsub('[^/]+$','trainer_accents.lua');local refs=assert(loadfile(accents))();local _,byId=P.presets({data={}})
check(#refs==10,'actual uploaded Trainer Skins has ten named palettes')
for _,ref in ipairs(refs)do
 local row=byId[P.fromRGB(table.unpack(ref[2]))]
 check(row and row.section=='trainer' and row.label=='TRAINER '..(ref[1]=='GRAY'and'GREY'or ref[1]),'all actual companion palette references match')
end
print(('PASS: %d source-pixel/renderer checks across %d source/quantised cases; ten actual Trainer palettes; no physical-device claim.'):format(n,#cases))
