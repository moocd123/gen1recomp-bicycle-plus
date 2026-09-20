-- Native ItemUse, Bag and player modules; fake field/modal/graphics boundaries.
local engine=assert(arg[1]);package.path=engine..'/?.lua;'..package.path
love={graphics={},filesystem={getInfo=function()return nil end,read=function()return nil end}}
local V=require('src.core.GameVersion');V.set('firered')
local P=require('src.core.game3.player');local Use=require('src.core.game3.item_use');local Bag=require('src.core.game3.bag')
local Model=dofile('gen3_lab/mount.lua');local Native=dofile('gen3_lab/native_mount.lua')
local R=require('src.mods.Runtime');R.install(require('src.mods.Events').new(),require('src.mods.Hooks').new())
local session={map='FR_ROUTE_1',bag=Bag.new()}
local game={phase='field',session=session,input={wasPressed=function()return false end},data={maps={
 FR_ROUTE_1={pair='outdoor'},FR_ROUTE_2={pair='outdoor'},FR_POKECENTER={pair='indoor'}}}}
package.loaded['src.core.game3.runtime']={_game=game,uiBusy=function()return false end,getSession=function()return session end}
package.loaded['src.core.game3.field']={running=true,locked=false}
package.loaded['src.core.game3.scripting.space']={}
package.loaded['src.core.game3.battle']={isActive=function()return false end}
package.loaded['src.core.game3.warp']={isBusy=function()return false end}
package.loaded['src.render.Assets']={register=function()end}
P.reset(1,1,'down')
local baseUse,baseUpdate=Use.useBike,P.update
local api=Native.attach({id='autobike_gen3_lab'},Model,function()return true end)
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
ck(not api.update(game)and not P.biking,'missing bicycle mounted')
assert(Bag.add(session.bag,360,1))
ck(api.update(game)and P.biking,'native bicycle was not mounted')
ck(Use.useBike(session)==true and not P.biking,'native manual dismount failed')
for i=1,50 do ck(not api.update(game)and not P.biking,'manual dismount overridden')end
session.map='FR_ROUTE_2';ck(api.update(game)and P.biking,'new route did not mount')
Use.useBike(session);session.map='FR_POKECENTER';ck(not api.update(game)and not P.biking,'native indoor restriction bypassed')
ck(Bag.has(session.bag,360,1)==true,'bicycle inventory altered')
api.dispose();ck(Use.useBike==baseUse and P.update==baseUpdate,'wrappers not restored')
print('PASS '..n..' native FireRed Bag/ItemUse adapter checks. This is not full gameplay.')
