vim9script

import "./Message.vim" as mes

export class ResponseMessage extends mes.Message
  var id: number
  var result: any
  var error: number

  def new(request: any, result: any)
    if (request.id->type() == v:t_string
    && (request.id->trim() =~ '[^[:digit:]]\+'
        || request.id->trim()->empty()))
      || (request.id->type() != v:t_string && request.id->type() != v:t_number)
      return
    endif
    this.id = request.id
    this.result = result
  enddef

  def ToJson(): dict<any>
    return extend(super.ToJson(), {
       id: this.id,
       result: this.result,
       error: this.error
    })
  enddef
endclass
