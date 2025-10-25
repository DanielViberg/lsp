vim9script

import "./Abstract/Feature.vim" as ft
import "../ClientState/Server.vim" as srv
import "./Interfaces/IFeature.vim" as if
import "../ClientState/Buffer.vim" as b

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

      :highlight LError ctermfg=Red
      :highlight LIError ctermbg=Red
      :highlight LWarning ctermfg=Yellow
      :highlight LIWarning ctermbg=Yellow
      :highlight LInfo ctermfg=Blue
      :highlight LIInfo ctermbg=Blue
      :highlight LHint ctermfg=Magenta
      :highlight LIHint ctermbg=Magenta

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
      bufLines = len(getbufline(buf, 1, '$'))
      prop_clear(1, bufLines, {'bufnr': buf})
    endfor
  enddef

  def ProcessRequest(server: any, data: any): void 
  enddef

  def ProcessNotification(server: any, data: any): void 
    if has_key(data, 'method') && data.method == 'textDocument/publishDiagnostics'
			&& g:lsp_diagnostics
      this.PublishDiagnostics(data)
    endif
  enddef

  def PublishDiagnostics(data: any): void
    var buffers = b.GetBuffersByUri(data.params.uri)
    var bufLines: number
    for buf in buffers
      bufLines = len(getbufline(buf, 1, '$'))
      prop_clear(1, bufLines, {'bufnr': buf})
      sign_unplace('s_g', { buffer: buf })
      for diag in data.params.diagnostics

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
    endfor
  enddef
  
endclass
