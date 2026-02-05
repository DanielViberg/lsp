vim9script

import "./Config.vim" as conf
import "./Session.vim" as ses
import "./Server.vim" as ser
import "../Utils/Str.vim" as str
import "../Utils/Log.vim" as l
import "../Features/Completion.vim" as c

export var disable: bool = false
export var isQuickFix: bool = false

autocmd QuickFixCmdPre * isQuickFix = true
autocmd QuickFixCmdPost * isQuickFix = false

export class Buffer
  def new()

    if !IsAFileBuffer(bufnr()) || disable || isQuickFix
      l.PrintDebug('Not a file buffer, disabled or a quickfix')
      return
    endif

    l.PrintDebug('New buffer')
    conf.Init()

    var ft = expand('%:e')
    l.PrintDebug('Filetype ' .. ft)

    var conServerIds = conf.GetConfigServerIdsByFt(ft)
    l.PrintDebug('Configured servers ' .. conServerIds->join(' '))

    if conServerIds->len() == 0 && ses.SessionServers->len() == 0
      l.PrintDebug('No servers, start buff comp')
      var comp = c.Completion.new(true)
    else
      var sesServersIds = ses.GetSessionServerIdsByFt(ft)
      l.PrintDebug('Session servers ' .. sesServersIds->join(' '))

      var newServerIds = conServerIds->filter((_, i) => index(sesServersIds, i) < 0)
      l.PrintDebug('New servers ' .. newServerIds->join(' '))

      var bId = bufnr()
      for nsi in newServerIds
        l.PrintDebug('New server ' .. nsi)
        var s = ser.Server.new(nsi, ft)
        ses.SetSessionServer(s)
        s.Init(bId)
      endfor
    endif
  enddef
endclass

export def IsAFileBuffer(bId: number): bool
  return filereadable(expand('#' .. bId .. ':p'))
enddef 

export def GetBuffersByPath(path: string): list<number>
    return getbufinfo({ buflisted: 1, bufloaded: 1})
      ->filter((_, buf) => buf.name == path)
      ->map((_, buf) => buf.bufnr)
enddef
