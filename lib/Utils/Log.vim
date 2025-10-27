vim9script

import "../../env.vim" as e
import "./Str.vim" as s

export enum Type
  Info,
  Warning,
  Error
endenum

export def Log(type: Type, msg: string)
  writefile(msg->split("\n"), s.TempDir() .. 'lspc.log', 'a')
enddef

export def LogRpc(out: bool, msg: any)
  if e.TESTING || e.DEBUG_RPC
    var m = out ? 'REQUEST: ' .. json_encode(msg) : 'RESPONSE: ' .. json_encode(msg)
    writefile(m->split("\n"), s.TempDir() .. 'lspc.log', 'a')
    writefile(m->split("\n"), s.TempDir() .. 'lspc_rpc.log', 'a') 
  endif
enddef

export def PrintInfo(msg: string): void
  echohl DiagnosticsOk
  echomsg msg | redraw
  echohl None
enddef

export def PrintDebug(msg: string): void
  if e.DEBUG || e.TESTING
    echomsg msg | redraw
    Log(Type.Info, msg)
  endif
enddef

export def PrintWarning(msg: string): void
  echohl Warning
  echomsg msg | redraw
  echohl None
enddef

export def PrintError(msg: string): void
  echohl ErrorMsg
  echomsg msg
  echohl None
enddef
