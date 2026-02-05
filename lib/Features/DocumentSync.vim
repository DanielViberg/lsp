vim9script

import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if
import "../ClientState/Buffer.vim" as b
import "../ClientState/Session.vim" as ses
import "../ClientState/Abstract/Server.vim" as abs
import "../Rpc/Rpc.vim" as r
import "../Utils/Str.vim" as s
import "../Utils/Log.vim" as l
import "../ClientState/Server.vim" as ser
import "../Protocol/Notifications/DocumentDidOpen.vim" as ddo
import "../Protocol/Notifications/DocumentDidChange.vim" as ddc
import "../Protocol/Notifications/DocumentDidClose.vim" as ddcl
import "../Protocol/Notifications/WillSaveTextDocument.vim" as wstd
import "../Protocol/Notifications/DidSaveTextDocument.vim" as dstd
import "../Protocol/Objects/VersionedTextDocumentIdentifier.vim" as vtdi
import "../Protocol/Objects/TextDocumentContentChangeEvent.vim" as tdcce
import "../Protocol/Objects/TextDocumentPosition.vim" as tdp
import "../Protocol/Objects/TextDocumentIdentifier.vim" as tdi

var CachedBufferContent: dict<list<string>>
var initOnce: bool = false
var didOpenFiles: list<string> = []
var isQuickFix: bool = false

const KIND_NONE = 0
const KIND_FULL = 1
const KIND_INC  = 2
  
export class DocumentSync extends ft.Feature implements if.IFeature

  def new()
    this.AutoCmds()
  enddef

  def AutoCmds()
    if !initOnce
      initOnce = true
      autocmd BufReadPost * ft.FeatAu(DidOpen)
      autocmd QuickFixCmdPre * isQuickFix = true
      autocmd QuickFixCmdPost * isQuickFix = false
      autocmd BufWipeout,BufUnload * ft.FeatAu(DidClose)
      autocmd BufWritePre * ft.FeatAu(WillSave)
      autocmd BufWritePost * ft.FeatAu(DidSave)

      var bIds = getbufinfo({buflisted: 1, bufloaded: 1})
      for buf in bIds
        var servers = ses.GetSessionServersByBuf(buf.bufnr)
        for server in servers
          while !server.isRunning || !server.isInit
            l.PrintDebug('Waiting to send DidOpen for server: ' .. server.id)
            sleep 1
          endwhile
          DidOpen(server, buf.bufnr, true)
        endfor 
      endfor

    endif
  enddef
  
  def ServerPreStop(): void
  enddef

  def ProcessRequest(server: abs.Server, data: any): void 
  enddef

  def ProcessNotification(server: abs.Server, data: any): void 
  enddef
endclass


export def DidOpen(server: abs.Server, bId: number, par: any): void
  l.PrintDebug('Trying to open ' .. uri_encode(expand('#' .. bId .. ':p')))
  if isQuickFix
    l.PrintDebug('Is quickfix')
    return
  endif

  if !b.IsAFileBuffer(bId) || 
      index(didOpenFiles, uri_encode(expand('#' .. bId .. ':p'))) != -1
    l.PrintDebug('s:' .. server.id .. 'b:' .. bId .. ' not a buffer or already open')
    return
  endif

  didOpenFiles->add(uri_encode(expand('#' .. bId .. ':p')))

  listener_add((_bnr: number, start: number, end: number, added: number, changes: list<dict<number>>) => {
    DidChange(server, bId, true)
  }, bId)

  l.PrintDebug("Did open sid: " .. server.id .. " bId " .. bId )
  l.PrintDebug("Server is running: " .. server.isRunning)
  l.PrintDebug("Server is init: " .. server.isInit)
  l.PrintDebug("Server is featInit: " .. server.isFeatInit)
  var didOpenNotif = ddo.DocumentDidOpen.new(uri_encode(expand('#' .. bId .. ':p')), server.fileType, bId)
  r.RpcAsyncMes(server, didOpenNotif)
  if GetSyncKind(server) == KIND_INC
    l.PrintDebug("Cache buffer" .. bId)
    CachedBufferContent[bId] = bId->getbufline(1, '$')
  endif
enddef

export def DidClose(server: abs.Server, bId: number, par: any): void
  l.PrintDebug("Check close sid: " .. server.id .. " bId " .. bId )

  if index(didOpenFiles, uri_encode(expand('#' .. bId .. ':p'))) != -1 &&
      getbufinfo({bufloaded: 1})->filter((_, buf) => buf.name == expand('#' .. bId .. ':p'))->len() <= 1

    remove(didOpenFiles, index(didOpenFiles, uri_encode(expand('#' .. bId .. ':p'))))
    listener_remove(bId)
    l.PrintDebug("Did close sid: " .. server.id .. " bId " .. bId )
    var didCloseNotif = ddcl.DocumentDidClose.new(uri_encode(expand('%:p')))
    r.RpcAsyncMes(server, didCloseNotif)
    if has_key(CachedBufferContent, bId)
      unlet CachedBufferContent[bId]
    endif
  endif
enddef

export def DidChange(server: abs.Server, bId: number, par: any): void
  l.PrintDebug("Did change sid: " .. server.id .. " bId " .. bId )
  var changes: list<tdcce.TextDocumentContentChangeEvent>
  if GetSyncKind(server) == KIND_FULL
    changes->add(tdcce.TextDocumentContentChangeEvent.new(
      bId->getbufline(1, '$')->join("\n") .. "\n",
      null_dict,
      server
    ))
  endif

  if GetSyncKind(server) == KIND_INC
    var newBufState = bId->getbufline(1, '$')
    if has_key(CachedBufferContent, bId)
      var diffs = diff(CachedBufferContent[bId], newBufState, {output: 'indices'})
      if diffs->len() == 0
        return
      endif
      for hunk in diffs->reverse()
        var change = tdcce.TextDocumentContentChangeEvent.new(
            join(newBufState[hunk.to_idx : hunk.to_idx + hunk.to_count], "\n") .. "\n", 
            {
                start: {
                  line: hunk.from_idx + 1, # Current line
                  character: 1
                },
                end: {
                  line: hunk.from_idx + hunk.from_count + 2, # Start two lines town
                  character: 1
                }
            },
            server
        )
        changes->add(change)
      endfor
      CachedBufferContent[bId] = newBufState
    endif
  endif

  var ver = vtdi.VersionedTextDocumentIdentifier.new(bId)
  var ddcNotif = ddc.DocumentDidChange.new(ver, changes)
  r.RpcAsyncMes(server, ddcNotif)

  if par
    server.PostDidChange(bId)
  endif
enddef

def GetSyncKind(server: abs.Server): number
  if type(server.serverCapabilites.textDocumentSync) == v:t_dict
    return server.serverCapabilites.textDocumentSync.change
  endif
  return server.serverCapabilites.textDocumentSync
enddef

export def WillSave(server: abs.Server, bId: number, par: any): void
  if !server.clientCapabilites.textDocument.synchronization.willSave
    return
  endif
  if has_key(server.serverCapabilites, 'textDocumentSync') &&
    type(server.serverCapabilites.textDocumentSync) == v:t_dict
    if has_key(server.serverCapabilites.textDocumentSync, 'willSave') &&
      server.serverCapabilites.textDocumentSync.willSave
      var path = fnamemodify(bufname(bId), ':p')
      var ws = wstd.WillSaveTextDocument.new(s.Uri(path))
      r.RpcAsyncMes(server, ws)
    endif
  endif
enddef

export def DidSave(server: abs.Server, bId: number, par: any): void
  if !server.clientCapabilites.textDocument.synchronization.didSave
    return
  endif
  if has_key(server.serverCapabilites, 'textDocumentSync') &&
    type(server.serverCapabilites.textDocumentSync) == v:t_dict &&
      server.serverCapabilites.textDocumentSync->has_key('save')
    var path = fnamemodify(bufname(bId), ':p')
    var ds = dstd.DidSaveTextDocument.new(tdi.TextDocumentIdentifier.new(bId), join(getbufline(bId, 1, '$'), "\n"))
    r.RpcAsyncMes(server, ds)
  endif
enddef
