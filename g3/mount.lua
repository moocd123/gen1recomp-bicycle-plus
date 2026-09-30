-- Pure, non-persistent Gen 3 auto-mount state machine. No save/ROM writes.
local Mount={}
function Mount.new()
  local m={session=nil,map=nil,armed=false,wasRiding=false,wasSurfing=false,
    returnFromSurf=false,dismountCandidate=false,suppressed=false,reason='waiting for field'}
  function m:reset()
    self.session=nil;self.map=nil;self.armed=false;self.wasRiding=false;self.lastEnabled=nil
    self.wasSurfing=false;self.returnFromSurf=false;self.dismountCandidate=false;self.suppressed=false
  end
  function m:manual(before,after)
    if before~=after then
      self.armed=false;self.wasRiding=after==true;self.suppressed=after~=true
      self.returnFromSurf=false;self.dismountCandidate=false
      self.reason=after and 'manual mount' or 'manual dismount'
    end
  end
  function m:step(s,useBike)
    if not s or not s.session or not s.map or not s.field then
      self.reason='waiting for field';return false
    end
    local enabled=s.enabled~=false
    local entered=s.session~=self.session or s.map~=self.map or(self.lastEnabled==false and enabled)
    self.lastEnabled=enabled
    if entered then
      self.session,self.map=s.session,s.map;self.armed=true
      self.wasRiding=false;self.wasSurfing=false;self.returnFromSurf=false
      self.dismountCandidate=false;self.suppressed=false
    end
    if not enabled then
      self.armed=false;self.returnFromSurf=false;self.dismountCandidate=false
      self.wasRiding=s.riding==true;self.wasSurfing=s.surfing==true
      self.reason='disabled';return false
    end
    if s.surfing then
      if not self.wasSurfing and not self.suppressed
          and (self.wasRiding or self.dismountCandidate) then self.returnFromSurf=true end
      if self.returnFromSurf then self.armed=true end
      self.wasSurfing=true;self.wasRiding=false;self.dismountCandidate=false
      self.reason='surfing';return false
    end
    if self.wasSurfing then
      self.wasSurfing=false
      if self.returnFromSurf then self.armed=true;self.suppressed=false end
      self.returnFromSurf=false
    end
    local busy=s.busy or s.moving or s.jumping or s.hidden or s.manualInput
    if s.riding then
      self.armed=false;self.wasRiding=true;self.dismountCandidate=false;self.suppressed=false
      self.reason='already riding';return false
    elseif self.wasRiding then
      if busy then self.dismountCandidate=true
      else self.armed=false;self.suppressed=true end
    elseif self.dismountCandidate and not busy then
      self.dismountCandidate=false;self.armed=false;self.suppressed=true
    end
    self.wasRiding=false
    if self.dismountCandidate or self.suppressed then self.reason='walking this visit';return false end
    if not self.armed then self.reason='walking this visit';return false end
    if s.enabled==false then self.reason='disabled';return false end
    if s.safeMode then self.reason='safe mode';return false end
    if s.busy or s.moving or s.surfing or s.jumping or s.hidden or s.manualInput then
      self.reason='waiting for player control';return false
    end
    if not s.hasBike then self.armed=false;self.reason='Bicycle not owned';return false end
    local ok,result=pcall(useBike)
    self.armed=false
    if not ok then self.reason='native Bicycle action failed';return false,result end
    if result~=true then self.reason='native cycling restriction';return false end
    self.wasRiding=true;self.reason='auto mounted';return true
  end
  return m
end
return Mount
