vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

export class CS extends a.ATest implements i.ITest

  def Config(): dict<any>
    return {
      name: "mscs-ls",
      filetype: ["cs"],
      path: ["dotnet", "Microsoft.CodeAnalysis.LanguageServer.dll"],
      args: ["--logLevel", "Information", "--extensionLogDirectory", "/tmp/ms-cs-ls", "--stdio"],
      initializationOptions: {},
      workspaceConfig: {}
    }
  enddef

  def PreFormatString(): string
    return ""
  enddef

  def PostFormatString(): string
    return ""
  enddef

  def CompletionStates(): list<tuple<string, list<string>>>
    return []
  enddef

  def CompletionAccepts(): list<tuple<string, string, string>>
    return []
  enddef

  def CompletionIncrEdit(): list<tuple<string, string, list<list<string>>>>
    return []
  enddef

endclass
