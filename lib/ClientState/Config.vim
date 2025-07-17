vim9script

var CachedConfig: list<dict<any>> = null_list

export class Config 
endclass

export def OpenLspConfig()
  var configDir = readfile(expand('$HOME/.vim/.lsp-config-dir'))[0]
  var configFile = configDir .. "lsp-config.json"
  execute 'edit' configFile
enddef

export def Init(): void

  var pointerFile = expand("$HOME/.vim/.lsp-config-dir")
  if !filereadable(pointerFile)
    # Ask user for config file dir + (lsp-config.json)
    var configDir = input("Enter directory for lsp servers config file (lsp-config.json):", expand("$HOME"), "dir")
    writefile([configDir], pointerFile)
  endif

  var configDir = readfile(expand("$HOME/.vim/.lsp-config-dir"))[0]
  var configFile = configDir .. "lsp-config.json"
  if !filereadable(configFile)
  # Ask to create if dir has no file
    var sel = confirm("There is no lsp-config.json, create it now?", "&Yes\n&No", 2)
    echomsg sel
    if sel == 1
      var exConfigFile = expand("%:p:h") .. '/../assets/lsp-config.json'
      system("cp " .. shellescape(exConfigFile) .. " " .. shellescape(configDir))
    else
      return
    endif
  endif

  var servers = json_decode(join(readfile(configFile), '')).servers
  # Add id to each server
  servers->map((i, s) => extend(s, {id: i + 1 }))
  CachedConfig = servers
enddef

export def GetConfigServerIdsByFt(ft: string): list<number>
  return CachedConfig->filter((_, s) => has_key(s, 'filetype') && index(s.filetype, ft) != -1)
                     ->mapnew((_, s) => has_key(s, 'id') ? s.id : '')
                     ->filter((_, i) => !empty(i))
enddef 

export def GetConfigServerById(id: number): dict<any> 
  var serv = CachedConfig->filter((_, s) => s.id == id)
  return !empty(serv) ? serv[0] : null_dict
enddef

