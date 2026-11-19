vim9script

import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if

# https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#snippet_syntax

const marker = 'lsp_snippet_stop'
var initialized = false

def Clear()
  if exists('b:lsp_snippet_index')
    prop_remove({type: marker, all: true})
    unlet b:lsp_snippet_index b:lsp_snippet_final
  endif
enddef

def LeftEditing(buf: number, _: number)
  # Moving into Select mode briefly passes through Normal mode too.
  if bufnr() == buf && mode() =~# '^n'
    Clear()
  endif
enddef

def MarkPos(id: number): list<number>
  var mark = prop_find({type: marker, id: id, both: true, lnum: 1, col: 1}, 'f')
  return empty(mark) ? [] : [mark.lnum, mark.col]
enddef

def Select(first: list<number>, last: list<number>)
  cursor(first)
  normal! v
  cursor(last)
  execute "normal! \<C-G>"
enddef

def Next()
  while exists('b:lsp_snippet_index')
    var index = b:lsp_snippet_index
    b:lsp_snippet_index += 2
    var first = MarkPos(index)
    var last = MarkPos(index + 1)
    if index == b:lsp_snippet_final
      Clear()
    endif
    if empty(first) || empty(last)
      continue
    endif
    cursor(first)
    if first != last
      # Select mode replaces the whole default on the next typed character.
      if &selection != 'exclusive'
        var endByte = line2byte(last[0]) + last[1] - 2
        var row = byte2line(endByte)
        last = [row, endByte - line2byte(row) + 1]
      endif
      var cmd = $"\<C-\>\<C-N>\<Cmd>call {expand('<SID>')}Select({first}, {last})\<CR>"
      feedkeys(cmd, 'in')
    endif
    return
  endwhile
enddef

def JumpKey(): string
  return exists('b:lsp_snippet_index') ? "\<Plug>(lsp-snippet-next)" : "\<Tab>"
enddef

export class Snippet extends ft.Feature implements if.IFeature
  def new()
    this.AutoCmds()
  enddef

  def AutoCmds()
    if initialized
      return
    endif
    initialized = true
    prop_type_add(marker, {})
    inoremap <silent> <Plug>(lsp-snippet-next) <Cmd>call <SID>Next()<CR>
    snoremap <silent> <Plug>(lsp-snippet-next) <Esc>i<Cmd>call <SID>Next()<CR>
    if empty(maparg('<Tab>', 'i'))
      inoremap <expr> <Tab> JumpKey()
    endif
    if empty(maparg('<Tab>', 's'))
      snoremap <expr> <Tab> JumpKey()
    endif
    autocmd BufLeave * call Clear()
    autocmd ModeChanged *:n if exists('b:lsp_snippet_index') | timer_start(0, function(LeftEditing, [bufnr()])) | endif
  enddef

  def ServerPreStop(): void
  enddef

  def ProcessRequest(server: any, data: any): void 
  enddef

  def ProcessNotification(server: any, data: any): void 
  enddef

  def Handle(parsed: dict<any>, endpoint: list<number>)
    Clear()
    # The endpoint already includes additional edits. Map snippet-relative byte
    # offsets back into this buffer, including newlines, using that endpoint.
    var lines = split(parsed.text, "\n", true)
    var firstRow = endpoint[0] - len(lines) + 1
    var firstCol = len(lines) == 1 ? endpoint[1] - strlen(parsed.text) : 0
    if len(lines) > 1
      firstCol = strlen(getline(firstRow)) - strlen(lines[0]) + 1
    endif
    var id = 1
    for stop in parsed.stops
      for offset in stop
        var prefix = split(strpart(parsed.text, 0, offset), "\n", true)
        var row = firstRow + len(prefix) - 1
        var column = strlen(prefix[-1]) + (row == firstRow ? firstCol : 1)
        prop_add(row, column, {type: marker, id: id})
        id += 1
      endfor
    endfor
    b:lsp_snippet_index = 1
    b:lsp_snippet_final = id - 2
    Next()
  enddef
endclass
