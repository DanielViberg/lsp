vim9script

import "../Abstracts/RequestMessage.vim" as req

export class CompletionResolve extends req.RequestMessage
  def new(item: any)
    this.method = "completionItem/resolve"
    this.params = item
  enddef
endclass
