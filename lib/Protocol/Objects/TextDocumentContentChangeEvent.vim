vim9script

import "../../Utils/Json.vim" as j
import "../../Utils/Str.vim" as s
import "../../ClientState/Session.vim" as ses
import "../../Protocol/Objects/Position.vim" as p

export class TextDocumentContentChangeEvent implements j.JsonSerializable
  
  var start: p.Position
  var end: p.Position
  var text: string = null_string
  var server: any = null
  var defined: bool = false
  var moveCursor: bool = false

  def new(text: string, range: dict<any>, this.server = v:none, this.moveCursor = v:none) 
    this.text = text
    if range != null_dict
      this.start = p.Position.new(this.server, range.start.line, range.start.character)
      this.end = p.Position.new(this.server, range.end.line, range.end.character)
      this.defined = true
    endif
  enddef

  def ToJson(): dict<any>
    var range = null_dict
    if this.defined
      return {
         text: this.text,
         range: {
          start: this.start.ToJson(),
          end: this.end.ToJson()
         }
      }
    else
      return {
        text: this.text
      }
    endif
  enddef

  def ClearSnippet(): void
    this.text = substitute(this.text, '\$\d\+', '', 'g')
  enddef

  def VimDecode(bId: number): void
    this.start.VimDecode(bId)
    this.end.VimDecode(bId)
  enddef
endclass
