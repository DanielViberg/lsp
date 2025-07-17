vim9script

import "../../Abstracts/Message.vim" as mes

export abstract class Notification extends mes.Message

  var method: string
  var params: dict<any>

  def ToJson(): dict<any>
    return extend(super.ToJson(), {
      method: this.method,
      params: this.params
    })
  enddef

endclass
