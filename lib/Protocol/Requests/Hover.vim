vim9script

import "../Abstracts/RequestMessage.vim" as req
import "../Objects/TextDocumentPosition.vim" as tdp
import "../Requests/Methods.vim" as met

export class Hover extends req.RequestMessage 
  def new(td: tdp.TextDocumentPosition)
    this.method = 'textDocument/hover'
    this.params = td.ToJson()
  enddef 
endclass
