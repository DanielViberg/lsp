vim9script

import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if
import "../Protocol/Requests/DocumentFormatting.vim" as df
import "../Rpc/Rpc.vim" as r
import "../Utils/TextEdit.vim" as te
import "../ClientState/Session.vim" as ses
import "../Protocol/Objects/TextDocumentContentChangeEvent.vim" as tdce
import "../Utils/Log.vim" as l

var initOnce: bool = false

export class Formatting extends ft.Feature implements if.IFeature

  def new()
    this.AutoCmds()
  enddef

  def AutoCmds()
    if initOnce
      return
    endif
    initOnce = true
    autocmd BufWritePre * ft.FeatAu(PreSave)
  enddef

  def ServerPreStop(): void
  enddef
  
  def ProcessRequest(server: any, data: any): void 
  enddef

  def ProcessNotification(server: any, data: any): void 
  enddef

endclass
  
def PreSave(server: any, bId: number, par: any): void
	if g:lsp_format_pre_save
		Format(server, bId)
	endif
  noautocmd write
enddef

export def FormatCmd(): void
  l.PrintDebug("Format cmd triggered")
  var servers = ses.GetSessionServersByBuf(bufnr())
  if servers->len() > 0
    Format(servers[0], bufnr())
  endif
enddef

def Format(server: any, bId: number): void
  var docFor = df.DocumentFormatting.new(bId)
  if has_key(server.serverCapabilites, 'documentFormattingProvider') &&
      server.serverCapabilites.documentFormattingProvider
    var reply = r.RpcSync(server, docFor)
    if has_key(reply, 'result') && reply.result != null
      l.PrintDebug("Format response")
      var changes: list<tdce.TextDocumentContentChangeEvent>
      for r in reply.result
        var change = tdce.TextDocumentContentChangeEvent.new(r.newText, r.range, server)
        change.VimDecode(bId)
        changes->add(change)
      endfor
      te.ApplyTextEdits(bId, changes) 
    endif
  endif
enddef

