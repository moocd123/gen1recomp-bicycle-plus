-- Native SpriteRenderer; pixel/audio/window boundaries are software doubles.
-- Optional second argument is the v1.6.0 prepare_fixtures.py Lua output.
local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
local H=dofile('verification/v1.7.0/support.lua');H.install()
local P=dofile('colour_values.lua').extend(dofile('hardware_colours.lua'))
local Parts=dofile('bike_parts.lua');local Runtime=require('src.mods.Runtime')
package.loaded['src.render.PaletteFX']={mode='redpp',honorsTrueColor=function()return true end,
 usesGbcPack=function()return true end,usesSpriteObp=function()return false end,
 darkObp=function(c,g)return c,g end,markTrueColor=H.noop,
 spriteObp=function()return{{255,255,255},{239,156,107},{58,189,25},{0,0,0}},'test'end}
package.loaded['src.render.GbcPalette']={mode='gbc',resolve=function(c)return c end}
local Sprite=require('src.render.SpriteRenderer');local baseline=Sprite.resolveImage
local rows={}
for _,kind in ipairs({'red','gen2'})do
 local d=H.data(16,96)
 for y=0,95 do for x=0,15 do d:setPixel(x,y,1,1,1,1)end end
 for f=1,6 do
  local m=Parts.masks[kind][f]
  for _,key in ipairs({'centres','tyres','frame','handlebars'})do for _,p in ipairs(m[key])do d:setPixel(p[1],p[2]+(f-1)*16,0,0,0,1)end end
  for j,p in ipairs(m.rims)do local c=kind=='gen2'and j%2==0 and 1/3 or 2/3;d:setPixel(p[1],p[2]+(f-1)*16,c,c,c,1)end
 end
 rows[#rows+1]={name=kind,kind=kind,data=d}
end
if arg[2]then
 for _,r in ipairs(assert(loadfile(arg[2]))())do
  local d=H.data(16,96)
  for y=0,95 do for x=0,15 do local i=(y*16+x)*8+1;local t=r.rgba
   d:setPixel(x,y,tonumber(t:sub(i,i+1),16)/255,tonumber(t:sub(i+2,i+3),16)/255,tonumber(t:sub(i+4,i+5),16)/255,tonumber(t:sub(i+6,i+7),16)/255)
  end end
  r.data=d;rows[#rows+1]=r
 end
end
local U=dofile('colour_ui.lua').init({hooks={wrap=H.noop}})
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local settings={};local C=dofile('colours.lua').init({hooks={wrap=H.noop}},function(k)return settings[k]end,Parts,P)
local keys={rims='bike_colour',stripes='bike_stripes_colour',centres='bike_centres_colour',tyres='bike_tyres_colour',frame='bike_frame_colour',handlebars='bike_handlebars_colour'}
for i,case in ipairs(rows)do
 local path='fixture/'..i..'/'..(case.skin and'bike.png'or case.kind=='red'and'red_bike.png'or'chris_bike.png')
 H.add(path,case.data)
 local s=Sprite.new({image=path,frames=6,walker=true,trueColor=case.trueColor,_trainerSkinId=case.skin},'player')
 local g={data={},save={onBike=true,options={}},overworld={map={id='TEST'},player={onBike=true,bikeSprite=s}}}
 C.update(g);for _,k in pairs(keys)do settings[k]='original'end;local base=s:resolveImage()
 for part,k in pairs(keys)do
  -- This accent is deliberately NOT RGB555, detecting accidental rounding.
  settings[k]='rgb:8B00BA';local changed=s:resolveImage();local count=0
  for y=0,95 do for x=0,15 do
   local r,gg,b,a=case.data:getPixel(x,y);local br,bg,bb,ba=base.data:getPixel(x,y)
   local cr,cg,cb,ca=changed.data:getPixel(x,y)
   local owner=Parts.classify(case.kind,math.floor(y/16)+1,x,y%16,r,gg,b,a,part=='stripes')
   if owner==part and ba>0.01 then
    ck(cr==139/255 and cg==0 and cb==186/255 and ca==ba,'exact colour/alpha mismatch');count=count+1
   else ck(cr==br and cg==bg and cb==bb and ca==ba,'rider/other part changed')end
  end end
  if not case.skin then ck(count>0,'no target pixels exercised')end
  settings[k]='original'
 end
 H.reset();U.preview(C,g,118,13,2,.3,{bike_handlebars_colour='rgb:010203'},'down')
 ck(#H.draws==3 and H.draws[1][2].y==48 and H.draws[1][3]==118 and H.scissor[1]==118 and H.scissor[3]==32,'cropped front-facing handlebar preview missing')
 ck(s:resolveImage()==base,'draft preview changed world')
 H.reset();U.preview(C,g,118,13,2,.3,{bike_colour='rgb:112233'},'left')
 ck(#H.draws==3 and H.draws[3][2].y==80 and H.draws[3][3]==118,'cropped side-preview adapter')
 H.reset();C.drawPreview(g,16,4,2,.3,{bike_colour='rgb:112233'});ck(#H.draws==3,'three direction menu preview')
 ck(s:resolveImage()==base,'Original texture restoration')
 g.data.gen2Sprites={};g.world={map={id='TEST'},playerState='bike',player={sprite=s}}
 C.update(g);settings.bike_colour='rgb:010203';ck(s:resolveImage()~=base,'Gen2 bicycle renderer detection');settings.bike_colour='original'
end
C.shutdown();ck(Sprite.resolveImage==baseline,'unload did not restore resolver')
print(('PASS %d native renderer/pixel/preview checks across %d software-rendered sprite cases.'):format(n,#rows))
