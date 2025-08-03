vim9script

import "../Abstracts/Message.vim" as mes

export class Notification extends mes.Message

  var params: dict<any>

  def new(method: string)
    this.method = method
  enddef

  def ToJson(): dict<any>
    return extend(super.ToJson(), {
      method: this.method,
      params: this.params
    })
  enddef

endclass

