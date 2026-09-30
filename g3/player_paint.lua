-- Player-only FireRed bicycle paint renderer. It draws a private recoloured
-- copy for the local rider and never mutates OwSprites' shared source image,
-- so NPCs and vanilla assets retain their original palette.
local Paint={}
function Paint.attach(mod,Parts,Shade,settings,S)
 S=S or{}
 local Ow=S.OwSprites or require('src.core.game3.ow_sprites')
 local P=S.Player or require('src.core.game3.player')
 local Runtime=S.Runtime or require('src.mods.Runtime')
 local GameRuntime=S.GameRuntime or require('src.core.game3.runtime')
 local Assets=S.Assets or require('src.render.Assets')
 local L=S.Love or love
 local G=assert(L and L.graphics,'graphics unavailable')
 local I=assert(L and L.image,'image service unavailable')
 local priorDraw=assert(Ow.draw,'OwSprites.draw unavailable')
 local wrappedDraw,disposed
 local hooks,events=Runtime.hooks,Runtime.events
 local cache={}
 local lastError,lastCount
 local KEYS={frame='bike_colour',rims='bike_colour',tyres='bike_tyres_colour',
  spokes='bike_stripes_colour',centres='bike_centres_colour',handlebars='bike_handlebars_colour'}
 local PREVIEW={
  {0,'down'},{3,'down'},{4,'down'},
  {2,'left'},{7,'left'},{8,'left'},
  {2,'right'},{7,'right'},{8,'right'},
  {1,'up'},{5,'up'},{6,'up'},
 }
 local function currentGame()
  return (GameRuntime and(GameRuntime._game or(GameRuntime.getGame and GameRuntime.getGame())))or mod.game
 end
 local function active()
  return not disposed and not Runtime.safeMode and Runtime.hooks==hooks and Runtime.events==events
 end
 local function close(a,b)return math.abs((tonumber(a)or 0)-(tonumber(b)or 0))<0.01 end
 local function isPlayerCall(gid,px,py,facing)
  if not active()or P.biking~=true then return false end
  local game=currentGame();if not game then return false end
  local want=Ow.playerGraphicsId and Ow.playerGraphicsId(game)
  if tonumber(gid)~=tonumber(want)then return false end
  local ox=P.spriteXOffset or 0;local oy=P.spriteYOffset or 0
  if oy==0 and P.jumpSpriteY then oy=P.jumpSpriteY()or 0 end
  return close(px,(P.px or 0)+ox)and close(py,(P.py or 0)+oy)
   and tostring(facing or'down')==tostring(P.facing or'down')
 end
 local function bikeGraphicsId(game)
  local session=game and game.session;local save=game and game.save
  local gender=(session and session.gender)or(save and(save.gender or(save.player and save.player.gender)))
  local female=gender=='female'or gender=='F'or gender==1
  return female and(tonumber(S.femaleBikeId)or 8)or(tonumber(S.maleBikeId)or 1)
 end
 local function rgb(v)
  if v=='original'or type(v)~='string'then return v end
  if settings.rgb then return settings.rgb(v)end
  local h=v:gsub('^rgb:',''):gsub('^#','');if not h:match('^%x%x%x%x%x%x$')then return nil end
  return{tonumber(h:sub(1,2),16),tonumber(h:sub(3,4),16),tonumber(h:sub(5,6),16)}
 end
 local function paints(game,overrides)
  local out,custom={},false;local sig={}
  for part,key in pairs(KEYS)do
   local value=overrides and overrides[key] or settings.get(key,game)or'original';sig[#sig+1]=part..'='..tostring(value)
   local c=rgb(value);if c==nil then return nil,nil,'invalid '..key end
   out[part]=c;if c~='original'then custom=true end
  end
  table.sort(sig)
  return out,custom,table.concat(sig,';')
 end
 local function sha256(bytes)
  if S.sha256 then return S.sha256(bytes)end
  local D=L and L.data;if not(D and D.hash)then return nil end
  local ok,digest=pcall(D.hash,'sha256',bytes);if not ok or not digest then return nil end
  if type(digest)~='string'and digest.getString then digest=digest:getString()end
  if type(digest)~='string'then return nil end
  if #digest==64 and digest:match('^%x+$')then return digest:lower()end
  if D.encode then
   local ok2,hex=pcall(D.encode,'string','hex',digest)
   if ok2 and type(hex)=='string'then return hex:lower()end
  end
  return nil
 end
 local function sourceBytes(spr)
  if spr and spr.imageData and spr.imageData.getString then return spr.imageData:getString() end
  return nil,'Native sprite ImageData unavailable'
 end
 local function releaseEntry(e)
  if e and e.image and e.image.release then pcall(e.image.release,e.image)end
 end
 local function build(gid,spr,game,signature,palette)
  local bytes,err=sourceBytes(spr);if not bytes then return nil,err end
  local digest=sha256(bytes);if not digest then return nil,'SHA-256 unavailable'end
  if not Parts.verify(bytes,tonumber(gid),function()return digest end)then
   return nil,'unknown FireRed bicycle artwork'
  end
  local painted,count=Shade.paint(bytes,spr.width,spr.height*spr.frameCount,Parts.sheet,palette)
  local ok,data=pcall(I.newImageData,spr.width,spr.height*spr.frameCount,'rgba8',painted)
  if not ok or not data then return nil,'could not create painted pixels'end
  local ok2,image=pcall(G.newImage,data)
  if data.release then pcall(data.release,data)end
  if not ok2 or not image then return nil,'could not create painted texture'end
  if image.setFilter then pcall(image.setFilter,image,'nearest','nearest')end
  lastCount=count
  return{source=spr.image,signature=signature,image=image,count=count}
 end
 local function painted(gid,spr,game,overrides)
  local palette,custom,signature=paints(game,overrides)
  if not palette then lastError=signature;return nil end
  if not custom then return false end -- exact vanilla path for Original
  local cacheKey=tostring(gid)..(overrides and ':preview' or ':world')
  local e=cache[cacheKey]
  if e and e.source==spr.image and e.signature==signature then return e.image end
  releaseEntry(e);cache[cacheKey]=nil
  local made,err=build(gid,spr,game,signature,palette)
  if not made then lastError=err;return nil end
  cache[cacheKey]=made;lastError=nil;return made.image
 end
 wrappedDraw=function(gid,px,py,camX,camY,facing,walkPhase,stepFlip,opts)
  if not isPlayerCall(gid,px,py,facing)then return priorDraw(gid,px,py,camX,camY,facing,walkPhase,stepFlip,opts)end
  local spr=(Ow.getDraw or Ow.get)(gid);if not spr then return priorDraw(gid,px,py,camX,camY,facing,walkPhase,stepFlip,opts)end
  local image=painted(gid,spr,currentGame())
  if image==false or image==nil then return priorDraw(gid,px,py,camX,camY,facing,walkPhase,stepFlip,opts)end
  local frame,flip=Ow.pose(spr,facing,walkPhase,stepFlip,opts);local q=spr.quads[frame]
  if not q then return priorDraw(gid,px,py,camX,camY,facing,walkPhase,stepFlip,opts)end
  local sx=px-camX+(16-spr.width)/2;local sy=py-camY+16-spr.height
  G.setColor(1,1,1,1)
  if flip then G.draw(image,q,sx+spr.width,sy,0,-1,1)else G.draw(image,q,sx,sy)end
  return true
 end
 Ow.draw=wrappedDraw
 local api={}
 function api.invalidate()for k,e in pairs(cache)do releaseEntry(e);cache[k]=nil end;lastError=nil end
 function api.status()return{active=active(),error=lastError,paintedPixels=lastCount}end
 function api.drawPreview(game,x,y,scale,timer,overrides,facing)
  if not active()then return false end
  game=game or currentGame();if not game then return false end
  local gid=bikeGraphicsId(game);local spr=(Ow.getDraw or Ow.get)(gid);if not spr then return false end
  local image=painted(gid,spr,game,overrides);if image==false or image==nil then image=spr.image end
  if not image then return false end
  scale=math.max(1,math.floor(tonumber(scale)or 1));x=tonumber(x)or 0;y=tonumber(y)or 0
  local at=math.floor(math.max(0,tonumber(timer)or 0)*6)%#PREVIEW+1
  local pose=PREVIEW[at];
  if facing then
   local steps={down={0,3,4},up={1,5,6},left={2,7,8},right={2,7,8}}
   pose={steps[facing][math.floor((timer or 0)*6)%3+1],facing}
  end
 local frame,flip=Ow.pose(spr,pose[2],false,false,{frame=pose[1]})
  local q=spr.quads[frame];if not q then return false end
  G.setColor(1,1,1,1)
  if flip then G.draw(image,q,x+spr.width*scale,y,0,-scale,scale)
  else G.draw(image,q,x,y,0,scale,scale)end
  return true
 end
 function api.dispose()
  if disposed then return end;disposed=true;api.invalidate()
  if Ow.draw==wrappedDraw then Ow.draw=priorDraw end
 end
 if Assets and Assets.register then Assets.register({release=api.dispose})end
 function api.drawTriple(game,x,y,scale,timer,overrides)
  for i,facing in ipairs({'down','up','left'})do api.drawPreview(game,x+(i-1)*72,y,scale,timer,overrides,facing)end
 end
 api.keys=KEYS
 return api
end
return Paint
