vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

# TODO

export class TS extends a.ATest implements i.ITest

  def Config(): dict<any>
    return {
      name: "ts-ls",
      filetype: ["ts"],
      path: "typescript-language-server",
      args: ["--stdio"],
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
    return [
      ("con¤\n", "console", "console"),
    ]
  enddef

  def CompletionIncrEdit(): list<tuple<string, string, list<list<string>>>>
    return []
  enddef

endclass
