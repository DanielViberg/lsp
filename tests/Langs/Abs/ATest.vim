vim9script 

import "./ITest.vim" as i
import "../../../env.vim" as e
import "../../../lib/Utils/Log.vim" as l
import "../../../lib/ClientState/Session.vim" as ses
import "../../../lib/Features/Completion.vim" as comp

var result: number = 0

export abstract class ATest

  abstract def Config(): dict<list<any>>
  var noServer: bool = false

  def Run(): number
    comp.bufferWords = []
    comp.cacheWords = []
    writefile([json_encode({ servers: [ this.Config() ]})], e.TESTING_CONF_FILE)
    var file = "/tmp/vim-lsp-test-" .. this.Config().name .. "." .. this.Config().filetype[0]
    writefile([""], file)
    execute "e! " .. file 

    # Wait until server init
    var servers = ses.GetSessionServersByBuf(bufnr())
    if servers->len() == 0 && !this.noServer
      l.PrintError("No server found")
      return 0
    endif

    var maxWait = 5
    while !this.noServer && !servers[0].isFeatInit && maxWait > 0
      l.PrintDebug("Waiting for server to init")
      maxWait -= 1
      if maxWait == 0
        l.PrintError("Failed to init server")
        return 1
      endif
      sleep 1
    endwhile

    # Formatting
    appendbufline(bufnr(), 0, split(this.PreFormatString(), '\n'))
    :doautocmd TextChangedI
    LspFormat
    if assert_equal(this.PostFormatString(), join(getline(1, '$'), "\n"))
      l.PrintError("Formatting failed")
    endif

    :1,$d

    # Completion
    var states = this.CompletionStates()
    for state in states
      appendbufline(bufnr(), 0, split(state[0], '\n'))
      :doautocmd TextChangedI
      execute "normal! /¤\<CR>" 
      var charBefore = getline('.')[col('.') - 2]
      cursor(line('.'), col('.') + 1)
      normal! hxx
      timer_start(1000, (_) => {
        var items = complete_info(["items"]).items->map((_, mi) => mi.word)
        if assert_equal(items, state[1])
          echomsg items
          echomsg state[1]
          result = 1
        endif
        feedkeys("\<Esc>", "")
      })
      feedkeys("i\<Right>" .. charBefore, "x!")
      if result
        l.PrintError("Completion failed")
        return result
      endif
      :1,$d
    endfor

    var accepts = this.CompletionAccepts()
    for accept in accepts
      appendbufline(bufnr(), 0, split(accept[0], '\n'))
      :doautocmd TextChangedI
      execute "normal! /¤\<CR>" 
      var charBefore = getline('.')[col('.') - 2]
      cursor(line('.'), col('.') + 1)
      normal! hxx
      timer_start(1000, (_) => {
        var items = complete_info(["items"]).items->map((mix, mi) => {
          var r = { index: mix, word: mi.word }
          return r
        })
        for item in items
          if item.word == accept[1]
            feedkeys("\<Enter>", "")
            timer_start(500, (_) => {
              feedkeys("\<Esc>", "")
            })
            return
          endif
          feedkeys("\<Down>", "")
        endfor
      })
      feedkeys("\<Left>\<Left>ei\<Right>" .. charBefore, "x!") #TODO: fails at short words
      if assert_equal(join(getline(1, '$'), "\n"), accept[2])
        echomsg join(getline(1, '$'), "\n")
        echomsg accept[2]
        l.PrintError("Failed completion accept")
        return 1
      endif
      :1,$d
    endfor

    var incrEdits = this.CompletionIncrEdit()
    for iedit in incrEdits
      appendbufline(bufnr(), 0, split(iedit[0], '\n'))
      :doautocmd TextChangedI
      execute "normal! /¤\<CR>"
      normal! x
      for c in range(0, len(iedit[1]) - 1)
        var nextChar = iedit[1][c]
        timer_start(500, (_) => {
          var items = complete_info(["items"]).items->map((_, mi) => mi.word)
          if assert_equal(items, iedit[2][c]) && c < len(iedit[1]) - 1
            echomsg items
            echomsg iedit[2][c]
            l.PrintError("Wrong completion count")
            result = 1
            return
          endif

          feedkeys("\<Esc>", "")
        })
        feedkeys("i\<Right>" .. nextChar, "x!")
        if result
          l.PrintError("Completion failed")
          return 1
        endif
      endfor
      :1,$d
    endfor

    :1,$d

    return 0
  enddef

endclass

