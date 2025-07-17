vim9script

import "./Message.vim" as mes
import "../Error/ResponseError.vim" as err

export class ResponseMessage extends mes.Message
  var id: number
  var result: any
  var error: err.ResponseError
endclass
