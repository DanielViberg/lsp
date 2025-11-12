vim9script

import "./Message.vim" as mes

export abstract class RequestMessage extends mes.Message

  public var id: number
  var params: dict<any>
  var resetClientReqNr: bool = false

  def ToJson(): dict<any>
    return extend(super.ToJson(), {
      id: 0,
      method: this.method,
      params: this.params
    })
  enddef

endclass
