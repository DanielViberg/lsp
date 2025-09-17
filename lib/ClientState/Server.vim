vim9script

import "../Features/Diagnostics.vim" as diag
import "../Features/Completion.vim" as comp
import "../Features/Snippet.vim" as sn
import "../Features/Formatting.vim" as for
import "../Features/Workspace.vim" as w
import "../Features/GoToDefinition.vim" as gtd
import "../Features/DocumentSync.vim" as dc
import "../Protocol/Notifications/Notification.vim" as notif
import "../Protocol/Requests/Initialize.vim" as reqI
import "../Protocol/Requests/Shutdown.vim" as reqSu
import "../ClientState/Config.vim" as c
import "../Protocol/Config/cc.vim" as cap
import "../Rpc/Rpc.vim" as r
import "../Utils/Str.vim" as str
import "../Utils/Log.vim" as l

const currentDir = expand('<sfile>')

export class Server 
  
  public var isRunning: bool = false
  public var isInit: bool = false
  public var isFeatInit: bool = false
  public var isWaiting: bool = false
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

  def new(this.id = v:none, this.fileType = v:none)
    l.PrintDebug('New server')
    if this.id != null
      this.config = c.GetConfigServerById(this.id)
      this.clientCapabilites = cap.CC
    endif
  enddef

  def Init(bnr = v:none): void
    l.PrintDebug('Init server')
    if this.isInit
      l.PrintDebug('Already init')
      return
    endif

    var opts = { in_mode: 'lsp',
		             out_mode: 'lsp',
		             err_mode: 'raw',
		             noblock: 1,
                 out_cb: function(r.RpcOutCb, [this]),
		             err_cb: function(r.RpcErrorCb, [this]),
                 exit_cb: function(r.RpcExitCb, [this])}

    if !executable(this.config.path)
      l.PrintError("Binary for " .. this.config.path .. " is missing")
      return
    endif

    var cmd = [this.config.path]
    if has_key(this.config, 'args')
      cmd->extend(this.config.args)
    endif
    this.job = cmd->job_start(opts)

    this.isRunning = true

    var initReq = reqI.Initialize.new(this.config)
    r.RpcAsync(this, initReq, this.InitResponse)
    l.PrintInfo("Server " .. get(this.config, 'name') .. " init")
  enddef

  def InitResponse(server: Server, reply: dict<any>): void
    server.isInit = true
    server.serverCapabilites = reply.result.capabilities
    r.RpcAsyncMes(server, notif.Notification.new('initialized'))
    server.InitFeat()
  enddef

  def InitFeat(): void
    this.documentSync = dc.DocumentSync.new()
    this.workspace = w.Workspace.new()
    this.diagnostics = diag.Diagnostics.new()
    if has_key(this.serverCapabilites, 'completionProvider')
      this.completion = comp.Completion.new(false)
    endif
    this.snippet = sn.Snippet.new()
    this.formatting = for.Formatting.new()
    this.goToDefinition = gtd.GoToDefinition.new()
    this.isFeatInit = true
    l.PrintDebug('Ready and do open')
    dc.DidOpen(this, bufnr(), null)
    this.workspace.SendWorkspaceConfig(this, this.config->get('workspaceConfig', null_dict))
  enddef
  
  def ProcessRequest(data: any): void 
    if !this.isFeatInit
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
  enddef

  def ProcessNotification(data: any): void 
    if !this.isFeatInit
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

  def Stop(): void
    this.isRunning = false
    r.RpcAsync(this, reqSu.Shutdown.new(), this.StopResponse)
  enddef

  def StopResponse(server: Server, reply: dict<any>): void
    r.RpcAsyncMes(server, notif.Notification.new('exit'))
    if server.job->job_status() == 'run'
      server.job->job_stop()
    endif
    server.isRunning = false
  enddef

  def Kill(): void
    r.RpcAsyncMes(this, notif.Notification.new('exit'))
  enddef

  def IsReady(): bool 
    return this.isInit && 
      this.isRunning && 
      this.job->job_status() == 'run'
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


