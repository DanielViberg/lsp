vim9script

import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if
import "../Protocol/Objects/TextDocumentPosition.vim" as tdp
import "../Protocol/Requests/Definition.vim" as def
import "../Rpc/Rpc.vim" as r
import "../Utils/Log.vim" as l
import "../Protocol/Objects/Position.vim" as p
import "../Protocol/Objects/Location.vim" as lo

var initOnce: bool = false

export class GoToDefinition extends ft.Feature implements if.IFeature

  def new()
    this.AutoCmds()
  enddef

  def AutoCmds()
    if !initOnce
      initOnce = true
      autocmd KeyInputPre * call ft.FeatAu(GoTo)
    endif
  enddef

  def ProcessRequest(server: any, data: any): void 
  enddef

  def ProcessNotification(server: any, data: any): void 
  enddef

endclass

def GoTo(server: any, bId: number, par: any): void
  if mode() == 'n' && 
    v:char == "\r" && # TODO: unhardcode this
    expand('<cword>') =~ '^\k\+$'
    var tdpos = tdp.TextDocumentPosition.new(server, bId)
    var dt = def.Definition.new(tdpos)
    r.RpcAsync(server, dt, GoToReply)
  endif
enddef

def GoToReply(server: any, reply: dict<any>)
  if reply->empty() || reply.result->empty()
    l.PrintWarning('Symbol definition not found')
    return
  endif
  var results = reply.result->copy()
  var locations: list<lo.Location>
  for loc in reply.result
    if has_key(loc, 'uri') && has_key(loc, 'range')
      var pos = p.Position.new(
        server, loc.range.start.line + 1, 
        loc.range.start.character + 1)  
      locations->add(lo.Location.new(loc.uri, pos))
    else
      l.PrintWarning('Null or LocationLink not supported')
      return
    endif
  endfor

  if locations->len() > 0
    locations[0].GoTo()
  endif

enddef

