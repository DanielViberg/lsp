vim9script

import "../../ClientState/Server.vim" as ser
import "../../ClientState/Session.vim" as ses
import "../../Utils/Log.vim" as l

export abstract class Feature 
endclass

export def FeatAu(Featcmd: func, par = v:none): void
  var bId = expand('<abuf>')->str2nr()
  if !bufloaded(bId)
    return
  endif
  var servers = ses.GetSessionServersByBuf(bId)
  for server in servers
    if !server.isRunning || !server.isInit
      l.PrintDebug('Server ' .. server.id .. ' not ready')
      return
    endif
      Featcmd(server, bId, par)
  endfor 
enddef
