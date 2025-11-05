vim9script

import "../Abstracts/RequestMessage.vim" as req
import "../Objects/TextDocumentPosition.vim" as tdp
import "../Requests/Methods.vim" as met

export class Completion extends req.RequestMessage

  var context: dict<any> = {
     triggerKind: 1,
     triggerCharacter: null_string,
  }
  var textDocumentPosition: tdp.TextDocumentPosition
  var workDoneProgress: any
  var partialResult: any

  def new(kind: number, char: string, tp: tdp.TextDocumentPosition)
    this.context.triggerKind = kind
    this.context.triggerCharacter = char
    this.textDocumentPosition = tp
    this.method = met.COMPLETION
  enddef

  def ToJson(): dict<any>
    this.params = extend({
       context: this.context
    }, this.textDocumentPosition.ToJson())
    return super.ToJson()
  enddef

endclass
