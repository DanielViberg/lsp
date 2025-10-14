vim9script

import "./Message.vim" as mes

var reqVer: number = 0

export abstract class RequestMessage extends mes.Message

  var id: number
  var params: dict<any>

  def GetRequestId(): number
    return reqVer
  enddef 

  def ToJson(): dict<any>
    reqVer += 1
    this.id = reqVer
    return extend(super.ToJson(), {
      id: this.id,
      method: this.method,
      params: this.params
    })
  enddef

endclass
