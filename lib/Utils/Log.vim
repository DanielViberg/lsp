vim9script

var isDebug: bool = false

export enum Type
  Info,
  Warning,
  Error
endenum

export def Log(type: Type, msg: string)
  writefile(msg->split("\n"), '/tmp/lspc.log', 'a')
enddef

export def PrintDebug(msg: string): void
  if isDebug
    echomsg msg
  endif
enddef

export def PrintWarning(msg: string): void
  echohl Warning
  echomsg msg
  echohl None
enddef

export def PrintError(msg: string): void
  echohl ErrorMsg
  echomsg msg
  echohl None
enddef
