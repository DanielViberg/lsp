vim9script

import "./Server.vim" as ser
import "../Utils/Log.vim" as l

var SessionServers: list<ser.Server> = null_list

export def SetSessionServer(server: ser.Server): void
  l.PrintDebug('Adding server: ' .. server.id .. ' to session')
  SessionServers->add(server)
enddef

export def GetSessionServerById(id: number): ser.Server
  for s in SessionServers
    if s.id == id
      return s
    endif
  endfor
  return ser.Server.new()
enddef

export def GetSessionServersByFt(ft: string): list<ser.Server>
  var servers: list<ser.Server> = []
  for s in SessionServers
    if s.fileType == ft
      servers->add(s)
    endif
  endfor
  return servers
enddef

export def GetSessionServersByBuf(bufnr: number): list<ser.Server>
  var ft = getbufvar(bufnr, '&filetype')
  return GetSessionServersByFt(ft)
enddef

export def GetSessionServerIdsByFt(ft: string): list<number>
  return SessionServers->copy()->filter((_, s) => s.fileType == ft)
                      ->mapnew((_, s) => s.id)
                      ->filter((_, i) => !empty(i))
enddef
