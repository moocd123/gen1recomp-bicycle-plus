-- Actual Loader options and Sandbox/Screens; graphics/audio/movement doubled.
local T=dofile('verification/v1.9.0/support.lua').init(assert(arg[1]));local noop=function()end
love.graphics={setColor=noop,rectangle=noop,push=noop,pop=noop,transformPoint=function(x,y)return x,y end,intersectScissor=noop,getDimensions=function()return 160,144 end}
love.keyboard={isDown=function()return false end}
package.loaded['src.render.Assets']={register=noop};package.loaded['src.render.Font']={draw=noop,drawBox=noop,drawCode=noop}
package.loaded['src.ui.Theme']={cursor=1};package.loaded['src.render.PaletteFX']={wholeNamed=function()return{}end,mode='redpp'}
package.loaded['src.render.GbcPalette']={mode='gbc'}
local Loader=require('src.mods.Loader');local Manifest=require('src.mods.Manifest');local Screens=require('src.ui.Screens');local Stack=require('src.core.StateStack')
local service=[[return{init=function()return{update=function()end,stop=function()end,stopPreview=function()end,status=function()return{}end,previewZones=function()return{}end,needsColourMode=function()return false end,drawPreview=function()return true end}end}]]
local n=0;local function ck(v,m)assert(v,m);n=n+1 end
local function copy(t)local out={};for k,v in pairs(t)do out[k]=type(v)=='table'and copy(v)or v end;return out end
local function same(a,b)if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end;for k,v in pairs(a)do if not same(v,b[k])then return false end end;for k in pairs(b)do if a[k]==nil then return false end end;return true end
for _,edition in ipairs({'red','blue','yellow','gold','silver','crystal'})do
 for _,pair in ipairs({{'original','original','original'},{'original','rgb:123456','rgb:123456'},{'rgb:998877','rgb:123456','rgb:998877'},{'gbc:0EE7','original','gbc:0EE7'}})do
  Screens.invalidate();require('src.core.GameVersion').set(edition);T.Runtime.safeMode=false
  local g={writes=0,data={screens={},audio={songs={}}},input={pressed={},held={}},stack=setmetatable({},{__index=Stack})};g.stack:init()
  function g.input:wasPressed(k)return self.pressed[k]==true end;function g.input:isDown(k)return self.held[k]==true end
  function g:writeOptions()self.writes=self.writes+1 end
  local initial={_audio_layout=5,auto_mount=false,riding_music='area',bike_volume=3,bike_filter=2,bike_song='original',bike_song_resume=true,bike_centres_colour='rgb:112233',bike_colour='rgb:123456',bike_tyres_colour='original',bike_handlebars_colour=pair[1],bike_frame_colour=pair[2],bike_frame_colour_custom='rgb:012345'}
  g.save={player={name='KEEP PROGRESS',money=12345},options={musicVol=6,sfxVol=5,musicFilter=1,modOptions={bicycle_plus=copy(initial)}}};g.options=g.save.options
  local loader=Loader.new({fs=T.fs,game=g,generation=(edition=='red'or edition=='blue'or edition=='yellow')and 1 or 2});g.mods=loader;loader.game=g;loader.modOptions={bicycle_plus=copy(initial)}
  T.Runtime.install(loader.events,loader.hooks)
  local record={path='mods/bicycle_plus',manifest=Manifest.validate({id='bicycle_plus',name='AUTOBIKE+',version='1.9.3',api=2,entry='main.lua',games={edition},permissions={'engine_internals'}},'bicycle_plus')}
  local mod=loader:_api(record);mod.env=loader:_modEnv(record)
  function mod:read(p)if p=='audio.lua'or p=='automount.lua'or p=='colours.lua'then return service end;return T.readDisk(p)end
  function mod.content.screens:register(k,v)g.data.screens[k]=v end
  local before=copy(g.save)
  T.load(mod,'main')(mod);loader.events:emit('game.ready',{game=g})
  local expected=copy(before);local opts=expected.options.modOptions.bicycle_plus
  opts._handlebars_layout=1;opts.bike_handlebars_colour=pair[3];opts.bike_handlebars_colour_custom='rgb:012345'
  ck(same(g.save,expected),'migration changed unrelated data or wrong precedence')
  for _,row in ipairs(loader.optionSchemas.bicycle_plus)do ck(row.key~='bike_frame_colour','obsolete detail option exposed')end
  local count=g.writes;loader.events:emit('game.ready',{game=g});ck(g.writes==count,'migration repeated')
  mod.exports.openColours(g);local menu=g.stack:top();ck(#menu.rows==6,'five components plus reset required')
  local labels={'WHEEL','STRIPE','CENTRE','EDGE','HANDLEBARS','RESET COLOURS'}
  for i,row in ipairs(menu.rows)do ck(row.label()==labels[i],'wrong visible appearance row')end
  g.input.pressed={down=true};menu:update(.02);g.input.pressed={};g.input.held={down=true};for i=1,20 do menu:update(.2)end;g.input.held={}
  ck(menu.index==2,'held navigation repeated')
  mod.exports.setSetting(g,'bike_frame_colour','rgb:FA1234');ck(mod.exports.getSetting('bike_handlebars_colour')=='rgb:FA1234','old setter not aliased')
  T.Runtime.safeMode=true;count=g.writes;ck(not mod.exports.resetColours(g)and g.writes==count,'safe mode wrote reset');T.Runtime.safeMode=false
  ck(mod.exports.resetColours(g),'reset failed')
  local saved=g.save.options.modOptions.bicycle_plus
  for _,k in ipairs({'bike_colour','bike_stripes_colour','bike_centres_colour','bike_tyres_colour','bike_handlebars_colour','bike_frame_colour'})do ck(saved[k]=='original','reset did not clear '..k)end
  for _,k in ipairs({'auto_mount','riding_music','bike_volume','bike_filter','bike_song','bike_song_resume'})do ck(saved[k]==initial[k],'reset altered audio/movement')end
  ck(g.save.player.name=='KEEP PROGRESS'and g.save.player.money==12345 and g.options.musicVol==6,'progress/native settings changed')
  menu:draw();while g.stack:top()do g.stack:pop()end
 end
end
print(('PASS %d native Loader/Sandbox appearance migration/reset/preservation assertions in 24 edition/preference cases.'):format(n))
