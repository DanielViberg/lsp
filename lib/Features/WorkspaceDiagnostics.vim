vim9script

import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if
import "./Diagnostics.vim" as diag
import "../ClientState/Abstract/Server.vim" as srv
import "../ClientState/Buffer.vim" as b
import "../ClientState/Session.vim" as ses
import "../Protocol/Requests/WorkspaceDiagnostic.vim" as wd
import "../Rpc/Rpc.vim" as r
import "../Utils/Str.vim" as s

var workspaceCheck = 0
var workspaceQuickfix = 0
var workspacePending: list<srv.Server> = []
var workspaceCompleted: list<srv.Server> = []
var workspaceFailures = 0
var workspaceTimer = -1

export class WorkspaceDiagnostics extends ft.Feature implements if.IFeature

  var workspaceReports: dict<dict<any>> = {}

  def new()
    this.AutoCmds()
  enddef

  def AutoCmds()
  enddef

  def ServerPreStop(): void
    this.workspaceReports = {}
    for server in workspacePending->copy()
      if server.workspaceDiagnostics is this
        WorkspaceFinished(server, workspaceCheck, false)
      endif
    endfor
  enddef

  def ProcessRequest(server: any, data: any): void
  enddef

  def ProcessNotification(server: any, data: any): void
  enddef

  def RequestWorkspaceDiagnostics(server: any, check: number): void
    var previous: list<dict<any>> = []
    for uri in this.workspaceReports->keys()->sort()
      var report = this.workspaceReports[uri]
      if report->has_key('resultId')
        previous->add({uri: uri, value: report.resultId})
      endif
    endfor
    var provider = server.serverCapabilites.diagnosticProvider
    var request = wd.WorkspaceDiagnostic.new(previous, provider->get('identifier', ''))
    r.RpcAsync(server, request, function(this.WorkspaceDiagnosticsResponse, [check]))
  enddef

  def WorkspaceDiagnosticsResponse(check: number, server: any, reply: dict<any>): void
    if check != workspaceCheck || index(workspacePending, server) == -1
      return
    endif

    var result = reply->get('result', {})
    if reply->has_key('error') || type(result) != v:t_dict ||
        type(result->get('items', 0)) != v:t_list
      WorkspaceFinished(server, check, false)
      return
    endif

    # Only reports with a result ID can be reused by an incremental response.
    var reports = this.workspaceReports->deepcopy()
    reports->filter((_, report) => report->has_key('resultId'))
    for report in result.items
      if report.kind == 'full'
        reports[report.uri] = report->deepcopy()
      elseif report.kind == 'unchanged' && reports->has_key(report.uri)
        reports[report.uri].resultId = report.resultId
      else
        WorkspaceFinished(server, check, false)
        return
      endif
    endfor
    this.workspaceReports = reports
    WorkspaceFinished(server, check, true)
  enddef

  def WorkspaceQuickfixItems(server: any): list<dict<any>>
    var items: list<dict<any>> = []
    var encoding = server.serverCapabilites->get('positionEncoding', 'utf-16')
    for uri in this.workspaceReports->keys()->sort()
      if uri !~? '^file://'
        continue
      endif
      var report = this.workspaceReports[uri]
      if report.items->empty()
        continue
      endif
      var path = s.FromFileUri(uri)
      var buffers = b.GetBuffersByPath(path)
      var lines: list<string> = []
      if !buffers->empty()
        lines = getbufline(buffers[0], 1, '$')
      elseif filereadable(path)
        try
          lines = readfile(path)
        catch /^Vim\%((\a\+)\)\=:E484:/
          # The file may have been removed while diagnostics were running.
        endtry
      endif
      var displayPath = WorkspaceDisplayPath(path, server.rootUri)
      for diagnostic in report.items
        var severity = diagnostic->get('severity', diag.ERROR)
        if severity < diag.ERROR || severity > diag.HINT
          severity = diag.ERROR
        endif
        var position = diagnostic.range.start
        items->add({
          filename: path,
          lnum: position.line + 1,
          col: DiagnosticColumn(lines, position, encoding),
          type: ['E', 'W', 'I', 'N'][severity - 1],
          text: diagnostic.message->substitute('[\r\n\t]\+', ' ', 'g')->trim(),
          user_data: {
            path: displayPath,
            severity: ['error', 'warning', 'information', 'hint'][severity - 1]
          }
        })
      endfor
    endfor
    return items
  enddef

endclass

export def DiagnosticsCmd(): void
  if !workspacePending->empty() && getqflist({id: workspaceQuickfix}).id == workspaceQuickfix
    setqflist([], 'a', {id: workspaceQuickfix, title: 'LSP diagnostics (cancelled)'})
  endif
  workspaceCheck += 1
  if workspaceTimer != -1
    timer_stop(workspaceTimer)
    workspaceTimer = -1
  endif
  workspacePending = []
  workspaceCompleted = []
  workspaceFailures = 0
  workspaceQuickfix = 0

  for buf in getbufinfo({buflisted: 1})
    if buf.name->empty() || getbufvar(buf.bufnr, '&buftype') != ''
      continue
    endif
    for server in ses.GetSessionServersByBuf(buf.bufnr)
      if index(workspacePending, server) != -1 || !server.IsReady() || !server.isFeatInit
        continue
      endif
      var provider = server.serverCapabilites->get('diagnosticProvider', {})
      if type(provider) == v:t_dict && provider->get('workspaceDiagnostics', false)
        workspacePending->add(server)
      endif
    endfor
  endfor

  if workspacePending->empty()
    echomsg 'LSP: No workspace diagnostic servers for open buffers.'
    return
  endif

  setqflist([], ' ', {
    title: 'LSP diagnostics (checking...)',
    items: [],
    quickfixtextfunc: function(WorkspaceQuickfixText)
  })
  workspaceQuickfix = getqflist({id: 0}).id
  copen
  workspaceTimer = timer_start(120000, function(WorkspaceTimeout, [workspaceCheck]))
  for server in workspacePending->copy()
    server.workspaceDiagnostics.RequestWorkspaceDiagnostics(server, workspaceCheck)
  endfor
enddef

def WorkspaceFinished(server: any, check: number, success: bool): void
  var pendingIndex = index(workspacePending, server)
  if check != workspaceCheck || pendingIndex == -1
    return
  endif
  workspacePending->remove(pendingIndex)
  if success
    workspaceCompleted->add(server)
  else
    workspaceFailures += 1
  endif
  UpdateWorkspaceQuickfix()
enddef

def WorkspaceTimeout(check: number, _timer: number): void
  if check != workspaceCheck
    return
  endif
  workspaceFailures += workspacePending->len()
  workspacePending = []
  UpdateWorkspaceQuickfix()
enddef

def UpdateWorkspaceQuickfix(): void
  var items: list<dict<any>> = []
  for server in workspaceCompleted
    items->extend(server.workspaceDiagnostics.WorkspaceQuickfixItems(server))
  endfor
  items->sort((left, right) => {
    if left.filename !=# right.filename
      return left.filename <# right.filename ? -1 : 1
    endif
    if left.lnum != right.lnum
      return left.lnum - right.lnum
    endif
    if left.col != right.col
      return left.col - right.col
    endif
    return left.text ==# right.text ? 0 : (left.text <# right.text ? -1 : 1)
  })

  var title = 'LSP diagnostics'
  if !workspacePending->empty()
    title ..= ' (checking...)'
  elseif workspaceFailures > 0
    title ..= ' (incomplete)'
  endif
  if getqflist({id: workspaceQuickfix}).id == workspaceQuickfix
    setqflist([], 'r', {id: workspaceQuickfix, title: title, items: items})
  endif

  if workspacePending->empty()
    timer_stop(workspaceTimer)
    workspaceTimer = -1
    if workspaceFailures > 0
      echomsg printf('LSP: Workspace diagnostics incomplete (%d failed or timed-out servers).', workspaceFailures)
    elseif items->empty()
      echomsg 'LSP: No diagnostics found.'
    endif
  endif
enddef

def WorkspaceDisplayPath(path: string, rootUri: string): string
  var displayPath = path->substitute('\\', '/', 'g')
  if !rootUri->empty()
    var root = s.FromFileUri(rootUri)->substitute('\\', '/', 'g')->substitute('/$', '', '') .. '/'
    var prefix = strpart(displayPath, 0, strlen(root))
    if &fileignorecase ? prefix ==? root : prefix ==# root
      displayPath = strpart(displayPath, strlen(root))
    endif
  endif
  return pathshorten(displayPath)
enddef

def DiagnosticColumn(lines: list<string>, position: dict<any>, encoding: string): number
  var text = lines->get(position.line, '')
  var column = encoding == 'utf-8'
    ? min([strlen(text), position.character])
    : byteidxcomp(text, position.character, encoding != 'utf-32')
  return (column < 0 ? strlen(text) : column) + 1
enddef

def WorkspaceQuickfixText(info: dict<any>): list<string>
  var items = getqflist({id: info.id, items: 1}).items
  var lines: list<string> = []
  for item in items[info.start_idx - 1 : info.end_idx - 1]
    lines->add(printf('"%s" %s: %s (%d:%d)', item.user_data.path,
      item.user_data.severity, item.text, item.lnum, item.col))
  endfor
  return lines
enddef
