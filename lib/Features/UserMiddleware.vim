vim9script

import "./Abstract/Feature.vim" as ft
import "./Interfaces/IFeature.vim" as if
import "../Protocol/Abstracts/RequestMessage.vim" as rm

export class UserMiddleware extends ft.Feature implements if.IFeature
  def new()
    this.AutoCmds()
  enddef

  def AutoCmds()
  enddef

  def PreRequest(server: any, req: rm.RequestMessage): void
  enddef

  def ProcessRequest(server: any, data: any): void 
  enddef

  def ProcessNotification(server: any, data: any): void 
  enddef

  def Handle()
  enddef
endclass
