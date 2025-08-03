vim9scrip

import "./Abstract/Notification.vim" as an

export class DidChangeConfiguration extends an.Notification
  def new(config: dict<any>)
    this.method = "workspace/didChangeConfiguration"
    this.params = {
       settings: config
    }
  enddef
endclass
