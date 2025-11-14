vim9script

import "./Abstract/Feature.vim" as ft
import "../ClientState/Server.vim" as srv
import "./Interfaces/IFeature.vim" as if
import "../ClientState/Buffer.vim" as b
import "../Protocol/Requests/Diagnostic.vim" as d
import "../Protocol/Objects/TextDocumentIdentifier.vim" as tdi
import "../Rpc/Rpc.vim" as r
import "../Utils/Log.vim" as l
import "../Utils/Str.vim" as s

var initOnce = false

export const ERROR       = 1
export const WARNING     = 2
export const INFORMATION = 3
export const HINT        = 4

export class Diagnostics extends ft.Feature implements if.IFeature

  def new()
    this.AutoCmds()
    if !initOnce
      initOnce = true

      :highlight LError ctermfg=Red guifg=#cf4c4c
      :highlight LIError ctermbg=Red guifg=#ecb55d
      :highlight LWarning ctermfg=Yellow guifg=#ecb55d
      :highlight LIWarning ctermbg=Yellow guifg=#ecb55d
      :highlight LInfo ctermfg=Blue guifg=#3465a4
      :highlight LIInfo ctermbg=Blue guifg=#3465a4
      :highlight LHint ctermfg=Magenta guifg=#c061cb
      :highlight LIHint ctermbg=Magenta guifg=#c061cb

	    call prop_type_add('error', {'highlight': 'LError'})
	    call prop_type_add('errorI', {'highlight': 'LIError'})
	    call prop_type_add('warning', {'highlight': 'LWarning'})
	    call prop_type_add('warningI', {'highlight': 'LIWarning'})
	    call prop_type_add('info', {'highlight': 'LInfo'})
	    call prop_type_add('infoI', {'highlight': 'LIInfo'})
	    call prop_type_add('hint', {'highlight': 'LHint'})
	    call prop_type_add('hintI', {'highlight': 'LIHint'})

      call sign_define([
      {
        name: 's_error',
        text: '▶',
        texthl: 'LError',
      },
      {
        name: 's_warning',
        text: '■',
        texthl: 'LWarning',
      },
      {
        name: 's_info',
        text: '●',
        texthl: 'LInfo',
      },
      {
        name: 's_hint',
        text: '◆',
        texthl: 'LHint',
      }
      ])
    endif
  enddef

  def AutoCmds()
  enddef
  
  def ServerPreStop(): void
    var bufLines: number
    for buf in getbufinfo({ buflisted: 1, bufloaded: 1})
      bufLines = len(getbufline(buf.bufnr, 1, '$'))
      prop_clear(1, bufLines, {'bufnr': buf.bufnr})
    endfor
  enddef

  def ProcessRequest(server: any, data: any): void 
  enddef

  def ProcessNotification(server: any, data: any): void 
    if has_key(data, 'method') && data.method == 'textDocument/publishDiagnostics'
			&& g:lsp_diagnostics
      this.PushDiagnostics(data)
    endif
  enddef

  def PushDiagnostics(data: any): void
    var buffers = b.GetBuffersByPath(s.UrlDecode(s.FromUri(data.params.uri)))
    for buf in buffers
      this.PublishDiagnostics(buf, data.params.diagnostics)
    endfor
  enddef

  def RequestDiagnostics(server: any, bId: number): void
    l.PrintDebug('Request diagnostics')
    var td = tdi.TextDocumentIdentifier.new(bId)
    var diag = d.Diagnostic.new(td) 
    r.RpcAsync(server, diag, this.RequestDiagnosticsResponse, bId)
  enddef

  def RequestDiagnosticsResponse(server: any, reply: dict<any>, bId: number)
    l.PrintDebug('Response diagnostics')
    this.PublishDiagnostics(bId, reply.result.items)
  enddef

  def PublishDiagnostics(buf: number, diagnostics: list<dict<any>>)
    var bufLines = len(getbufline(buf, 1, '$'))
    prop_clear(1, bufLines, {'bufnr': buf})
    sign_unplace('s_g', { buffer: buf })
    for diag in diagnostics
      var type = 'info'
      var uni = ''

      if diag.severity == ERROR
        type = 'error'
        uni = '◀'
      endif

      if diag.severity == WARNING
        type = 'warning'
        uni = '■'
      endif

      if diag.severity == INFORMATION
        type = 'info'
        uni = '●'
      endif

      if diag.severity == HINT
        type = 'hint'
        uni = '◆'
      endif

      var line = diag.range.start.line + 1
      if line > bufLines
        line = bufLines
      endif

      if diag.message->len() > 0 && 
         line > 0 && line <= bufLines &&
         buf->bufloaded()
       prop_add(line, 0, {
          type: type,
          bufnr: buf,
          text: uni .. ' ' .. diag.message,
          text_align: 'after',
          text_wrap: 'wrap',
          text_padding_left: 2
       })
       call sign_place(1, 's_g', 's_' .. type, buf, {lnum: line})
      endif
    endfor
  enddef

endclass
