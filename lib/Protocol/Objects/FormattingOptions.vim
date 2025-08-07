vim9script

import "../../Utils/Json.vim" as j

export class FormattingOptions implements j.JsonSerializable

  # Size of a tab in spaces.
  var tabSize: number
  # Prefer spaces over tabs.
  var insertSpaces: bool
  # Trim trailing whitespace on a line.
  var trimTrailingWhitespaces: bool
  # Insert a newline character at the end of the file if one does not exist.
  var insertFinalNewline: bool
  # Trim all newlines after the final newline at the end of the file.
	var trimFinalNewlines: bool

  def new()
    this.tabSize = &tabstop
    this.insertSpaces = &expandtab
    this.trimTrailingWhitespaces = true
    this.insertFinalNewline = false
    this.trimFinalNewlines = true
  enddef

  def ToJson(): dict<any>
    return {
       tabSize: this.tabSize,
       insertSpaces: this.insertSpaces,
       trimTrailingWhitespaces: this.trimTrailingWhitespaces,
       insertFinalNewline: this.insertFinalNewline,
       trimFinalNewlines: this.trimFinalNewlines
    }
  enddef

endclass
