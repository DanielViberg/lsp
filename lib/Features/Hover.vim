vim9script

import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if
import "../Utils/Log.vim" as l
import "../Protocol/Objects/TextDocumentPosition.vim" as tdp
import "../ClientState/Session.vim" as ses
import "../Protocol/Requests/Hover.vim" as h
import "../Rpc/Rpc.vim" as r

var initOnce: bool = false
var timer: number = 0
var autoHoverId: number = 0
export class Hover extends ft.Feature implements if.IFeature
  def new()
    this.AutoCmds()
  enddef

  def AutoCmds()
    if !initOnce
      initOnce = true
      echomsg 'init'
      autocmd TextChangedI * call AutoHover(false)
      autocmd CursorMoved * call AutoHover(true)
    endif
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

export def AutoHover(atCol: bool): void
  timer_stop(timer)
  timer = timer_start(1000, (_) => {
    popup_close(autoHoverId)
    var bId = bufnr()
    var servers = ses.GetSessionServersByBuf(bId)
    if servers->len() > 0
      var col = atCol ? col('.') : col('.') - 2
      var tdpos = tdp.TextDocumentPosition.new(servers[0], bId, col)
      var hov = h.Hover.new(tdpos)
      var reply = r.RpcSync(servers[0], hov)
      if reply->has_key('result')
        var result = reply.result
        if (type(result) == v:t_dict && result->has_key('contents'))
          var info = result.contents.value->substitute('\r\n', '\n', 'g')->split("\n")
          autoHoverId = popup_create(info, {
            line: 2, 
            col: &columns, 
            pos: 'topright', 
            maxwidth: &columns / 3, 
            padding: [1, 1, 1, 1]})
        endif
      endif
    endif
  })
enddef

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
        var info = result.contents.value->substitute('\r\n', '\n', 'g')->split("\n")
        popup_atcursor(info, {
          pos: 'topleft',
          padding: [0, 1, 0, 1],
          highlight: 'PopupSelected'
        })
      endif
    endif
  endif
enddef
