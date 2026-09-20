-- Development adapter for Gen1ReComp++ v0.2.66 FireRed. Not a complete mod.
local Native={}
function Native.attach(mod,Machine,getSetting)
  local Version=require('src.core.GameVersion')
  assert(Version.get()=='firered' and Version.generation()==3,'FireRed adapter only')
  local P=require('src.core.game3.player')
  local ItemUse=require('src.core.game3.item_use')
  local Bag=require('src.core.game3.bag')
  local Compat=require('src.mods.Gen3Compat')
  local Bus=require('src.mods.Runtime')
  local ownerHooks,ownerEvents=Bus.hooks,Bus.events
  local m=Machine.new();local api={state=m};local autoCall=false;local disposed=false
  local priorUse,priorUpdate=ItemUse.useBike,P.update
  local wrappedUse,wrappedUpdate
  local function active()
    return not disposed and not Bus.safeMode and Version.get()=='firered'
      and Bus.hooks==ownerHooks and Bus.events==ownerEvents
  end
  wrappedUse=function(session,...)
    local before=P.biking==true
    local a,b,c=priorUse(session,...)
    if active() and not autoCall then m:manual(before,P.biking==true)end
    return a,b,c
  end
  function api.update(game)
    if not active() then return false end
    local session=game and game.session
    local input=game and game.input
    local busy=Compat.worldBusy()
    local manual=false
    if input and input.wasPressed then
      for _,k in ipairs({'a','b','select','start'})do
        if input:wasPressed(k)then manual=true end
      end
    end
    local owned=false
    if session and session.bag then
      local ok,v=pcall(Bag.has,session.bag,360,1);owned=ok and v==true
    end
    local state={session=session,map=session and session.map,field=game and game.phase=='field',
      enabled=getSetting('auto_mount')~=false,safeMode=Bus.safeMode,
      riding=P.biking==true,busy=busy,moving=P.moving,surfing=P.surfing,
      jumping=P.jumping or P.surfHopping or P.dismounting or (P.fieldMoveAnim or 0)>0,
      hidden=P.isVisible and not P.isVisible(),hasBike=owned,manualInput=manual}
    return m:step(state,function()
      autoCall=true
      local ok,result=pcall(wrappedUse,session)
      autoCall=false
      if not ok then error(result,0)end
      return result==true and P.biking==true
    end)
  end
  wrappedUpdate=function(game,...)
    if active() then api.update(game)end
    return priorUpdate(game,...)
  end
  ItemUse.useBike=wrappedUse;P.update=wrappedUpdate
  function api.dispose()
    if disposed then return end;disposed=true
    if ItemUse.useBike==wrappedUse then ItemUse.useBike=priorUse end
    if P.update==wrappedUpdate then P.update=priorUpdate end
    m:reset()
  end
  require('src.render.Assets').register({release=api.dispose})
  return api
end
return Native
