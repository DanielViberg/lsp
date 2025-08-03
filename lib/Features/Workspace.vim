vim9script

import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if
import "../Protocol/Notifications/DidChangeConfiguration.vim" as dcc
import "../Rpc/Rpc.vim" as r

export class Workspace extends ft.Feature implements if.IFeature

  def new()
    this.AutoCmds()
  enddef

  def AutoCmds()

  enddef

  def ProcessRequest(data: any): void
    if has_key(data, 'method') && data.method == 'workspace/configuration'
    endif
  enddef

  def ProcessNotification(data: any)
  enddef

  def SendWorkspaceConfig(server: any, config: dict<any>)
    var notif = dcc.DidChangeConfiguration.new(config)
    r.RpcAsyncMes(server, notif)
  enddef

endclass
