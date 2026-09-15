-- One user-triggered import action. The engine owns OS dialogs and file reads;
-- this adapter never unwraps sandbox globals or opens an arbitrary host path.
local Picker={}
function Picker.init(mod,library)
  local Runtime=require('src.mods.Runtime')
  local Platform=require('src.core.Platform')
  local Cache=require('src.import.CacheFs')
  local FilePicker=require('src.core.FilePicker')
  local Json=require('src.link.Json')
  local api={request=nil,counter=0,abandoned={},clock=0}
  local LEGACY='picked_required_import.bin'
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
    if r then
      state.file=r.manifest.optional_imports[1].file
      state.legacyBlocked=r.legacyBlocked==true
      state.legacyError=r.legacyError
    end
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
      if self.capture then self.bytes=bytes;return true end
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
  -- Read through the same bounded native reader as the launcher. A mod's
  -- compatibility filesystem does not necessarily expose the native pick.
  local function readPending(r,path)
    assert(path==temporary(r.manifest) or path==LEGACY, 'Invalid picker destination')
    local obj=proxy(r.manifest);obj.capture=true
    local ok,err=pcall(function()
      require('src.import.RomImporter')._importRequiredSource(obj,mod.id,'autobike_audio',path,true)
    end)
    if not ok then return nil,'Could not read selected audio: '..tostring(err) end
    if type(obj.bytes)~='string' then
      return nil,(obj.requiredImportNotice and obj.requiredImportNotice.text) or 'Selected audio could not be read'
    end
    if #obj.bytes>LIMIT then return nil,'Choose audio no larger than 64 MiB' end
    return obj.bytes
  end
  local function removeExact(path)
    local prefix=Cache.prefix;Cache.prefix=''
    local ok,err=pcall(Cache.remove,path);Cache.prefix=prefix
    return ok,err
  end
  local function errorFor(r)
    local path=temporary(r.manifest);local flag=Cache.readAt('pick_error.flag')
    local target=type(flag)=='string' and flag:gsub('^cancelled:','')
    if target==path or (target==LEGACY and not r.legacyBlocked and flag~=r.legacyError) then return flag end
  end
  local function markerFor(r)
    local raw=Cache.readAt('pick_complete.flag')
    if type(raw)~='string' or #raw>4096 then return nil end
    local version,path,digest,count=raw:match('^([^\r\n]+)\r?\n([^\r\n]+)\r?\n([^\r\n]+)\r?\n([^\r\n]+)\r?\n?$')
    if path~=temporary(r.manifest) then return nil end
    if version~='v1' or #digest~=32 or not digest:match('^%x+$') or not count:match('^%d+$') then
      return raw,nil,'Invalid audio completion marker'
    end
    count=tonumber(count)
    if not count or count<12 or count>LIMIT then return raw,nil,'Choose valid audio no larger than 64 MiB' end
    return raw,count,nil,digest:lower()
  end
  local function clearSignals(r)
    -- Completion/error markers are shared with the launcher. Only remove a
    -- marker still bound to THIS exact request; never touch another import.
    local marker=markerFor(r)
    if marker and Cache.readAt('pick_complete.flag')==marker then removeExact('pick_complete.flag') end
    local err=errorFor(r)
    if err and Cache.readAt('pick_error.flag')==err then removeExact('pick_error.flag') end
  end
  local function finish(r,bytes,err,path)
    api.request=nil;library.pending=false;persist(nil)
    local row
    if bytes and not r.discard then
      local ok,a,b=pcall(library.importBytes,bytes,nil)
      if ok then row,err=a,b else err='Audio import failed: '..tostring(a) end
    end
    clearSignals(r)
    if path==LEGACY and not r.legacyBlocked then removeExact(LEGACY) end
    clean(r)
    return row,err
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
    if api.request then
      local row,err=api.poll(0)
      if row or err then return row,err end
      -- A repeated activation while the native window is opening does nothing.
      -- After returning, Import also acts as retry rather than deadlocking.
      if api.request.lastBytes or api.clock-(api.request.started or -2)<1 then return 'pending' end
      api.cancel()
    end
    local caps=Platform.detect()
    if caps.hasNativePicker then
      api.counter=api.counter+1
      local name=('autobike_audio_%d_%d_%d.bin'):format(os.time(),api.counter,math.random(100000,999999))
      local m=manifest(name);local obj=proxy(m)
      obj.nativePicker=true;obj.mobileFileBridge=caps.mobile==true;obj.android=caps.os=='Android'
      -- On current mobile builds chooseRequiredImport delegates to the native
      -- document picker with this unique, mod-confined destination.
      if not caps.mobile then return 'browser' end
      if Cache.existsAt(LEGACY) then
        return nil,'Another dependency import is pending; finish it in the launcher first'
      end
      local r={manifest=m,object=obj,discard=false,legacyBlocked=false,started=api.clock,legacyError=Cache.readAt('pick_error.flag')}
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
  function api.poll(dt)
    if Runtime.safeMode then return end
    api.clock=api.clock+math.max(0,math.min(1,tonumber(dt) or 0))
    -- Late direct callbacks for abandoned requests have unique destinations.
    -- Do not consume any global ROM/save/mod staging files.
    for i=#api.abandoned,1,-1 do
      local old=api.abandoned[i];local path=temporary(old.manifest)
      if not Cache.existsAt(path..'.part') and (Cache.existsAt(path) or errorFor(old)) then
        clearSignals(old);clean(old);table.remove(api.abandoned,i);persist(api.request)
      end
    end
    local r=api.request
    if not r then return end
    local flag=errorFor(r)
    if flag then return finish(r,nil,flag:sub(1,10)=='cancelled:' and 'IMPORT CANCELLED' or 'FILE PICKER FAILED') end
    local path=temporary(r.manifest)
    local marker,count,invalid,digest=markerFor(r)
    if invalid then return finish(r,nil,invalid) end
    local source
    if Cache.existsAt(path) and not Cache.existsAt(path..'.part') then source=path
    elseif not r.legacyBlocked and Cache.existsAt(LEGACY) and not Cache.existsAt(LEGACY..'.part') then source=LEGACY end
    if not source then
      -- Some bridges report cancellation with no marker at all. Returning to
      -- Import can retry immediately; this backstop also ends a silent wait.
      if api.clock-(r.started or 0)>120 then
        api.cancel();return nil,'NO FILE RETURNED - IMPORT SONG TO RETRY'
      end
      return
    end
    if r.nextRead and api.clock<r.nextRead then return end
    r.nextRead=api.clock+0.25
    local bytes,err=readPending(r,source)
    if not bytes then return finish(r,nil,err,source) end
    if source==path and marker then
      if #bytes~=count then return finish(r,nil,'Audio copy size did not match; please retry',source) end
      if love.data and love.data.hash then
        local ok,sum=pcall(love.data.hash,'md5',bytes)
        if ok and type(sum)=='string' then
          sum=(sum:gsub('.',function(c)return ('%02x'):format(c:byte())end))
          if sum~=digest then return finish(r,nil,'Audio copy checksum did not match; please retry',source) end
        end
      end
    else
      -- Older native bridges deliver picked_required_import.bin without the
      -- new marker. A final direct destination can also outlive a consumed
      -- marker. Never inspect .part files, and require an unchanged payload
      -- across polls before validating/decoding either markerless delivery.
      if r.lastSource~=source or r.lastBytes~=bytes then
        r.lastSource=source;r.lastBytes=bytes;return
      end
    end
    r.lastBytes=nil
    return finish(r,bytes,nil,source)
  end
  function api.cancel()
    local r=api.request
    if r then
      -- Only clear a standard staging file when this request owned the slot.
      -- Existing unrelated dependency files prevented choose() from opening.
      if not r.legacyBlocked and Cache.existsAt(LEGACY) then removeExact(LEGACY) end
      clearSignals(r)
      r.lastBytes=nil;r.legacyBlocked=true
      api.abandoned[#api.abandoned+1]=r
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
        local r={manifest=manifest(t.file),discard=t.discard==true,legacyBlocked=t.legacyBlocked==true,started=-2,legacyError=type(t.legacyError)=='string' and t.legacyError or nil}
        if r.discard then api.abandoned[#api.abandoned+1]=r else api.request=r;library.pending=true end
      end
      if type(t.abandoned)=='table'then for i,name in ipairs(t.abandoned)do
        if i>128 then break end
        if valid(name)then api.abandoned[#api.abandoned+1]={manifest=manifest(name),discard=true,legacyBlocked=true}end
      end end
    end
  end
  return api
end
return Picker
