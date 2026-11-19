vim9script

import "../../Utils/Json.vim" as j
import "../../Utils/Log.vim" as l

const KIND_UTF8  = 'utf-8'
const KIND_UTF16 = 'utf-16'
const KIND_UTF32 = 'utf-32'

export class Position implements j.JsonSerializable
  var server: any

  # Line position in a document (zero-based).
  var line: number

  # Character offset on a line in a document (zero-based). The meaning of this
	# offset is determined by the negotiated `PositionEncodingKind`.
	# If the character value is greater than the line length it defaults back
	# to the line length.
  var character: number

  def new(server: any, line: number, char: number)
    this.server = server
    this.line = line
    this.character = char
  enddef

  def ToJson(): dict<any>
    return this.ServerEncode()
  enddef

  def VimDecode(bId: number): void
    this.line += 1

    # When on the first character, nothing to do.
    if this.character <= 0
      return
    endif

    # Need a loaded buffer to read the line and compute the offset
    :silent! bId->bufload()

    var ltext: string = bId->getbufline(this.line)->get(0, '')
    var enc = this.GetServerEncoding()
    var offset = enc == KIND_UTF8 ? this.character
        : byteidxcomp(ltext, this.character, enc == KIND_UTF16)
    this.character = offset < 0 ? strlen(ltext) : min([offset, strlen(ltext)])
  enddef

  # 1. Subract 1 char, then calculate byte offset
  def ServerEncode(): dict<any>
    var text = getline(this.line)
    var line = this.line - 1
    var char = this.character - 1
    if text->empty()
      return {
         line: line,
         character: 0
      }
    endif
    var prefix = strpart(text, 0, char)
    var newChar = strlen(prefix)
    var enc = this.GetServerEncoding()
    if enc == KIND_UTF16
      newChar = strutf16len(prefix, true)
    elseif enc == KIND_UTF32
      newChar = strchars(prefix)
    endif
    return {
       line: line,
       character: newChar
    }
  enddef

  def GetServerEncoding(): string
    if this.server.serverCapabilites->has_key('positionEncoding')
      return this.server.serverCapabilites.positionEncoding
    else
      return KIND_UTF16
    endif
  enddef

  def Equals(p: Position): bool
    return this.line == p.line &&
           this.character == p.character
  enddef

endclass
