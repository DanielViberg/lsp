vim9script

import "../../Utils/Log.vim" as l

export abstract class Server

  public var isRunning: bool = false
  public var isInit: bool = false
  public var isFeatInit: bool = false
  public var job: job = null_job
  public var config: dict<any> = null_dict
  public var serverCapabilites: dict<any> = null_dict
  public var clientCapabilites: dict<any> = null_dict
  public var fileType: string = null_string

  var id: number = -1

  var documentSync: any
  var workspace: any
  var diagnostics: any
  var completion: any
  var snippet: any
  var formatting: any
  var goToDefinition: any
  var userMiddleware: any

  def ProcessRequest(data: any): void 
    l.PrintDebug('Server request ' .. data)

    if !this.isFeatInit
      l.PrintInfo('Features not init')
      return
    endif

    this.documentSync.ProcessRequest(this, data)
    this.workspace.ProcessRequest(this, data)
    this.diagnostics.ProcessRequest(this, data)
    if has_key(this.serverCapabilites, 'completionProvider')
      this.completion.ProcessRequest(this, data)
    endif
    this.formatting.ProcessRequest(this, data)
    this.goToDefinition.ProcessRequest(this, data)

    this.userMiddleware.ProcessRequest(this, data)
  enddef

  def ProcessNotification(data: any): void 
    l.PrintDebug('Server notification ' .. data)

    if data.method == 'window/logMessage'
      l.PrintInfo(data.params.message)
    endif

    if !this.isFeatInit
      l.PrintInfo('Features not init')
      return
    endif

    this.documentSync.ProcessNotification(this, data)
    this.workspace.ProcessNotification(this, data)
    this.diagnostics.ProcessNotification(this, data)
    if has_key(this.serverCapabilites, 'completionProvider')
      this.completion.ProcessNotification(this, data)
    endif
    this.formatting.ProcessNotification(this, data)
    this.goToDefinition.ProcessNotification(this, data)
  enddef

  def PostDidChange(bId: number): void
    l.PrintDebug('Post did change')
    if !this.isFeatInit
      return
    endif

    if has_key(this.serverCapabilites, 'completionProvider')
      this.completion.RequestCompletion(this, bId)
    endif
  enddef

endclass
