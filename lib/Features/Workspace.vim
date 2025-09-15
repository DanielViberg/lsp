vim9script

import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if
import "../Protocol/Notifications/DidChangeConfiguration.vim" as dcc
import "../Rpc/Rpc.vim" as r
import "../ClientState/Config.vim" as c
import "../Protocol/Abstracts/ResponseMessage.vim" as res

export class Workspace extends ft.Feature implements if.IFeature

  def new()
    this.AutoCmds()
  enddef

  def AutoCmds()
  enddef

  def ProcessRequest(server: any, data: any): void
    if has_key(data, 'method') && data.method == 'workspace/configuration'
      var items = data.params.items->map((_, item) => c.GetConfigItem(server, item))

      # Server expect null value if no config is given
      if items->type() == v:t_list && items->len() == 1
        && items[0]->type() == v:t_dict
        && items[0] == null_dict
        items[0] = null
      endif

      var response = res.ResponseMessage.new(data, items)
      r.RpcAsyncMes(server, response)
    endif
  enddef

  def ProcessNotification(server: any, data: any)
  enddef

  def SendWorkspaceConfig(server: any, config: dict<any>)
    var notif = dcc.DidChangeConfiguration.new(config)
    r.RpcAsyncMes(server, notif)
  enddef

endclass
