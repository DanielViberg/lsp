vim9script

import "../../Utils/Json.vim" as j
import "../../Utils/Str.vim" as s

export class TextDocumentIdentifier implements j.JsonSerializable
  
  var uri: string = null_string

  def new(bId: number): void
    this.uri = s.Uri(expand('#' .. bId .. ':p'))
  enddef

  def ToJson(): dict<any>
    return {uri: this.uri}
  enddef

endclass
