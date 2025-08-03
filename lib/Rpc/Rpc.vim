vim9script

import "../Protocol/Abstracts/RequestMessage.vim" as rm
import "../ClientState/Server.vim" as serv
import "../ClientState/Session.vim" as ses
import "../Protocol/Abstracts/Message.vim" as mes
import "../Utils/Log.vim" as l

export def RpcSync(job: job, req: rm.RequestMessage, Cb: func)
  #var reply = job->ch_evalexpr(req)
enddef

export def RpcAsyncMes(server: any, notif: mes.Message)
  l.PrintDebug('Notification ' .. notif.method)
  server.job->ch_sendexpr(notif.ToJson())
enddef

export def RpcAsync(server: any, req: rm.RequestMessage, Cb: func)
  l.PrintDebug('Request ' .. req.method)
  var Fn = function('RpcAsyncCb', [server, Cb])
  server.job->ch_sendexpr(req.ToJson(), {callback: Fn})
enddef

def RpcAsyncCb(server: any, RpcCb: func, chan: channel, reply: dict<any>)
  var sName = has_key(server.config, 'name') ? server.config.name : ''
  if has_key(reply, 'error')
    l.PrintError('(' .. sName .. ') ' .. string(reply.error.message))
  else
    RpcCb(server, reply)
  endif
enddef

export def RpcOutCb(server: any, chan: channel, msg: any): void
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
    server.ProcessRequest(string(msg))
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
