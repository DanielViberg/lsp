vim9script

import "../ClientState/Server.vim" as s
import "../ClientState/Session.vim" as ses
import "../Utils/Str.vim" as str
import "../Utils/Log.vim" as l
import "../Rpc/Rpc.vim" as r
import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if
import "../Protocol/Requests/Completion.vim" as c
import "../Protocol/Requests/CompletionResolve.vim" as cr
import "../Features/DocumentSync.vim" as d
import "../Protocol/Objects/Position.vim" as p
import "../Protocol/Objects/TextDocumentPosition.vim" as tdp
import "../Protocol/Objects/TextDocumentContentChangeEvent.vim" as tdce

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

var initOnce: bool = false
var isIncomplete: bool = false
var bufferWords: list<string> = []

export class Completion extends ft.Feature implements if.IFeature

  def new()
    this.AutoCmds()
  enddef

  def AutoCmds()
    if !initOnce
      initOnce = true
      set completeopt+=noinsert,menuone,popup
      inoremap <expr> <CR> pumvisible() ? PumCallback() : "\<CR>"
      inoremap <expr> <Up> pumvisible() ? PumShowDoc("\<Up>") : "\<Up>"
      inoremap <expr> <Down> pumvisible() ? PumShowDoc("\<Down>") : "\<Down>"
      autocmd TextChangedI * call CheckEmptyLineForPUM()
      autocmd BufEnter * call CacheBufferWords()
      CacheBufferWords()
    endif
  enddef

  def ProcessRequest(data: any): void 
  enddef

  def ProcessNotification(data: any): void 
  enddef

  def RequestCompletion(server: any, bId: number): void 
    if mode() == 'i' 
      []->complete(col(".")) # Pum list is sometimes outdated
      var tdpos = tdp.TextDocumentPosition.new(server, bId)
      var compReq = c.Completion.new(
        this.GetTriggerKind(server, bId),
        str.GetTriggerChar(server.serverCapabilites.completionProvider.triggerCharacters),
        tdpos)
      r.RpcAsync(server, compReq, RequestCompletionReply)
    endif
  enddef

  def GetTriggerKind(server: any, bId: number): number
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

def PumShowDoc(key: string): string
  var info = complete_info(['completed'])
  return key
enddef

def CheckEmptyLineForPUM()
  if getline('.') =~ '^\s*$'
    set completeopt+=noselect
  else
    set completeopt-=noselect
  endif
enddef

def RequestCompletionReply(server: any, reply: dict<any>)
  # TODO: handle itemDefaults
  if has_key(reply, 'result')
    l.PrintDebug('Completion with result')
    var result = reply.result
    if result == null
      return
    endif
    var items = type(result) == v:t_dict && 
                has_key(result, 'items') ? result.items : result
    if items->len() > 0
      if type(result) == v:t_dict
        isIncomplete = result.isIncomplete
      endif
      l.PrintDebug('Completion item count ' .. items->len())
      # Get trigger char before the word, or '\s'
      var tc = str.GetTriggerCharIdx(
        server.serverCapabilites.completionProvider.triggerCharacters,
        line('.'),
        col('.')
      )
      var query = getline(line('.'))[tc.col : col('.') - 2]
      l.PrintDebug('Completion query ' .. query)
      
      # Add buffer words
      items = items + GetCacheBufferW()

      # Compare query to items label w/o trigger char or additional space
      items->filter((_, v) => {
        if has_key(v, 'label') && type(v.label) == v:t_string
          var labelName = trim(v.label)
          if server.serverCapabilites.completionProvider.triggerCharacters->index(labelName[0]) != -1
            labelName = labelName[1 : ]
          endif
          if empty(query)
            return true # Case: typed $
          endif
          return tolower(query) == tolower(labelName[ : len(query) - 1]) # Substring and same index
        else
          return false
        endif
      })
      l.PrintDebug('Completion items count after filer ' .. items->len())
      var compItems = items->map((_, i) => LspItemToCompItem(i, server.id))
      if mode() == 'i'
        compItems->complete(col("."))
      endif
    endif
  endif
enddef

def CacheBufferWords(): void
  var lines = getbufline(bufnr(), 1, '$')
  for l in lines
    var words = split(l, '\W\+')
    for w in words
      if bufferWords->index(w) == -1
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
  var info: string = ''
  if has_key(item, 'documentation')
    var doc = item.documentation
    if type(doc) == v:t_dict && has_key(doc, 'value')
      info = doc.value
    endif
  endif
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
  if has_key(info, 'completed') && info.selected != -1
    timer_start(0, (_) => CompleteAccept(info.completed))
    return ""
  endif
  return "\n\n"
enddef

def CompleteAccept(ci: any): void
  if !ci->empty() && type(ci.user_data) == v:t_dict
    if has_key(ci.user_data.item, 'textEdit') && 
       ci.user_data.item.textEdit != null_dict
      var server = ses.GetSessionServerById(ci.user_data.server_id)
      var change = tdce.TextDocumentContentChangeEvent.new(
        ci.user_data.item.textEdit.newText,
        ci.user_data.item.textEdit.range,
        server) 
      change.VimDecode()
      change.ApplyChange()
    else
      ResolveCompletion(ci.user_data.server_id, bufnr(), ci.user_data.item)
    endif
  endif
enddef

def ResolveCompletion(sid: number, buf: number, item: any): void
  var server = ses.GetSessionServerById(sid)
  if !server.serverCapabilites.completionProvider.resolveProvider
    return
  else
    var compRes = cr.CompletionResolve.new(item)
    r.RpcAsync(server, compRes, ResolveCompletionReply) 
  endif
enddef

def ResolveCompletionReply(server: any, reply: dict<any>): void
  if has_key(reply.result, 'textEdit') && reply.result.textEdit != null_dict
    var change = tdce.TextDocumentContentChangeEvent.new(
      reply.result.textEdit.newText,
      reply.result.textEdit.range,
      server)
    change.VimDecode()
    change.ApplyChange()
  elseif has_key(reply.result, 'label')
    var tc = str.GetTriggerCharIdx(
      server.serverCapabilites.completionProvider.triggerCharacters,
      line('.'),
      col('.')
    )
    var query = getline(line('.'))[tc.col : col('.') - 2]
    var lineText = getline(line('.'))
    var start = col('.') - query->len() - 2 <= 0 ? 0 : col('.') - 2 - query->len()
    var startText = start == 0 ? '' : lineText[ : start]
    setline(line('.'), startText .. reply.result.label .. lineText[ col('.') - 1 : ])
    cursor(line('.'), col('.') + len(reply.result.label) - query->len())
  endif
enddef
