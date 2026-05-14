vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

export class TXT extends a.ATest implements i.ITest

  def new()
    this.noServer = true
  enddef

  def Config(): dict<any>
    return {
      name: "txt-ls",
      filetype: ["txt"],
    }
  enddef

  def CompletionAccepts(): list<tuple<string, string, string>>
    return [
      ("completionWord\ncompl¤", "completionWord", "completionWord\ncompletionWord\n"),
    ]
  enddef

endclass
