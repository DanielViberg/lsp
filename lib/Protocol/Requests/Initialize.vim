vim9script

import "../Abstracts/RequestMessage.vim" as req
import "../../Utils/Json.vim" as j
import "../../Utils/Str.vim" as str
import "../../Utils/Log.vim" as l
import "../Config/cc.vim" as c
import "../../../env.vim" as e

const currentDir = expand('<sfile>')

export class Initialize extends req.RequestMessage 
  def new(config: dict<any>)
    this.method = 'initialize'
    this.resetClientReqNr = true
    var rootUri = ''
    var rootSearchFiles = config->get('rootSearch')
    var bufDir = bufnr('.')->bufname()->fnamemodify(':p:h')
    if !rootSearchFiles->empty()
      rootUri = str.FindNearestRootDir(bufDir, rootSearchFiles)
    endif
    if rootUri->empty()
      var cwd = getcwd()

      # bufDir is within cwd
      var bufDirPrefix = bufDir[0 : cwd->strcharlen() - 1]
      if &fileignorecase
          ? bufDirPrefix ==? cwd
          : bufDirPrefix == cwd
        rootUri = cwd
      else
        rootUri = bufDir
      endif
    endif

    rootUri = uri_encode(rootUri)

    l.PrintDebug('Root uri: ' .. rootUri)

    this.params = {
      processId: getpid(),
      clientInfo: {
        name:    'Vim',
        version: '9.1'
      },
      trace: e.DEBUG ? 'verbose' : 'off',
      rootUri: rootUri,
      initializationOptions: config->get('initializationOptions', null_dict),
      capabilities: c.CC
    }
  enddef 

endclass
