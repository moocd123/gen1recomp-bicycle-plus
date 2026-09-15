-- AUTOBIKE+ private cycling controls. Does not wrap, rename or insert anything
-- into either generation's native Audio/OptionsMenu implementations.
local Menu={}
function Menu.init(mod,config)
  local get,set=config.getSetting,config.setSetting
  local api={}
  local filters={'OFF','1X','2X','3X'}
  local function row(key,label,maximum,inherit)
    local low=inherit and -1 or 0
    return {label=label,key=key,value=function()
      local n=get(key)
      if n<0 then return 'SAME' end
      if maximum==3 then return filters[n+1] end
      return n==0 and 'OFF' or tostring(n)
    end,step=function(d,s)
      local n=get(key)
      if maximum==3 then n=(n-low+d)%(maximum-low+1)+low
      else n=math.max(low,math.min(maximum,n+d))end
      set(s.game,key,n)
    end}
  end
  function api.rows()
    return {
      row('riding_area_volume','AREA VOLUME',7,true),
      row('riding_area_filter','AREA FILTER',3,true),
      row('riding_sfx_volume','SFX VOLUME',7,true),
      row('riding_sfx_filter','SFX FILTER',3,true),
      row('bike_volume','CYCLING MUSIC VOLUME',7,false),
      row('bike_filter','CYCLING MUSIC FILTER',3,false),
      {label='BIKE SONG',action=function(s)config.openSong(s.game)end},
      {label='ON MOUNT',value=function()return get('bike_song_resume') and 'RESUME' or 'RESTART'end,
       step=function(_,s)set(s.game,'bike_song_resume',not get('bike_song_resume'))end},
    }
  end
  function api.open(game)
    return config.menus.open(game,{title='BIKE AUDIO',tag='autobike.audio',
      subtitle='WHILE CYCLING',rows=api.rows(),footer='LR:CHANGE'})
  end
  function api.update()end -- compatibility for an existing main integration
  return api
end
return Menu
