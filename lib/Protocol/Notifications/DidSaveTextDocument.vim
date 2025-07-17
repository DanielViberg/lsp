vim9script

import "./Abstract/Notification.vim" as an

export class DidSaveTextDocument extends an.Notification

  def new(uri: string, text: string)
      this.method = "textDocument/didSave"
      this.params = {
        textDocument: uri,
        text: text
      }
  enddef

endclass
