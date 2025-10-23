vim9script

import "../Protocol/Abstracts/RequestMessage.vim" as rm
import "../ClientState/Abstract/Server.vim" as serv
import "../ClientState/Session.vim" as ses
import "../Protocol/Abstracts/Message.vim" as mes
import "../Utils/Log.vim" as l
import "../../env.vim" as e

export var serverReqNrState: dict<any> = {}

export def RpcSync(server: serv.Server, req: rm.RequestMessage): any
  server.userMiddleware.PreRequest(server, req)
  return server.job->ch_evalexpr(req.ToJson())
enddef

export def RpcAsyncMes(server: serv.Server, notif: mes.Message)
  l.PrintDebug('Notification ' .. notif.method)
  server.job->ch_sendexpr(notif.ToJson())
enddef

export def RpcAsync(server: serv.Server, req: rm.RequestMessage, Cb: func)
  l.PrintDebug('Request ' .. req.method)

  if !has_key(serverReqNrState, server.id)
    serverReqNrState[server.id] = 1
  elseif req.resetClientReqNr 
    serverReqNrState[server.id] = 1
  else
    serverReqNrState[server.id] += 1
  endif

  req.id = serverReqNrState[server.id]

  l.PrintDebug('Request state nr ' .. req.id)

  var Fn = function('RpcAsyncCb', [server, Cb, req.onlyLatest])
  server.job->ch_sendexpr(req.ToJson(), {callback: Fn})
enddef

def RpcAsyncCb(server: serv.Server, RpcCb: func, needLatest: bool, chan: channel, reply: dict<any>)
  var sName = has_key(server.config, 'name') ? server.config.name : ''
  if has_key(reply, 'error')
    l.PrintError('(' .. sName .. ') ' .. string(reply.error.message))
  endif

  l.PrintDebug('Response client state nr ' .. serverReqNrState[server.id])
  l.PrintDebug('Response server state nr ' .. reply.id)

  if needLatest && reply.id < serverReqNrState[server.id]
    return
  endif

  RpcCb(server, reply)
enddef

export def RpcOutCb(server: serv.Server, chan: channel, msg: any): void
  var sName = has_key(server.config, 'name') ? server.config.name : ''
  
  if has_key(msg, 'error')
    l.PrintError('(' .. sName .. ') ' .. string(msg.error.message))
  endif
  
  if has_key(msg, 'params') 
    if type(msg.params) == v:t_dict && has_key(msg.params, 'type') && msg.params.type == 1
      l.PrintError('(' .. sName .. ') ' .. string(msg.params.message))
    endif
  endif

  if msg->has_key('id') && msg->has_key('method')
    server.ProcessRequest(msg)
  elseif msg->has_key('method')
    server.ProcessNotification(msg)
  endif
enddef

export def RpcErrorCb(s: any, chan: channel, emsg: string)
  l.Log(l.Type.Error, emsg)
enddef

export def RpcExitCb(s: any, job: job, status: number)
  s.isRunning = false
enddef
