-- Shared AUTOBIKE+ pages. Each row is one clipped, horizontally scrolling line.
-- D-pad navigation uses press edges only; holding a button cannot skip options.
local Menu={}
function Menu.init(mod,U)
  local Screens=require('src.ui.Screens')
  local api={}
  local function value(v,s)return type(v)=='function' and v(s) or v end
  local factory={new=function(game,opts)
    local s={game=game,isOpaque=true,isModOptions=true,_bicycleUI=U,index=1,scroll=0,
      timer=0,rowTimer=0,lastIndex=1,rows=opts.rows or {},_bicycleMusic=opts.music,
      bicycleMusicPreview=opts.preview==true,tag=opts.tag,title=opts.title}
    function s:sgbPalettes()return U.zones()end
    function s:exit()if opts.exit then opts.exit(self)end end
    function s:activate()
      local row=self.rows[self.index]
      if not row then return end
      if row.action then row.action(self)elseif row.step then row.step(1,self)end
    end
    function s:update(dt)
      self.timer=self.timer+(dt or 0);self.rowTimer=self.rowTimer+(dt or 0)
      if opts.update then opts.update(self)end
      if self.game.stack:top()~=self then return end
      local input=game.input
      if input:wasPressed('b') or input:wasPressed('start') then game.stack:pop();return end
      if input:wasPressed('a') then self:activate();return end
      if input:wasPressed('select') and opts.select then opts.select(self);return end
      local key=U.tapDirection(self)
      if #self.rows>0 then
        if key=='up' then self.index=(self.index-2)%#self.rows+1
        elseif key=='down' then self.index=self.index%#self.rows+1
        elseif key=='left' or key=='right' then
          local row=self.rows[self.index];local direction=key=='left' and -1 or 1
          if row.step then row.step(direction,self)
          elseif opts.pages then self.index=math.max(1,math.min(#self.rows,self.index+direction*8))end
        end
      end
      if self.index~=self.lastIndex then self.lastIndex=self.index;self.rowTimer=0 end
    end
    function s:visible()
      self.index=math.max(1,math.min(self.index,math.max(1,#self.rows)))
      if self.index<=self.scroll then self.scroll=self.index-1 end
      if self.index>self.scroll+8 then self.scroll=self.index-8 end
      self.scroll=math.max(0,self.scroll)
    end
    function s:pointer(e,x,y)
      if e.phase~='pressed' and e.phase~='moved' then return true end
      if e.source=='mouse' and e.phase=='pressed' and e.button~=1 then return false end
      self:visible()
      for i=1,8 do local index=self.scroll+i;local row=self.rows[index]
        if row and U.hit(x,y,{4,32+(i-1)*11,152,11})then
          if self.index~=index then self.rowTimer=0 end
          self.index=index;self.lastIndex=index
          if e.phase=='pressed'then
            if row.step and x<125 then row.step(-1,self)else self:activate()end
          end
          return true
        end
      end
      if e.phase=='pressed' and U.hit(x,y,{112,127,46,17})then game.stack:pop()end
      if opts.pages and e.phase=='pressed'then
        if U.hit(x,y,{4,127,38,17})then self.index=math.max(1,self.index-8)
        elseif U.hit(x,y,{44,127,38,17})then self.index=math.min(#self.rows,self.index+8)end
      end
      return true
    end
    function s:draw()
      self:visible();U.background()
      U.marquee(value(opts.title,self),5,5,25,self.timer)
      U.marquee(self.notice or value(opts.subtitle,self) or '',5,18,25,self.timer)
      for i=1,8 do local row=self.rows[self.scroll+i]
        if row then
          local y=34+(i-1)*11;local selected=self.index==self.scroll+i
          if selected then U.focus(4,y-2,152,11);U.marker(6,y)end
          local val=value(row.value,self)
          local columns=23
          if val then val=tostring(val);local x=153-U.width(val);U.text(val,x,y);columns=math.max(1,math.floor((x-22)/6))end
          U.marquee(value(row.label,self),16,y,columns,selected and self.rowTimer or 0)
        end
      end
      if opts.pages then U.text('PREV',5,131);U.text('NEXT',45,131)
      else U.text(opts.footer or 'A:PICK',5,131)end
      U.text('B:BACK',116,131);U.white()
    end
    return s
  end}
  mod.content.screens:register('AutobikeMenu',factory)
  function api.open(game,opts)return Screens.push(game,'AutobikeMenu',opts)end
  api.factory=factory
  return api
end
return Menu
