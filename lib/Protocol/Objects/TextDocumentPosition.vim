vim9script

import "./TextDocumentIdentifier.vim" as ti
import "../../Utils/Json.vim" as j
import "./Position.vim" as p
import "../../Utils/Str.vim" as s

export class TextDocumentPosition implements j.JsonSerializable
  var textDocument: any
  var position: any
  var defCol: number

  def new(server: any, bId: number, this.defCol = v:none)
    this.textDocument = ti.TextDocumentIdentifier.new(bId)
    var line = line(".", bufwinid(bId))
    var ltext = getline(line)
    var column = this.defCol == 0 ? col(".", bufwinid(bId)) : this.defCol
    this.position = p.Position.new(server, line, column)
  enddef

  def ToJson(): dict<any>
    return {
       textDocument: this.textDocument.ToJson(),
       position: this.position.ToJson()
    }
  enddef

  def VimDecode(bId: number): void
    this.position.VimDecode(bId)
  enddef

  def ServerEncode()
    this.position.ServerEncode()
  enddef
endclass
