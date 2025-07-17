vim9script

import "./TextDocumentIdentifier.vim" as tdi
import "../../Utils/Json.vim" as j

export class VersionedTextDocumentIdentifier implements j.JsonSerializable
  
  var version: number
  var textDocument: tdi.TextDocumentIdentifier

  def new(bId: number): void
    this.version = bId->getbufvar('changedtick')
    this.textDocument = tdi.TextDocumentIdentifier.new(bId)
  enddef

  def ToJson(): dict<any>
    return extend({
      version: this.version
    }, this.textDocument.ToJson())
  enddef

endclass
