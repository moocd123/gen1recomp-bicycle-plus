-- A narrowly scoped adapter to the engine's user-initiated file chooser.
-- No global LOVE callbacks or launcher instance are replaced. The temporary
-- request copies only the explicitly selected file into this mod's baseroms
-- staging area; our audio decoder validates it before copying to mod.cache.
local Import={}
function Import.init(mod,library)
  local Platform=require('src.core.Platform')
  local FilePicker=require('src.core.FilePicker')
  local RomImporter
  local Required=require('src.mods.RequiredImports')
  local Runtime=require('src.mods.Runtime')
  local FS=require('src.core.SaveData').persistenceFs()
  local api={pending=false,message=nil,result=nil}
  local request,manifest,spec,sourceName
  local sequence,abandoned=0,{}
  local inbox='baseroms/audio_inbox'
  local EXT={mp3=true,ogg=true,wav=true}
  api.inboxLabel='mods/'..mod.id..'/'..inbox
  function api.inbox()
    local rows={}
    for _,name in ipairs(mod:list(inbox) or {})do
      if type(name)=='string' and not name:find('[/\\]') and not name:find('..',1,true) then
        local ext=name:lower():match('%.([a-z]+)$')
        local info=EXT[ext or ''] and mod:info(inbox..'/'..name)
        if info and info.type=='file' then rows[#rows+1]={name=name,bytes=info.size}end
      end
    end
    table.sort(rows,function(a,b)return a.name:lower()<b.name:lower()end)
    return rows
  end
  function api.fromInbox(name)
    if Runtime.safeMode then return nil,'Safe mode: import disabled.'end
    local row
    for _,candidate in ipairs(api.inbox())do if candidate.name==name then row=candidate;break end end
    if not row then return nil,'Select a file in the audio inbox.'end
    if type(row.bytes)~='number' then return nil,'Could not read the file size. Use the system picker.'end
    if row.bytes>64*1024*1024 then return nil,'Maximum file size: 64 MiB.'end
    local bytes=mod:read(inbox..'/'..name)
    return library.importBytes(bytes,name)
  end
  local function complete(bytes,name)
    local id,err=library.importBytes(bytes,name)
    api.result=id;api.message=id and library.notice or tostring(err)
    api.pending=false
    return id~=nil
  end
  function api.start()
    if Runtime.safeMode then return false,'Safe mode: import disabled.'end
    if request and api.pending then return false,'A file choice is already pending.'end
    if request and api.mode=='native' then abandoned[Required.path(manifest,spec)]={manifest=manifest,spec=spec}end
    sourceName=nil
    api.mode=nil
    RomImporter=RomImporter or require('src.import.RomImporter')
    api.result,api.message=nil,nil
    api.cancelled=false
    sequence=sequence+1
    spec={id='bicycle_personal_audio',file='bicycle_personal_audio_'..tostring(os.time())..'_'..sequence..'.bin',
      name='Personal audio file',format='raw',required=false,max_size=64*1024*1024}
    manifest={id=mod.id,name='Bicycle Plus personal audio',path=mod.path,
      optional_imports={spec}}
    api.staging=Required.path(manifest,spec)
    -- This is a picker request, not a new dependency or ROM declaration. Its
    -- only consumer is this adapter. It does not alter the installed manifest.
    request=setmetatable({mods={{id=mod.id,manifest=manifest}},
      nativePicker=false,mobileFileBridge=false,isNX=false,workState='idle'},
      {__index=RomImporter})
    function request:_importRequiredData(_,_,bytes)
      return complete(bytes,sourceName)
    end
    function request:_refreshMods()end
    local platform=Platform.detect()
    api.pending=true
    if platform.hasNativePicker and not FilePicker.available() then
      -- A function exported as a no-op on a desktop/console is not a picker.
      -- Require the declared scoped-import contract; never fall back to ROM
      -- staging for an audio file. Desktop dialogs take precedence below.
      local supported=false
      if love.system.pickFileKinds then
        local ok,kinds=pcall(love.system.pickFileKinds)
        supported=ok and type(kinds)=='string' and (','..kinds..','):find(',required_import,',1,true)~=nil
      end
      if not supported then
        api.pending=false;api.mode='inbox'
        return false,'No scoped audio picker in this build. Use AUDIO INBOX.'
      end
      if type(mod.path)~='string' or not mod.path:match('^mods/[^/]+$') then
        api.pending=false;return false,'This mod location does not support the native picker.'
      end
      api.mode='native'
      request.nativePicker=true;request.mobileFileBridge=true
      request.android=platform.os=='Android'
      -- Current mobile bridges create an atomic file and completion receipt.
      Required.remove(manifest,spec.id)
      RomImporter.chooseRequiredImport(request,mod.id,spec.id)
      if request.requiredImportNotice then
        api.pending=false;return false,request.requiredImportNotice.text
      end
      if request.requiredImportLegacyRomPick then
        api.pending=false;return false,'Update the app: this native picker bridge is too old.'
      end
      api.message='Choose an audio file. Then return here.'
      api.mode='native'
      return true
    end
    if FilePicker.available() then
      api.mode='desktop'
      local path=FilePicker.open('Choose bicycle music',{label='Audio',exts={'mp3','ogg','wav'}})
      if not path then api.pending=false;api.message='No file selected.';return false,api.message end
      sourceName=FilePicker.basename(path)
      -- This engine method checks the external file size against max_size
      -- BEFORE reading. Only the request-local callback receives its bytes.
      RomImporter._importRequiredSource(request,mod.id,spec.id,path,true)
      api.pending=false
      if request.requiredImportNotice then api.message=request.requiredImportNotice.text end
      return api.result~=nil,api.message
    end
    api.pending=false
    api.mode='inbox'
    return false,'No native dialog in this build. Use AUDIO INBOX below.'
  end
  local elapsed=0
  function api.poll(dt)
    if (not request or api.mode~='native')and next(abandoned)==nil then return end
    elapsed=elapsed+(dt or 0);if elapsed<0.25 then return end;elapsed=0
    local path=request and api.mode=='native'and Required.path(manifest,spec)
    local marker=FS and FS.read('pick_complete.flag')
    local which,digest,count
    -- Parse explicitly: a logical expression would discard extra captures.
    if type(marker)=='string' then which,digest,count=marker:match('^v1\n([^\n]+)\n(%x+)\n(%d+)')end
    local old=which and abandoned[which]
    if old then
      FS.remove('pick_complete.flag');Required.remove(old.manifest,old.spec.id);abandoned[which]=nil;return
    end
    if path and which==path then
      if api.cancelled then FS.remove('pick_complete.flag');Required.remove(manifest,spec.id);request=nil;return end
      FS.remove('pick_complete.flag')
      count=tonumber(count)
      local info=FS.getInfo(path,'file')
      if not count or count<=0 or count>64*1024*1024 or not info or (info.size and info.size~=count)then
        api.message='Audio must be a complete file under 64 MiB.';api.pending=false
      else
        local bytes=mod:read('baseroms/'..spec.file)
        if not bytes or #bytes~=count then api.message='Audio copy was incomplete.';api.pending=false
        elseif #digest~=32 or love.data.encode('string','hex',love.data.hash('md5',bytes)):lower()~=digest:lower() then
          api.message='Audio transfer failed integrity check.';api.pending=false
        else complete(bytes,nil)end
      end
      Required.remove(manifest,spec.id)
      request=nil
      return
    end
    if not path then return end
    local cancelled=FS and FS.read('pick_cancelled.flag')
    if cancelled==path or cancelled==spec.file then
      FS.remove('pick_cancelled.flag');api.message='No file selected.';api.pending=false
      Required.remove(manifest,spec.id);request=nil;return
    end
    local errorText=FS and FS.read('pick_error.flag')
    if type(errorText)=='string' and errorText==path then
      FS.remove('pick_error.flag');api.message='No audio file was imported.';api.pending=false
      Required.remove(manifest,spec.id);request=nil
    end
  end
  function api.cancel()
    -- Only abandon our request. Never delete another request's completion flag.
    -- Keep polling a pending native receipt without accepting its audio.
    -- Desktop pickers return synchronously; only native copies can finish late.
    api.pending=false;api.cancelled=true
  end
  return api
end
return Import
