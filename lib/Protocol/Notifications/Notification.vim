vim9script

import "../Abstracts/Message.vim" as mes

export const INITIALIZED = 'initialized'
export const EXIT = 'exit'

export class Notification extends mes.Message

  var method: string
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

