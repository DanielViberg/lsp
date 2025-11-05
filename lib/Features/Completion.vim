vim9script

import "../ClientState/Server.vim" as s
import "../ClientState/Abstract/Server.vim" as abs
import "../ClientState/Session.vim" as ses
import "../ClientState/Buffer.vim" as b
import "../Utils/Str.vim" as str
import "../Utils/Log.vim" as l
import "../Rpc/Rpc.vim" as r
import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if
import "../Protocol/Requests/Completion.vim" as c
import "../Protocol/Requests/CompletionResolve.vim" as cr
import "../Protocol/Abstracts/RequestMessage.vim" as req
import "../Features/DocumentSync.vim" as d
import "../Protocol/Objects/Position.vim" as p
import "../Protocol/Objects/TextDocumentPosition.vim" as tdp
import "../Protocol/Objects/TextDocumentContentChangeEvent.vim" as tdce
import "../Utils/TextEdit.vim" as t
import "../../env.vim" as e

# Completion was triggered by typing an identifier (24x7 code
# complete), manual invocation (e.g Ctrl+Space) or via API.
const KIND_INVOKED = 1

# Completion was triggered by a trigger character specified by
# the `triggerCharacters` properties of the
# `CompletionRegistrationOptions`.
const KIND_CHARACTER = 2

# Completion was re-triggered as the current completion list is 
# incomplete.
const KIND_INCOMPLETE_COMPLETION = 3

export var bufferWords: list<string> = []
export var cacheWords: list<dict<any>> = []

var initOnce: bool = false
var isIncomplete: bool = false
var noServer: bool = false
var waiting: bool = false

export class Completion extends ft.Feature implements if.IFeature

  def new(ns: bool)
    noServer = ns
    this.AutoCmds()
  enddef

  def AutoCmds()
    if !initOnce
      initOnce = true
      set completeopt+=noinsert,noselect,menuone,popuphidden
      set shortmess+=cC
      inoremap <expr> <CR> pumvisible() ? PumCallback() : "\<CR>"
      autocmd CompleteChanged * call PumShowDoc()
      autocmd BufEnter * call CacheBufferWords()
      autocmd BufAdd * call CacheBufferWords()
      autocmd VimEnter * call CacheBufferWords()
      autocmd InsertLeave * call CacheBufferWords()
      autocmd InsertEnter * call CacheBufferWords()
      if noServer
        autocmd TextChangedI * call CompleteNoServer()
      endif
    endif
  enddef

  def ProcessRequest(server: abs.Server, data: any): void 
  enddef

  def ProcessNotification(server: abs.Server, data: any): void 
  enddef
  
  def ServerPreStop(): void
  enddef

  def RequestCompletion(server: abs.Server, bId: number): void 
		if !g:lsp_autocomplete
			return
		endif
    l.PrintDebug('Request completion')
    if mode() == 'i' || e.TESTING 
      var tdpos = tdp.TextDocumentPosition.new(server, bId)
      var compReq = c.Completion.new(
        this.GetTriggerKind(server, bId),
        str.GetTriggerChar(server.serverCapabilites.completionProvider.triggerCharacters),
        tdpos)
      waiting = true
      r.RpcAsync(server, compReq, RequestCompletionReply, bId)
    endif
    # Dont spam pum if using fast servers
    timer_start(400, (_) => {
      if waiting
        CompleteNoServer()
      endif
    })
  enddef

  def GetTriggerKind(server: abs.Server, bId: number): number
    # 1. Check current pum if its incomplete
    if false # TODO: isIncomplete not correctly handled
      return KIND_INCOMPLETE_COMPLETION
    endif
    
    var char = str.GetTriggerChar(server.serverCapabilites.completionProvider.triggerCharacters)
    if (index(server.serverCapabilites.completionProvider.triggerCharacters, char) != -1)
      return KIND_CHARACTER
    endif

    return KIND_INVOKED
  enddef

endclass

def PumShowDoc(): void
  var ci = v:event.completed_item
  if ci->has_key('user_data')
    ResolveCompletionDoc(ci.user_data.server_id, bufnr(), ci.user_data.item)
  endif
enddef

def RequestCompletionReply(server: abs.Server, reply: dict<any>, bId: any)
  waiting = false
  # TODO: handle itemDefaults
  if has_key(reply, 'result') && mode() == 'i'
    l.PrintDebug('Completion with result')
    var result = reply.result
    var items: list<any> = []

    if type(result) == v:t_dict && has_key(result, 'items')
      items = result.items
    elseif type(result) == v:t_list
      items = result
    endif

    l.PrintDebug('Completion lsp item count ' .. items->len())

    # Add buffer words
    var onlyBuffer = items->len() == 0
    items = items + GetCacheBufferW()

    l.PrintDebug('Completion item count ' .. items->len())

    var line = getline('.')
    var cursorCol = col('.') - 1
    var startCol = cursorCol - 1
    var endCol = startCol

    while startCol > 0 && endCol > 0 && line[endCol] =~ '[a-zA-Z0-9-_]' 
      endCol -= 1
    endwhile
    l.PrintDebug('Completion startCol:' .. startCol)
    l.PrintDebug('Completion endCol:' .. endCol)

    var word = trim(line[ endCol : startCol ])

    var query = substitute(word, '[^a-zA-Z0-9-_]', '', 'g')
    l.PrintDebug('Completion query ' .. word)
    
    # Compare query to items label w/o trigger char or additional space
    items->filter((_, v) => {
      if has_key(v, 'label') && type(v.label) == v:t_string
        var labelName = substitute(v.label, '[^a-zA-Z0-9-_]', '', 'g')
        if empty(query) && !v->has_key('is_buf')
          return true # Case: typed $ and is not a bufferComp
        endif
        return query == labelName[ : len(query) - 1] # Substring and same index
      else
        return false
      endif
    })

    l.PrintDebug('Completion items count after filter ' .. items->len())
    var compItems = items->map((_, i) => LspItemToCompItem(i, server.id))
    l.PrintDebug('Completion mode ' .. mode())
    cacheWords = compItems
    if mode() == 'i' 
      l.PrintDebug('Prompt completions')
      compItems->complete(col('.'))
    endif
  endif
enddef

def CompleteNoServer()
  if b.disable
    return
  endif
  var items: list<any> = GetCacheBufferW()
  var compItems = items->map((_, i) => LspItemToCompItem(i, -1))
  var match = complete_match()
  var [col, trigger] = match->len() > 0 ? match[0] : [null, null_string]
  if mode() == 'i' && strlen(trigger) > 0
    compItems->filter((_, v) => {
        var labelName = trim(v.word)
        return trigger == labelName[ : len(trigger) - 1]
    })
    compItems->complete(col('.'))
  endif
enddef

def CacheBufferWords(): void
  var lines = getbufline(bufnr(), 1, '$')
  for l in lines
    var words = split(l, '\W\+')
    for w in words
      if bufferWords->index(w) == -1 && # Dont already exists
         mode() != 'i' &&               # Check only finished words
         w =~# '[a-zA-Z]'               # Only letterWords
        bufferWords->add(w)
      endif
    endfor
  endfor
enddef

def GetCacheBufferW(): list<dict<any>>
  var comps: list<dict<any>> = []
  for w in bufferWords
    comps->add({
       label: w,
       is_buf: true,
    })
  endfor
  return comps
enddef

def LspItemToCompItem(item: dict<any>, sId: number): dict<any>
  var info: string = " "
  return {
    word: item.label, 
    kind: has_key(item, 'is_buf') ? '[buf]' : '[lsp]',
    dup: has_key(item, 'is_buf') ? 1 : 0,
    info: info,
    user_data: {
      item: item,
      server_id: sId
     }
  }
enddef

def PumCallback(): string
  var info = complete_info(['completed', 'selected'])
  l.PrintDebug("Pum callback: " .. json_encode(info))
  if has_key(info, 'completed') && 
     info.selected != -1 &&
     !noServer
    l.PrintDebug("Accept completion")
    timer_start(0, (_) => CompleteAccept(info.completed))
    return ""
  endif
  if noServer
    var comp = info->get('completed')
    var word = ""
    if !comp->empty() 
      word = comp->get("word")
    endif
    if !word->empty()
      timer_start(0, (_) => CompleteAcceptBuf(word))
      return ""
    else
      return "\n"
    endif
  else
    return "\n\n"
  endif
enddef

def CompleteAccept(ci: any): void
  if !ci->empty() && type(ci.user_data) == v:t_dict

    if ci.user_data.item->get('is_buf') || ci.user_data.item->has_key('insertText')
      var word = ci->get('word')
      if ci.user_data.item->has_key('insertText')
        word = ci.user_data.item.insertText
      endif
      CompleteAcceptBuf(word)
      return
    endif

    if !ci.user_data.item->has_key('additionalTextEdits')
      ResolveCompletion(ci.user_data.server_id, bufnr(), ci.user_data.item)
      return
    else 
      if has_key(ci.user_data.item, 'textEdit') && 
         ci.user_data.item.textEdit != null_dict
        l.PrintDebug("Process completion change")
        var server = ses.GetSessionServerById(ci.user_data.server_id)
        var changes: list<any> = []
        changes->add(tdce.TextDocumentContentChangeEvent.new(
          ci.user_data.item.textEdit.newText,
          ci.user_data.item.textEdit.range,
          server,
          true))
        if has_key(ci.user_data.item, 'additionalTextEdits')
          for edit in ci.user_data.item->get('additionalTextEdits')
            l.PrintDebug("Process additionalTextEdits")
            changes->add(tdce.TextDocumentContentChangeEvent.new(
              edit.newText,
              edit.range,
              server))
          endfor
        endif
        CompletionChange(changes, server)
        if ci.user_data.item->get('insertTextFormat') == 2
          server.snippet.Handle()
        endif
      else
        ResolveCompletion(ci.user_data.server_id, bufnr(), ci.user_data.item)
      endif
    endif
  endif
enddef

def ResolveCompletion(sid: number, buf: number, item: any): void
  l.PrintDebug("Resolve completion")
  var server = ses.GetSessionServerById(sid)
  if !server.serverCapabilites.completionProvider.resolveProvider
    return
  else
    var compRes = cr.CompletionResolve.new(item)
    r.RpcAsync(server, compRes, ResolveCompletionReply) 
  endif
enddef

def ResolveCompletionReply(server: abs.Server, reply: dict<any>): void
  var changes: list<any> = []
  if has_key(reply.result, 'textEdit') && reply.result.textEdit != null_dict
    l.PrintDebug("Process completion change")
    changes->add(tdce.TextDocumentContentChangeEvent.new(
      reply.result.textEdit.newText,
      reply.result.textEdit.range,
      server,
      true))
  endif

  if has_key(reply.result, 'additionalTextEdits')
    l.PrintDebug("Process additionalTextEdits")
    for edit in reply.result->get('additionalTextEdits')
      changes->add(tdce.TextDocumentContentChangeEvent.new(
        edit.newText,
        edit.range,
        server))
    endfor
  endif

  CompletionChange(changes, server)

  if changes->len() == 0
    CompleteAcceptBuf(reply.result.label)
  endif
enddef

def ResolveCompletionDoc(sid: number, buf: number, item: any): void
  l.PrintDebug("Resolve completion doc")
  var server = ses.GetSessionServerById(sid)

  if !server.isFeatInit
    return
  endif

  if !server.serverCapabilites.completionProvider.resolveProvider
    return
  else
    var compRes = cr.CompletionResolve.new(item)
    r.RpcAsync(server, compRes, ResolveCompletionDocReply) 
  endif
enddef

def ResolveCompletionDocReply(server: abs.Server, reply: dict<any>): void
  var id = popup_findinfo()
	if reply->has_key('result')
		var item = reply.result
		var info: list<string> = []
		if has_key(item, 'documentation')
			var doc = item.documentation
			if type(doc) == v:t_dict && has_key(doc, 'value')
				info = doc.value->split("\n")
			endif
		endif
		if id > 0 && info->len() > 0
			popup_settext(id, info)
			popup_show(id)
		endif
	endif
enddef


def CompleteAcceptBuf(word: string): void
  l.PrintDebug("Completion Accept Buf")
  var match = complete_match()
  var [_, trigger] = match->len() > 0 ? match[0] : [null, null_string]
  var lineText = getline(line('.'))
  var cursorIndex = col('.') - 1
  var compIndex = cursorIndex - trigger->len()
  var startIndex = compIndex <= 0 && cursorIndex == 0 ? 0 : compIndex
  var startText = startIndex == 0 ? '' : lineText[ : startIndex - 1]
  setline(line('.'), startText .. word .. lineText[ col('.') - 1 : ])
  cursor(line('.'), col('.') + len(word) - trigger->len())
enddef

def CompletionChange(changes: list<any>, server: any): void
  if changes->len() == 0
    return
  endif

  # FIXME: Vue server includes import even when it exists, filter out 
  # those additionalTextEdits
  changes->filter((_, ca) => {
    if ca.moveCursor
      return true
    endif
    return getline(1, '$')->indexof((_, line) => {
      return line .. "\n" == ca.text
    }) == -1
  })

  var cursorLineDelta = 0
  var newCol = 0
  for change in changes
    change.VimDecode(bufnr())
    if change.end.line < line('.')
      cursorLineDelta = change.text->split("\n")->len()
    endif
    if change.start.line == line('.')
      newCol = change.start.character + strlen(change.text) + 1
    endif
  endfor

  t.ApplyTextEdits(bufnr(), changes)
  cursor(line('.') + cursorLineDelta, newCol)
  
  d.DidChange(server, bufnr(), false)
enddef
