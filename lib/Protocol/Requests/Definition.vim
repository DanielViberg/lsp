vim9script

import "../Abstracts/RequestMessage.vim" as req
import "../Objects/TextDocumentPosition.vim" as tdp

export class Definition extends req.RequestMessage
  var textDocumentPosition: tdp.TextDocumentPosition

  def new(tp: tdp.TextDocumentPosition)
    this.textDocumentPosition = tp
    this.method = 'textDocument/definition'
  enddef

  def ToJson(): dict<any>
    this.params = this.textDocumentPosition.ToJson()
    return super.ToJson()
  enddef

endclass
