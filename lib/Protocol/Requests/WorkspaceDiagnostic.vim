vim9script

import "../Abstracts/RequestMessage.vim" as req

export class WorkspaceDiagnostic extends req.RequestMessage

  def new(previousResultIds: list<dict<any>>, identifier: string = '')
    this.method = 'workspace/diagnostic'
    this.params = {previousResultIds: previousResultIds}
    if !identifier->empty()
      this.params.identifier = identifier
    endif
  enddef

endclass
