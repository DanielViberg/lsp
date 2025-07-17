vim9script

import "../Abstracts/RequestMessage.vim" as req
import "../Requests/Methods.vim" as met
import "../../Utils/Json.vim" as j

const currentDir = expand('<sfile>')

export class Initialize extends req.RequestMessage 
  var initOpts: any

  def new(rootUri: string, this.initOpts = v:none)
    this.method = met.INITIALIZE
    this.params = {
      processId: getpid(),
      clientInfo: {
        name:    'Vim',
        version: '9.1'
      },
      rootUri: rootUri,
      initializationOptions: this.initOpts,
      capabilities: json_encode(readfile(fnamemodify(currentDir, ':h') .. '/../Config/cc.json')),
    }
  enddef 

endclass
