vim9script

import "./Abstract/Notification.vim" as an

export class WillSaveTextDocument extends an.Notification

  def new(uri: string)
      this.method = "textDocument/willSave"
      this.params = {
        textDocument: uri,
      }
  enddef

endclass
