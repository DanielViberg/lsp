vim9script

import "./TextDocumentIdentifier.vim" as ti
import "../../Utils/Json.vim" as j
import "./Position.vim" as p
import "../../Utils/Str.vim" as s

export class TextDocumentPosition implements j.JsonSerializable
  var textDocument: any
  var position: any

  def new(server: any, bId: number)
    this.textDocument = ti.TextDocumentIdentifier.new(bId)
    var line = line(".", bufwinid(bId))
    var ltext = getline(line)
    var column = col(".", bufwinid(bId))
    this.position = p.Position.new(server, line, column - 1)
  enddef

  def ToJson(): dict<any>
    return {
       textDocument: this.textDocument.ToJson(),
       position: this.position.ToJson()
    }
  enddef

  def VimDecode()
    this.position.VimDecode()
  enddef

  def ServerEncode()
    this.position.ServerEncode()
  enddef
endclass
