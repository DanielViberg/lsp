vim9script

import "../Abstracts/RequestMessage.vim" as req
import "../Requests/Methods.vim" as met

export class Shutdown extends req.RequestMessage 
  def new()
    this.method = met.SHUTDOWN
  enddef 
endclass
