vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

# https://github.com/clangd/clangd/issues/2385

export class C extends a.ATest implements i.ITest

  def Config(): dict<any>
    return {
      name: "c-ls",
      filetype: ["c"],
      path: "clangd",
      args: ["--background-index", "--clang-tidy"],
    }
  enddef

  def CompletionAccepts(): list<tuple<string, string, string>>
    return [
      ("#inc¤\n", "include", "#include\n"),
    ]
  enddef

endclass
