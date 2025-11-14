vim9script

import "./Abs/ATest.vim" as a
import "./Abs/ITest.vim" as i

export class PHP extends a.ATest implements i.ITest

  def Config(): dict<any>
    return {
      name: "php-ls",
      filetype: ["php"],
      path: "intelephense",
      args: ["--stdio"],
      initializationOptions: {},
      workspaceConfig: {
        intelephense: {
          format: {
		        braces: "k&r"
          }
        }
      }
    }
  enddef

  def PreFormatString(): string
    return "<?php\nclass Test {}"
  enddef

  def PostFormatString(): string
    return "<?php\nclass Test {\n}"
  enddef

  def CompletionStates(): list<tuple<string, list<string>>>
    return [
      ("<?php\n class Test {\n\tconst test = '';\n\tpublic function test()\n{\n\tself::¤\n\t}\n}", ["class", "test"]),
      ("<?php\n class Test {\n\tconst test_variable = '';\n\tpublic function test()\n{\n\ttest_var¤\n\t}\n}", ["test_variable"]),
      ("<?php\n class Test {\n\tpublic function myfunc()\n{\n\t$test = new Test();\n\t$test->¤\n\t}\n}", ["myfunc"]),
      ("<?php\n class Test {\n\tp¤\n}", ["private", "protected", "public", "php"]),
      ("<?php\n class Test {\n\tpublic fu¤\n}", ["function"]),
      ("<?php\n class Test {\n\tpublic function test()\n{\n\t $testVar = null;\n\t $te¤\n}\n}", ["$testVar"]),
      ("<?php\n class Test {\n\tpublic function test()\n{\n\t $¤\n}\n}", ["$this", 
                                                                          "$_COOKIE", 
                                                                          "$_ENV",
                                                                          "$_FILES", 
                                                                          "$_GET",
                                                                          "$_POST", 
                                                                          "$_REQUEST",
                                                                          "$_SERVER", 
                                                                          "$_SESSION", 
                                                                          "$GLOBALS", 
                                                                          "$HTTP_RAW_POST_DATA", 
                                                                          "$http_response_header", 
                                                                          "$php_errormsg"]),
                                                                          ]
  enddef

  def CompletionAccepts(): list<tuple<string, string, string>>
    return [
      ("<?php\n class Test {\n\tpub¤\n}\n", "public", "<?php\n class Test {\n\tpublic\n}\n"),
      ("<?php\n class Test {\n\tpublic function test()\n{\n\t $testVar = null;\n\t $testV¤ = 1;\n}\n}\n", 
      "$testVar",
      "<?php\n class Test {\n\tpublic function test()\n{\n\t $testVar = null;\n\t $testVar = 1;\n}\n}\n"),
    ]
  enddef

  def CompletionIncrEdit(): list<tuple<string, string, list<list<string>>>>
    return [
      ("<?php\n class Test {\n\tpu¤\n}\n", "blic", [["public", "public"],
                                                    ["public", "public"],
                                                    ["public", "public"],
                                                    ["public", "public"]]),

      ("<?php\n class Test {\n\tpublic function test()\n{\n\t$longVariable = 1;\n\t$lo¤\n}\n}\n", "ngVariable", [
                                                    ["$longVariable"],
                                                    ["$longVariable"],
                                                    ["$longVariable"],
                                                    ["$longVariable"],
                                                    ["$longVariable"],
                                                    ["$longVariable"],
                                                    ["$longVariable"],
                                                    ["$longVariable"],
                                                    ["$longVariable"],
                                                    ["$longVariable"],
                                                    ]),

    ("<?php\n noValidVar\n class Test {\n\tpublic function test()\n{\n\tnoV¤\n}\n}\n", "alidVar", [
                                                    ["noValidVar"],
                                                    ["noValidVar"],
                                                    ["noValidVar"],
                                                    ["noValidVar"],
                                                    ["noValidVar"],
                                                    ["noValidVar"],
                                                    ["noValidVar"],
                                                    ]),
    ]
  enddef

endclass
