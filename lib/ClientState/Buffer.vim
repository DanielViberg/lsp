vim9script

import "./Config.vim" as conf
import "./Session.vim" as ses
import "./Server.vim" as ser
import "../Utils/Str.vim" as str
import "../Utils/Log.vim" as l

export class Buffer
  def new()
    l.PrintDebug('New buffer')
    conf.Init()
  
    if !IsAFileBuffer()
      l.PrintDebug('Not a file buffer')
      return
    endif

    var ft = expand('%:e')
    l.PrintDebug('Filetype ' .. ft)

    var conServerIds = conf.GetConfigServerIdsByFt(ft)
    l.PrintDebug('Configured servers ' .. conServerIds->join(' '))
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

  enddef
endclass

export def IsAFileBuffer(): bool
  return filereadable(expand('%:p'))
enddef 

export def GetBuffersByUri(uri: string): list<number>
    return getbufinfo()->filter((_, buf) => str.Uri(buf.name) ==# uri)->map((_, buf) => buf.bufnr)
enddef
