vim9script

import "../Protocol/Abstracts/RequestMessage.vim" as rm
import "../ClientState/Abstract/Server.vim" as serv
import "../ClientState/Session.vim" as ses
import "../Protocol/Abstracts/Message.vim" as mes
import "../Utils/Log.vim" as l
import "../../env.vim" as e

export def RpcSync(server: serv.Server, req: rm.RequestMessage): any
  var request = req.ToJson()
  l.LogRpc(true, request)
  var reply = server.job->ch_evalexpr(request)
  l.LogRpc(false, reply)
  return reply
enddef

export def RpcAsyncMes(server: serv.Server, notif: mes.Message)
  if server.job->job_status() != 'run'
    return
  endif
  var not = notif.ToJson()
  l.LogRpc(true, not)
  server.job->ch_sendexpr(not)
enddef

export def RpcAsync(server: serv.Server, 
                    req: rm.RequestMessage, 
                    Cb: func, 
                    bnr = v:none)
  if server.job->job_status() != 'run'
    return
  endif

  var request = req.ToJson()
  l.LogRpc(true, request)
  var Fn = function('RpcAsyncCb', [server, Cb, bnr])
  server.job->ch_sendexpr(request, {callback: Fn})
enddef

def RpcAsyncCb(server: serv.Server, 
               RpcCb: func, 
               bnr: any,
               chan: channel, 
               reply: dict<any>)

  l.LogRpc(false, reply)

  var sName = has_key(server.config, 'name') ? server.config.name : ''
  if has_key(reply, 'error')
    l.PrintError('(' .. sName .. ') ' .. string(reply.error.message))
  endif

  if bnr->type() == v:t_number
    RpcCb(server, reply, bnr)
  else
    RpcCb(server, reply)
  endif
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
  l.PrintDebug(emsg)
  l.Log(l.Type.Error, emsg)
enddef

export def RpcExitCb(s: any, job: job, status: number)
  s.isRunning = false
enddef
