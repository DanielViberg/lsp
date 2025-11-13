vim9script

import "./Message.vim" as mes

var reqNr: number = 1

export abstract class RequestMessage extends mes.Message

  public var id: number
  var params: dict<any>

  def ToJson(): dict<any>
    reqNr += 1
    this.id = reqNr
    return extend(super.ToJson(), {
      id: this.id,
      method: this.method,
      params: this.params
    })
  enddef

endclass
