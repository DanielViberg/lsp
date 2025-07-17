vim9script

import "./Abstract/Notification.vim" as an
import "../Objects/VersionedTextDocumentIdentifier.vim" as vtdi
import "../Objects/TextDocumentContentChangeEvent.vim" as tdcce

export class DocumentDidChange extends an.Notification
  
  def new(version: vtdi.VersionedTextDocumentIdentifier, 
          changes: list<tdcce.TextDocumentContentChangeEvent>)
    this.method = 'textDocument/didChange'
    this.params = {
      textDocument: version.ToJson(),
      contentChanges: changes->mapnew((_, c) => c.ToJson())
    }
  enddef

endclass
