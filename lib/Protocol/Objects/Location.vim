vim9script

import "./Position.vim" as p
import "../../Utils/Str.vim" as s

export class Location
  var position: p.Position
  var uri: string
  
  def new(uri: string, pos: p.Position)
    this.position = pos
    this.uri = uri 
  enddef

  def GoTo(): void
    var path = s.FromFileUri(this.uri)
    var cur = expand('%:p')
    if has('win32') ? cur->tolower() != path->tolower()
                    : cur != path
      execute('edit ' .. fnameescape(path))
    endif

    cursor(this.position.line, this.position.character)
  enddef

endclass
