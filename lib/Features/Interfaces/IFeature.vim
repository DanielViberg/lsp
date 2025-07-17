vim9script

export interface IFeature
  def AutoCmds(): void 
  def ProcessRequest(data: any): void 
  def ProcessNotification(data: any): void 
endinterface
