vim9script

import "./Abstract/Notification.vim" as an

export class DocumentDidClose extends an.Notification

  def new(uri: string)
      this.method = "textDocument/didClose"
      this.params = {
        textDocument: {
          uri: uri,
          version: 0
        }
      }
  enddef

endclass
