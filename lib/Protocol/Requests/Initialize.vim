vim9script

import "../Abstracts/RequestMessage.vim" as req
import "../../Utils/Json.vim" as j
import "../../Utils/Str.vim" as str
import "../../Utils/Log.vim" as l

const currentDir = expand('<sfile>')

export class Initialize extends req.RequestMessage 
  def new(config: dict<any>)
    this.method = 'initialize'

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

    rootUri = str.Uri(rootPath)

    l.PrintDebug('Root path: ' .. rootPath)

    this.params = {
      processId: getpid(),
      clientInfo: {
        name:    'Vim',
        version: '9.1'
      },
      rootUri: rootUri,
      initializationOptions: config->get('initializationOptions', null_dict),
      capabilities: json_encode(
                      json_decode(
                        join(
                          readfile(fnamemodify(currentDir, ':h') .. '/../Config/cc.json'), "\n")
                      )),
    }
  enddef 

endclass
