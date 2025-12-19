vim9script

import "./Abstract/Notification.vim" as an
import "../Objects/TextDocumentIdentifier.vim" as tdi

export class DidSaveTextDocument extends an.Notification

  def new(t: tdi.TextDocumentIdentifier, text: string)
      this.method = "textDocument/didSave"
      this.params = {
        textDocument: t.ToJson(),
        text: text
      }
  enddef

endclass
