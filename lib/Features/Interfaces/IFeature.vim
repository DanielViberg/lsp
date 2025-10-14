vim9script

import "../../ClientState/Abstract/Server.vim" as abs

export interface IFeature
  def AutoCmds(): void 
  def ProcessRequest(server: abs.Server, data: any): void 
  def ProcessNotification(server: abs.Server, data: any): void 
endinterface
