local sharer={preventbang=false}

local AWAKE_DATA_DIR=_path.data.."awake/"
local NAMES_DATA_DIR=_path.data.."awake/names/"


function sharer.setup(script_name)
  sharer.add_online(script_name)
  sharer.add_saving()
end


function sharer.add_saving()
  -- add saving/loading
  os.execute("mkdir -p "..NAMES_DATA_DIR)
  params:add_group("save/load",3)
  params:add_text('save_name',"save as...","")
  params:set_action("save_name",function(y)
    -- prevent banging
    local x=y
    params:set("save_name","")
    if x=="" then 
      do return end 
    end
    -- save
    print(x)
    backup_save(x)
    params:set("save_message","saved as "..x)
  end)
  print("AWAKE_DATA_DIR "..AWAKE_DATA_DIR)
  params:add_file("load_name","load",NAMES_DATA_DIR)
  params:set_action("load_name",function(y)
    -- prevent banging
    local x=y
    params:set("load_name",NAMES_DATA_DIR)
    if #x<=#NAMES_DATA_DIR then 
      do return end 
    end
    -- load
    print("load_name: "..x)
    pathname,filename,ext=string.match(x,"(.-)([^\\/]-%.?([^%.\\/]*))$")
    print("loading "..filename)
    backup_load(filename)
    params:set("save_message","loaded "..filename..".")
  end)
  params:add_text('save_message',">","")
end

function sharer.add_online(script_name)
  -- only continue if norns.online exists
  if not util.file_exists(_path.code.."norns.online") then
    print("need to donwload norns.online")
    do return end
  end

  -- prevents initial bang for reloading directory
  sharer.preventbang=true
  clock.run(function()
    clock.sleep(2)
    sharer.preventbang=false 
  end)

  -- load norns.online lib
  local share=include("norns.online/lib/share")

  -- start uploader with name of your script
  local uploader=share:new{script_name=script_name}
  if uploader==nil then
    print("uploader failed, no username?")
    do return end
  end

  -- add parameters
  params:add_group("SHARE",4)

  -- uploader (CHANGE THIS TO FIT WHAT YOU NEED)
  -- select a save from the names folder
  params:add_file("share_upload","upload",NAMES_DATA_DIR)
  params:set_action("share_upload",function(y)
    -- prevent banging
    local x=y
    params:set("share_download",NAMES_DATA_DIR)
    if #x<=#NAMES_DATA_DIR then
      do return end
    end

    -- choose data name
    -- (here dataname is from the selector)
    local dataname=share.trim_prefix(x,NAMES_DATA_DIR)

    -- send message to user
    params:set("share_message","uploading...")
    _menu.redraw()
    print("uploading "..x.." as "..dataname)

    -- upload parameters file 
    pathtofile=AWAKE_DATA_DIR..dataname.."/parameters.pset"
    target=AWAKE_DATA_DIR..uploader.upload_username.."_"..dataname.."/parameters.pset"
    uploader:upload{dataname=dataname,pathtofile=pathtofile,target=target}

    -- upload the names file
    pathtofile=NAMES_DATA_DIR..dataname
    target=NAMES_DATA_DIR..uploader.upload_username.."_"..dataname
    uploader:upload{dataname=dataname,pathtofile=pathtofile,target=target}

    -- goodbye
    params:set("share_message","uploaded.")
  end)

  -- downloader
  download_dir=share.get_virtual_directory(script_name)
  params:add_file("share_download","download",download_dir)
  params:set_action("share_download",function(y)
    -- prevent banging
    local x=y
    params:set("share_download",download_dir)
    if #x<=#download_dir then
      do return end
    end

    -- download
    print("downloading!")
    params:set("share_message","downloading...")
    _menu.redraw()
    local msg=share.download_from_virtual_directory(x)
    params:set("share_message",msg)
  end)

  -- add a button to refresh the directory
  params:add{type='binary',name='refresh directory',id='share_refresh',behavior='momentary',action=function(v)
    if sharer.preventbang then
      do return end
    end
    print("updating directory")
    params:set("share_message","refreshing directory.")
    _menu.redraw()
    share.make_virtual_directory()
    params:set("share_message","directory updated.")
  end
}
params:add_text('share_message',">","")
end

--
-- saving and loading
--
function backup_save(savename)
  -- create if doesn't exist
  savedir = AWAKE_DATA_DIR..savename.."/"
  os.execute("mkdir -p "..savedir)
  os.execute("echo "..savename.." > "..NAMES_DATA_DIR..savename)

  -- save the parameter set
  params:write(savedir.."/parameters.pset")
end

function backup_load(savename)
  sharer.preventbang=true
  clock.run(function()
    clock.sleep(2)
    sharer.preventbang=false 
  end)
  params:read(AWAKE_DATA_DIR..savename.."/parameters.pset")
end



return sharer
