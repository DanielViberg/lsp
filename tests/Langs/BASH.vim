
vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

export class BASH extends a.ATest implements i.ITest

  def Config(): dict<any>
    return {
      name: "bash-ls",
      filetype: ["sh", "bash"],
      path: "bash-language-server",
      args: ["start"],
      workspaceConfig: {
        html: {
          format: {
	          enable: true,
	          wrapAttributes: "force-aligned"
          }
        }
      }
    }
  enddef


  def CompletionStates(): list<tuple<string, list<string>>>
    return [
      ("fal¤", ["false"]),
    ]
  enddef

  def CompletionAccepts(): list<tuple<string, string, string>>
    return [
      ("\n\tfal¤", "false", "\tfalse\n"),
    ]
  enddef

endclass
