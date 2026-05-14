vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

export class CS extends a.ATest implements i.ITest

  def Config(): dict<any>
    return {
      name: "mscs-ls",
      filetype: ["cs"],
      path: "dotnet",
      args: [
      "/tools/cslsp/Microsoft.CodeAnalysis.LanguageServer.dll",
      "--logLevel", 
      "Information", 
      "--extensionLogDirectory", 
      "/tmp/ms-cs-ls", 
      "--stdio"],
      initializationOptions: {},
      workspaceConfig: {
        projects: {
          dotnet_binary_log_path: "tmp/binlogs"
         }
      }
    }
  enddef

  def CompletionStates(): list<tuple<string, list<string>>>
    return [
      ("Conso¤", [""]), #C sharp server is slow to read buffer state
      ("Conso¤", ["Console", 
                  "ConsoleCancelEventArgs", 
                  "ConsoleCancelEventHandler", 
                  "ConsoleColor", 
                  "ConsoleKey",
                  "ConsoleKeyInfo",
                  "ConsoleModifiers",
                  "ConsoleSpecialKey"]),
    ]
  enddef

endclass
