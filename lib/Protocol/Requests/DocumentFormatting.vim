vim9script

import "../Abstracts/RequestMessage.vim" as req
import "../Objects/TextDocumentIdentifier.vim" as ti
import "../Objects/FormattingOptions.vim" as o

export class DocumentFormatting extends req.RequestMessage

  var textDocument: any
  var options: any

  def new(bId: number)
    this.method = 'textDocument/formatting'
    this.textDocument = ti.TextDocumentIdentifier.new(bId)
    this.options = o.FormattingOptions.new()
    this.params = {
       textDocument: this.textDocument.ToJson(),
       options: this.options.ToJson()
    }
  enddef

endclass
