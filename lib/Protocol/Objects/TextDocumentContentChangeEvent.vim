vim9script

import "../../Utils/Json.vim" as j
import "../../Utils/Str.vim" as s
import "../../ClientState/Session.vim" as ses
import "../../Protocol/Objects/Position.vim" as p
import "../../Features/DocumentSync.vim" as ds

export class TextDocumentContentChangeEvent implements j.JsonSerializable
  
  var start: p.Position
  var end: p.Position
  var text: string = null_string
  var server: any = null
  var defined: bool = false

  def new(text: string, range: dict<any>, this.server = v:none) 
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

  def VimDecode(): void
    this.text = this.text
    this.start.VimDecode()
    this.end.VimDecode()
  enddef

  def ApplyChange(): void 
    if pumvisible()
      []->complete(col('.'))
    endif

    var triggerChars = this.server.serverCapabilites.completionProvider.triggerCharacters
    var text = substitute(join(split(this.text, '\n'), ''), '[\t\\]', '', 'g') 
    var line = this.start.line
    var col = this.start.character
    var end = this.end.character
    var lineText = getline(line)

    var textBefore = col > 1 ? lineText[ : col - 2] : ''
    # Must be one line according to spec
    var newText = textBefore .. substitute(join(split(text, '\n'), ''), '\\', '', 'g') .. lineText[end - 1 : ]
    setline(line, newText)

    # Remove and place cursor at ${0} or $0
    var matchPos = match(getline(line), '\${\w\+\}\|\$\d\+')
    if matchPos >= 0
      execute 'normal! :s/\${\w\+}\|\$\d\+//g' .. "\<CR>"
      cursor(line, matchPos + 1)
    else
      cursor(line, col + len(text))
    endif
    
    ds.DidChange(this.server, bufnr(), false)  
  enddef

  def ApplyChangeByLines(clearTrail: bool)
    if empty(trim(this.text))
      return
    endif
    var lines = split(this.text, '\n')
    if clearTrail
      deletebufline(bufnr(), this.start.line + len(lines), '$')
    endif
    setline(this.start.line, lines)
  enddef
endclass
