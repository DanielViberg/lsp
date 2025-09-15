vim9script

import "../../env.vim" as e

export enum Type
  Info,
  Warning,
  Error
endenum

export def Log(type: Type, msg: string)
  writefile(msg->split("\n"), '/tmp/lspc.log', 'a')
enddef

export def PrintInfo(msg: string): void
  echohl DiagnosticsOk
  echomsg msg | redraw
  echohl None
enddef

export def PrintDebug(msg: string): void
  if e.DEBUG
    echomsg msg | redraw
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
