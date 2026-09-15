-- One user-triggered import action. The engine owns OS dialogs and file reads;
-- this adapter never unwraps sandbox globals or opens an arbitrary host path.
local Picker={}
function Picker.init(mod,library)
  local Runtime=require('src.mods.Runtime')
  local Platform=require('src.core.Platform')
  local Cache=require('src.import.CacheFs')
  local FilePicker=require('src.core.FilePicker')
  local Json=require('src.link.Json')
  local api={request=nil,counter=0,abandoned={}}
  local LIMIT=64*1024*1024
  local function manifest(file)
    return {id=mod.id,name='AUTOBIKE+',path=mod.path or ('mods/'..mod.id),
      optional_imports={{id='autobike_audio',name='Audio file',file=file,
        format='raw',max_size=LIMIT,required=false}}}
  end
  local function temporary(m)return m.path..'/baseroms/'..m.optional_imports[1].file end
  local function clean(r)
    if not r then return end
    -- The engine's scoped import remover can remove this mod's staging file;
    -- it is not used for library tracks or the external file the user chose.
    local prefix=Cache.prefix
    pcall(function()require('src.mods.RequiredImports').remove(r.manifest,'autobike_audio')end)
    Cache.prefix=prefix
  end
  local function persist(r)
    local state={abandoned={}}
    if r then state.file=r.manifest.optional_imports[1].file end
    for _,old in ipairs(api.abandoned)do state.abandoned[#state.abandoned+1]=old.manifest.optional_imports[1].file end
    return mod.cache:write('music/picker.json',Json.encode(state))
  end
  function api.hasWork()return api.request~=nil or #api.abandoned>0 end
  local function proxy(m)
    local obj={mods={{id=mod.id,manifest=m}},nativePicker=false,mobileFileBridge=false,
      _refreshMods=function()end}
    -- Use the same bounded desktop reader as the launcher, but receive the
    -- chosen bytes here instead of importing them as a ROM or a saved game.
    function obj:_importRequiredData(_,_,bytes)
      self.result,self.problem=library.importBytes(bytes,self.originalName)
      return self.result~=nil
    end
    return setmetatable(obj,{__newindex=function(t,k,v)
      -- Older Android bridges fall back to picked_rom.gb. Never allow that
      -- fallback from an in-game music page; it could collide with ROM import.
      if k=='requiredImportLegacyRomPick' and v then
        error('This app build needs a newer native document picker for audio',0)
      end
      rawset(t,k,v)
    end})
  end
  function api.readSelected(path)
    if Runtime.safeMode then return nil,'Safe mode: importing is disabled' end
    if type(path)~='string' or path=='' or path:find('%z') then return nil,'No audio file selected' end
    local m=manifest('autobike_desktop_input.bin');local obj=proxy(m)
    obj.originalName=FilePicker.basename(path)
    local called,err=pcall(function()
      require('src.import.RomImporter')._importRequiredSource(obj,mod.id,'autobike_audio',path,true)
    end)
    if not called then return nil,'Could not read the selected audio: '..tostring(err) end
    return obj.result,obj.problem or (obj.requiredImportNotice and obj.requiredImportNotice.text)
      or (not obj.result and 'Could not read this audio file' or nil)
  end
  function api.choose()
    if Runtime.safeMode then return nil,'Safe mode: importing is disabled' end
    if api.request then return nil,'Finish or cancel the current file selection first' end
    local caps=Platform.detect()
    if caps.hasNativePicker then
      api.counter=api.counter+1
      local name=('autobike_audio_%d_%d_%d.bin'):format(os.time(),api.counter,math.random(100000,999999))
      local m=manifest(name);local obj=proxy(m)
      obj.nativePicker=true;obj.mobileFileBridge=caps.mobile==true;obj.android=caps.os=='Android'
      -- On current mobile builds chooseRequiredImport delegates to the native
      -- document picker with this unique, mod-confined destination.
      if not caps.mobile then return 'browser' end
      local r={manifest=m,object=obj,discard=false}
      local saved,saveErr=persist(r);if not saved then return nil,saveErr end
      local ok,err=pcall(function()
        require('src.import.RomImporter').chooseRequiredImport(obj,mod.id,'autobike_audio')
      end)
      if not ok or obj.requiredImportNotice then
        persist(nil)
        return nil, obj.requiredImportNotice and obj.requiredImportNotice.text or tostring(err)
      end
      if not obj.pickerPendingKind then persist(nil);return nil,'System file picker could not open' end
      api.request=r;library.pending=true;return 'pending'
    end
    local ok,available=pcall(FilePicker.available)
    if ok and available then
      local opened,path=pcall(FilePicker.open,'AUTOBIKE+ - Import audio',
        {label='Audio',exts={'mp3','ogg','wav','flac'},tempName='autobike_audio'})
      if not opened then return nil,'System file picker could not open' end
      -- Cancelling a native picker is a cancellation, not another help menu.
      if not path then return nil,'IMPORT CANCELLED' end
      return api.readSelected(path)
    end
    return 'browser'
  end
  function api.poll()
    if Runtime.safeMode then return end
    -- A cancelled iOS dialog need not emit a cancellation flag. Retire it
    -- without blocking the next Import action; unique destinations prevent
    -- a late callback from being imported under a newer request.
    for i=#api.abandoned,1,-1 do
      local old=api.abandoned[i];local path=temporary(old.manifest)
      local errorFlag=Cache.readAt('pick_error.flag')
      if Cache.existsAt(path) or errorFlag==path or errorFlag=='cancelled:'..path then
        clean(old);table.remove(api.abandoned,i);persist(api.request)
      end
    end
    local r=api.request
    if not r then return end
    local path=temporary(r.manifest)
    local errorFlag=Cache.readAt('pick_error.flag')
    if errorFlag==path or errorFlag=='cancelled:'..path then
      api.request=nil;library.pending=false;persist(nil);clean(r)
      return nil,errorFlag:sub(1,10)=='cancelled:' and 'IMPORT CANCELLED' or 'FILE PICKER FAILED'
    end
    -- Direct native imports rename .part to the final file and only then
    -- emit this completion marker. Ignore markers for every other importer.
    local marker=Cache.readAt('pick_complete.flag')
    if type(marker)~='string' or not marker:find('\n'..path..'\n',1,true) then return end
    local count=tonumber(marker:match('\n(%d+)\n?$'))
    if not count or count>LIMIT then
      api.request=nil;library.pending=false;persist(nil);clean(r)
      return nil,'Choose audio no larger than 64 MiB'
    end
    local bytes=mod:read('baseroms/'..r.manifest.optional_imports[1].file)
    if type(bytes)~='string' or #bytes~=count then return end
    api.request=nil;library.pending=false;persist(nil)
    if r.discard then clean(r);return end
    local row,err=library.importBytes(bytes,nil)
    clean(r)
    return row,err
  end
  function api.cancel()
    if api.request then
      api.abandoned[#api.abandoned+1]=api.request
      api.request=nil;persist(nil);library.pending=false
    end
  end
  function api.browser()
    -- Borrow the engine's directory listing, not its global active modal.
    -- Leaving FileBrowser.active set would steal input from our own screen.
    local shared=require('src.ui.kit.FileBrowser')
    local browser={active=false,currentDir='.',entries={}}
    local function scan(dir)
      if shared.active then return nil,'Another file browser is open' end
      if type(dir)~='string' or dir:find('["`$\r\n]') then return nil,'This folder name cannot be browsed safely' end
      local ok,err=pcall(shared.open,{title='Select audio',mode='all',initialPath=dir})
      if ok then browser.currentDir=shared.currentDir;browser.entries=shared.entries or {}end
      shared.close(nil)
      if not ok then return nil,'Could not browse this folder: '..tostring(err)end
      return true
    end
    function browser.open(opts)local ok,err=scan(opts.initialPath or '.');browser.active=ok==true;return ok,err end
    function browser.setDirectory(dir)return scan(dir)end
    function browser.close()browser.active=false end
    return browser
  end
  local state=mod.cache:read('music/picker.json')
  if state then
    local ok,t=pcall(Json.decode,state)
    local function valid(name)return type(name)=='string' and name:match('^autobike_audio_%d+_%d+_%d+%.bin$')end
    if ok and type(t)=='table' then
      if valid(t.file)then
        local r={manifest=manifest(t.file),discard=t.discard==true}
        if r.discard then api.abandoned[#api.abandoned+1]=r else api.request=r;library.pending=true end
      end
      if type(t.abandoned)=='table'then for i,name in ipairs(t.abandoned)do
        if i>128 then break end
        if valid(name)then api.abandoned[#api.abandoned+1]={manifest=manifest(name),discard=true}end
      end end
    end
  end
  return api
end
return Picker
