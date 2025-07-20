vim9script

import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if

export class Workspace extends ft.Feature implements if.IFeature

  def new()
    this.AutoCmds()
  enddef

  def AutoCmds()

  enddef

  def ProcessRequest(data: any): void
    if has_key(data, 'method') && data.method == 'workspace/configuration'
      echomsg 'config'
    endif
  enddef

  def ProcessNotification(data: any)
  enddef

endclass
