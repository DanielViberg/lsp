vim9script

import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if
import "../Utils/Log.vim" as l
import "../Protocol/Objects/TextDocumentPosition.vim" as tdp
import "../ClientState/Session.vim" as ses
import "../Protocol/Requests/Hover.vim" as h
import "../Rpc/Rpc.vim" as r

export class Hover extends ft.Feature implements if.IFeature
  def new()
    this.AutoCmds()
  enddef

  def AutoCmds()
  enddef

  def ServerPreStop(): void
  enddef

  def ProcessRequest(server: any, data: any): void 
  enddef

  def ProcessNotification(server: any, data: any): void 
  enddef

  def Handle()
  enddef
endclass

export def HoverCmd(): void 
  l.PrintDebug('Hover cmd trigger')
  var bId = bufnr()
  var servers = ses.GetSessionServersByBuf(bId)
  if servers->len() > 0
    var tdpos = tdp.TextDocumentPosition.new(servers[0], bId)
    var hov = h.Hover.new(tdpos)
    var reply = r.RpcSync(servers[0], hov)
    if reply->has_key('result')
      var result = reply.result
      if (type(result) == v:t_dict && result->has_key('contents'))
        var info = result.contents.value->split('\n')
        popup_atcursor(info, {
          pos: 'topleft'
        })
      endif
    endif
  endif
enddef
