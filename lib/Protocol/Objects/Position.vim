vim9script

import "../../Utils/Json.vim" as j
import "../../Utils/Str.vim" as s

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

  def VimDecode(): void
    this.line += 1
    var text = getline(this.line)
    if text->empty()
      return
    endif
    var enc = this.GetServerEncoding()
    var textLen = 0
    if enc == KIND_UTF16
      textLen = text->strutf16len(true)
    else
      textLen = text->strlen()
    endif

    if this.character > textLen
      this.character += 1
      return
    endif

    if this.character == textLen
      this.character = text->strchars()
    else
      if enc == KIND_UTF16
        this.character = s.Utf16ToUtf8ByteIdxWOComp(text, this.character)
      else
        this.character = text->charidx(this.character, true)
      endif
    endif
    this.character += 1
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
    var newChar: number = 0
    var enc = this.GetServerEncoding()
    if enc == KIND_UTF8
      newChar = s.Utf8ToUtf8WithComp(text, char)
    endif
    if enc == KIND_UTF16
      newChar = s.Utf8ToUtf16WithComp(text, char)
    endif
    if enc == KIND_UTF32
      newChar = s.Utf8ToUtf32WithComp(text, char)
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

endclass
