vim9script

import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if

export class Snippet extends ft.Feature implements if.IFeature
  def new()
    this.AutoCmds()
  enddef

  def AutoCmds()
  enddef

  def ServerPreStop(): void
  enddef

  def ProcessRequest(server: any, data: any): void 
  enddef

  def ProcessNotification(server: any, data: any): void 
  enddef

  def Handle()
  enddef
endclass
