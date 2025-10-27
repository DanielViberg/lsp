vim9script

import "../../env.vim" as e

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

  var configFile: string = ""
  var configDir: string = ""

  if e.TESTING
    configFile = e.TESTING_CONF_FILE
  else
    if !filereadable(pointerFile)
      # Ask user for config file dir + (lsp-config.json)
      configDir = input("Enter directory for lsp servers config file (lsp-config.json):", expand("$HOME"), "dir")
      writefile([configDir], pointerFile)
    endif

    configDir = readfile(expand("$HOME/.vim/.lsp-config-dir"))[0]
    configFile = configDir .. "lsp-config.json"

    if !filereadable(configFile)
    # Ask to create if dir has no file
      var sel = confirm("There is no lsp-config.json, create it now?", "&Yes\n&No", 2)
      if sel == 1
        var exConfigFile = expand("%:p:h") .. '/../assets/lsp-config.json'
        var cp = "cp"
        if has("win32")
          cp = "copy"
        endif
        system(cp .. " " .. shellescape(exConfigFile) .. " " .. shellescape(configDir))
      else
        return
      endif
    endif
  endif

  var servers = json_decode(join(readfile(configFile), '')).servers
  # Add id to each server
  servers->map((i, s) => extend(s, {id: i + 1 }))
  CachedConfig = servers
enddef

export def GetConfigServerIdsByFt(ft: string): list<number>
  return CachedConfig->filter((_, s) => has_key(s, 'filetype') && 
                                        has_key(s, 'path') &&
                                        index(s.filetype, ft) != -1)
                     ->mapnew((_, s) => has_key(s, 'id') ? s.id : '')
                     ->filter((_, i) => !empty(i))
enddef 

export def GetConfigServerById(id: number): dict<any> 
  var serv = CachedConfig->filter((_, s) => s.id == id)
  return !empty(serv) ? serv[0] : null_dict
enddef

export def GetConfigItem(server: any, configItem: dict<any>): any
  if server.config.workspaceConfig->empty()
    return {}
  endif
  if !configItem->has_key('section') || configItem.section->empty()
    return server.config.workspaceConfig
  endif
  var config: any = server.config.workspaceConfig
  for part in configItem.section->split('\.')
    if !config->has_key(part)
      return {}
    endif
    var nConfig = config[part]
    if type(nConfig) == v:t_bool
      nConfig = string(nConfig)
    endif
    config = nConfig
  endfor
  return config
enddef

