vim9script

import "./Position.vim" as p
import "../../Utils/Str.vim" as s

export class Location
  var position: p.Position
  var uri: string
  
  def new(uri: string, pos: p.Position)
    this.position = pos
    this.uri = s.FromUri(uri) 
  enddef

  def GoTo(): void
    # Unopened buffer
    if expand('%:p') != fnamemodify(s.UrlDecode(this.uri), ':p')
      execute 'edit' s.UrlDecode(this.uri)
    endif

    # Same buffer
    cursor(this.position.line, this.position.character)
  enddef

endclass
