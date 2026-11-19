vim9script
# vim -Nu NONE -i NONE -n -es -S tests/snippets.vim
source <sfile>:h/../plugin/lsp.vim
import '../lib/Features/Snippet.vim' as sn
import '../lib/Utils/Snippet.vim' as syntax

var engine = sn.Snippet.new()
var parsed = syntax.Parse('f(${2:later}, ${1:é})$0;')
assert_equal('f(later, é);', parsed.text)
assert_equal('a,b $1', syntax.Parse('${1|a\,b,c|} \$1').text)
assert_equal('1', syntax.Parse('${TM_LINE_NUMBER:${1:unused}}').text)
assert_equal('fallback', syntax.Parse('${UNKNOWN:fallback}').text)

def Start()
  engine.Handle(parsed, [2, strlen('prefix ' .. parsed.text) + 1])
enddef
inoremap <F2> <Cmd>call <SID>Start()<CR>
setline(1, ['import', 'prefix ' .. parsed.text .. ' suffix'])
feedkeys("i\<F2>FIRST\<Tab>SECOND\<Tab>!\<Esc>", 'xt')
assert_equal('prefix f(SECOND, FIRST)!; suffix', getline(2))
assert_false(exists('b:lsp_snippet_index'))

# Empty tab stop and an explicit final stop on a different line, with CRLF
# snippet text and a multibyte prefix before the inserted range.
parsed = syntax.Parse("(\$1)\r\n  \$0;")
def StartMultiline()
  engine.Handle(parsed, [3, 4])
enddef
inoremap <F3> <Cmd>call <SID>StartMultiline()<CR>
setline(1, ['import', 'é()', '  ; suffix'])
feedkeys("i\<F3>x\<Tab>y\<Esc>", 'xt')
assert_equal(['import', 'é(x)', '  y; suffix'], getline(1, '$'))

# Advance directly from a selected placeholder, retaining its default.
parsed = syntax.Parse('${1:keep}$0')
setline(2, 'prefix keep')
feedkeys("i\<F2>\<Tab>!\<Esc>", 'xt')
assert_equal('prefix keep!', getline(2))

if !empty(v:errors)
  echomsg join(v:errors, "\n")
  cquit
endif
qa!
