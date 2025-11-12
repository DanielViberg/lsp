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
var reqNr: number = 0

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
      l.PrintDebug('COMPREQ: ' .. json_encode(compReq.ToJson()))
      waiting = true
      reqNr += 1
      r.RpcAsync(server, compReq, RequestCompletionReply, reqNr)
    endif
    # Dont spam pum if using fast servers
    timer_start(400, (_) => {
      if waiting
        CompleteNoServer()
      endif
    })
  enddef

  def GetTriggerKind(server: abs.Server, bId: number): number
    if isIncomplete 
      return KIND_INCOMPLETE_COMPLETION
    endif
    
    var char = str.GetTriggerChar(server.serverCapabilites.completionProvider.triggerCharacters)
    if (index(server.serverCapabilites.completionProvider.triggerCharacters, char) != -1)
      l.PrintDebug('Trigger kind char')
      return KIND_CHARACTER
    endif

      l.PrintDebug('Trigger kind invoked')
    return KIND_INVOKED
  enddef

endclass

def PumShowDoc(): void
  var ci = v:event.completed_item
  if ci->has_key('user_data')
    ResolveCompletionDoc(ci.user_data.server_id, bufnr(), ci.user_data.item)
  endif
enddef

def RequestCompletionReply(server: abs.Server, reply: dict<any>, sreqNr: any)
  waiting = false

  # Skip intermediat requests
  if sreqNr < reqNr
    return
  endif

  l.PrintDebug('Triggers: ' .. json_encode(server.serverCapabilites.completionProvider.triggerCharacters))

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

    var lspItemCount = items->len()

    # Add buffer words
    var onlyBuffer = items->len() == 0
    items = items + GetCacheBufferW()

    l.PrintDebug('Completion item count ' .. items->len())

    var line = getline('.')
    var cursorCol = col('.') - 1
    var startCol = cursorCol - 1
    var endCol = startCol
    var wordChar: string = '[-]\?\(\d*\.\d\w*\|\w\+\|\$\+\)'

    while startCol > 0 && endCol > 0
      endCol -= 1
      if !(line[endCol] =~ wordChar)
        endCol += 1
        break
      endif
    endwhile

    l.PrintDebug('Completion startCol:' .. startCol)
    l.PrintDebug('Completion endCol:' .. endCol)

    var word = trim(line[ endCol : startCol ])
    var query = word
    l.PrintDebug('Completion query ' .. query)

    # Lsp dont want completion triggered
    if empty(query) && lspItemCount == 0
      return
    endif
    
    items->map((_, v) => {
        if v->get('sortText')->empty() 
          v.sortText = v.label
        endif
        if v->get('filterText')->empty()
          v.filterText = v.label
        endif
        return v
      })
    ->filter((_, v) => {
        # Ignore buffer words when query is empty
        if empty(query) && v->get('is_buf')
          return false
        endif
        # Let lsp completion list if query is trigger char
        if server.serverCapabilites.completionProvider.triggerCharacters->index(query) != -1 && 
          !v->get('is_buf')
          return true
        endif
        return v.filterText != query && query == v.filterText[ : len(query) - 1]
    })
    ->sort((_a, _b) => {
        if _a->get('is_buf') && !_b->get('is_buf')
          return 1
        elseif !_a->get('is_buf') && _b->get('is_buf')
          return -1
        else
          return _a->get('sortText') == _b->get('sortText') ? 0 : 
            (_a->get('sortText') >? _b->get('sortText') ? 1 : -1) 
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
    var words = split(l, '\v[^a-zA-Z0-9_-]+')
    for w in words
      if bufferWords->index(w) == -1 && # Dont already exists
         mode() != 'i' &&               # Check only finished words
         w =~# '[a-zA-Z]'               # Only letterWords
        if g:lsp_comp_buf_cache_limit == bufferWords->len()
          bufferWords->remove(0)
        endif
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
       filterText: w,
       sortText: 0
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

    if has_key(ci.user_data.item, 'textEdit') && 
       ci.user_data.item.textEdit != null_dict
      l.PrintDebug("Process completion change")
      var server = ses.GetSessionServerById(ci.user_data.server_id)
      var changes: list<any> = []
      var newText = ci.user_data.item.textEdit.newText
      var range: any = {}

      if ci.user_data.item.textEdit->has_key('insert')
        l.PrintDebug("Process completion insert")
        range = ci.user_data.item.textEdit.insert
      elseif ci.user_data.item.textEdit->has_key('range')
        l.PrintDebug("Process completion range")
        range = ci.user_data.item.textEdit.range
      endif

      changes->add(tdce.TextDocumentContentChangeEvent.new(
        newText,
        range,
        server,
        true))

      if has_key(ci.user_data.item, 'additionalTextEdits')
        for edit in ci.user_data.item->get('additionalTextEdits')
          l.PrintDebug("Process additionalTextEdits")
          var anewText = edit.newText
          var arange: any = {}

          if edit->has_key('insert')
            arange = edit.insert
          elseif edit->has_key('range')
            arange = edit.range
          endif

          changes->add(tdce.TextDocumentContentChangeEvent.new(
            anewText,
            arange,
            server))

        endfor
      endif
      CompletionChange(changes, server)

      if ci.user_data.item->get('insertTextFormat') == 2
        server.snippet.Handle()
      endif

      if !has_key(ci.user_data.item, 'additionalTextEdits')
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
    var reply = r.RpcSync(server, compRes) 
    ResolveCompletionReply(server, reply)
  endif
enddef

def ResolveCompletionReply(server: abs.Server, reply: dict<any>): void
  var changes: list<any> = []
  if has_key(reply.result, 'additionalTextEdits')
    for edit in reply.result->get('additionalTextEdits')
      var anewText = edit.newText
      var arange: any = {}

      if edit->has_key('insert')
        arange = edit.insert
      elseif edit->has_key('range')
        arange = edit.range
      endif

      changes->add(tdce.TextDocumentContentChangeEvent.new(
        anewText,
        arange,
        server))
    endfor
  endif
  CompletionChange(changes, server)
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

  l.PrintDebug('Apply Text Edits')
  t.ApplyTextEdits(bufnr(), changes)
  cursor(line('.') + cursorLineDelta, newCol)
  
  d.DidChange(server, bufnr(), false)
enddef
