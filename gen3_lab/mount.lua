-- Pure, non-persistent Gen 3 auto-mount state machine. No save/ROM writes.
local Mount={}
function Mount.new()
  local m={session=nil,map=nil,armed=false,wasRiding=false,reason='waiting for field'}
  function m:reset()
    self.session=nil;self.map=nil;self.armed=false;self.wasRiding=false
  end
  function m:manual(before,after)
    if before~=after then
      self.armed=false;self.wasRiding=after==true
      self.reason=after and 'manual mount' or 'manual dismount'
    end
  end
  function m:step(s,useBike)
    if not s or not s.session or not s.map or not s.field then
      self.reason='waiting for field';return false
    end
    local entered=s.session~=self.session or s.map~=self.map
    if entered then
      self.session,self.map=s.session,s.map;self.armed=true
    elseif self.wasRiding and not s.riding then
      -- Never repeatedly fight another mod/script which puts the player on foot.
      self.armed=false
    end
    self.wasRiding=s.riding==true
    if s.riding then self.armed=false;self.reason='already riding';return false end
    if not self.armed then self.reason='walking this visit';return false end
    if s.enabled==false then self.reason='disabled';return false end
    if s.safeMode then self.reason='safe mode';return false end
    if s.busy or s.moving or s.surfing or s.jumping or s.hidden or s.manualInput then
      self.reason='waiting for player control';return false
    end
    if not s.hasBike then self.reason='Bicycle not owned';return false end
    local ok,result=pcall(useBike)
    self.armed=false
    if not ok then self.reason='native Bicycle action failed';return false,result end
    if result~=true then self.reason='native cycling restriction';return false end
    self.wasRiding=true;self.reason='auto mounted';return true
  end
  return m
end
return Mount
