vim9script

export interface IFeature
  def AutoCmds(): void 
  def ProcessRequest(server: any, data: any): void 
  def ProcessNotification(server: any, data: any): void 
endinterface
