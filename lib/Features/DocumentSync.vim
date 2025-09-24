vim9script

import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if
import "../ClientState/Buffer.vim" as b
import "../ClientState/Session.vim" as ses
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

var CachedBufferContent: dict<list<string>>
var initOnce: bool = false
var didOpenBuffers: list<number> = []

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
      autocmd BufEnter * ft.FeatAu(DidOpen)
      autocmd BufUnload * ft.FeatAu(DidClose)
      autocmd BufWritePre * ft.FeatAu(WillSave)
      autocmd BufWritePost * ft.FeatAu(DidSave)
      autocmd TextChangedI * ft.FeatAu(DidChange, true)
      autocmd TextChanged * ft.FeatAu(DidChange, true)
      autocmd TextChangedP * ft.FeatAu(DidChange, true)
    endif
  enddef


  def ProcessRequest(server: any, data: any): void 
  enddef

  def ProcessNotification(server: any, data: any): void 
  enddef
endclass


export def DidOpen(server: any, bId: number, par: any): void

  l.PrintDebug("Did open sid: " .. server.id .. " bId " .. bId )
  l.PrintDebug("Server is running: " .. server.isRunning)
  l.PrintDebug("Server is init: " .. server.isInit)
  l.PrintDebug("Server is featInit: " .. server.isFeatInit)

  if b.IsAFileBuffer() && index(didOpenBuffers, bId) == -1
    var didOpenNotif = ddo.DocumentDidOpen.new(s.Uri(expand('%:p')), server.fileType, bId)
    didOpenBuffers->append(bId)
    r.RpcAsyncMes(server, didOpenNotif)
    if GetSyncKind(server) == KIND_INC
      CachedBufferContent[bId] = bId->getbufline(1, '$')
    endif
  endif
enddef

export def DidClose(server: any, bId: number, par: any): void
  l.PrintDebug("Did close sid: " .. server.id .. " bId " .. bId )
  if index(didOpenBuffers, bId) != -1
    remove(didOpenBuffers, index(didOpenBuffers, bId))
    var didCloseNotif = ddcl.DocumentDidClose.new(s.Uri(expand('%:p')))
    r.RpcAsyncMes(server, didCloseNotif)
    if has_key(CachedBufferContent, bId)
      unlet CachedBufferContent[bId]
    endif
  endif
enddef

export def DidChange(server: any, bId: number, par: any): void
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

def GetSyncKind(server: any): number
  if type(server.serverCapabilites.textDocumentSync) == v:t_dict
    return server.serverCapabilites.textDocumentSync.change
  endif
  return server.serverCapabilites.textDocumentSync
enddef

export def WillSave(server: any, bId: number, par: any): void
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

export def DidSave(server: any, bId: number, par: any): void
  if !server.clientCapabilites.textDocument.synchronization.didSave
    return
  endif
  if has_key(server.serverCapabilites, 'textDocumentSync') &&
    type(server.serverCapabilites.textDocumentSync) == v:t_dict &&
      server.serverCapabilites.textDocumentSync.save
    var path = fnamemodify(bufname(bId), ':p')
    var ds = dstd.DidSaveTextDocument.new(s.Uri(path), join(getbufline(bId, 1, '$'), "\n"))
  endif
enddef
