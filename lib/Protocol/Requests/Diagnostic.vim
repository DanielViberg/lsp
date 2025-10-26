vim9script

import "../Abstracts/RequestMessage.vim" as req
import "../Objects/TextDocumentIdentifier.vim" as tdi

export class Diagnostic extends req.RequestMessage
  
  var textDocument: tdi.TextDocumentIdentifier

  def new(td: tdi.TextDocumentIdentifier)
    this.method = 'textDocument/diagnostic'
    this.params = {
       textDocument: td.ToJson()
    }
  enddef

endclass
