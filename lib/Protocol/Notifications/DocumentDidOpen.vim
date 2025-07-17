vim9script

import "./Abstract/Notification.vim" as an

export class DocumentDidOpen extends an.Notification
  
  def new(uri: string, 
          languageId: string, 
          buffer: number)
          this.method = "textDocument/didOpen"
          this.params = {
            textDocument: {
              uri: uri,
              languageId: languageId,
              version: buffer->getbufvar('changedtick'),
              text: buffer->getbufline(1, '$')->join("\n") .. "\n"
            }
          }
  enddef

endclass
