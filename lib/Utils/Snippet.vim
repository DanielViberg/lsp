vim9script

# Offsets are bytes in the rendered text, before it is applied to the buffer.
class Parser
  var chars: list<string>
  var i = 0
  var text = ''
  var stops: dict<list<number>> = {}

  def new(source: string)
    this.chars = split(substitute(source, '\r\n', "\n", 'g'), '\zs')
  enddef

  def Peek(): string
    return get(this.chars, this.i, '')
  enddef

  def Body(nested: bool)
    while this.i < len(this.chars)
      var ch = this.Peek()
      if nested && ch == '}'
        return
      endif
      this.i += 1
      if ch == '\' && index(['$', '}', '\'], this.Peek()) >= 0
        this.text ..= this.Peek()
        this.i += 1
      elseif ch == '$'
        this.Field()
      else
        this.text ..= ch
      endif
    endwhile
  enddef

  def Field()
    var saved = this.i
    var braced = this.Peek() == '{'
    if braced
      this.i += 1
    endif
    var numbered = this.Peek() =~# '\d'
    var key = ''
    while this.Peek() =~# (numbered ? '\d' : '[A-Za-z_0-9]')
      key ..= this.Peek()
      this.i += 1
    endwhile
    if empty(key) || (braced && index([':', '}', '|'], this.Peek()) < 0)
      this.text ..= '$'
      this.i = saved
      return
    endif

    var start = strlen(this.text)
    var vars: dict<string> = {}
    if !numbered
      vars = {TM_FILENAME: expand('%:t'), TM_FILENAME_BASE: expand('%:t:r'),
        TM_DIRECTORY: expand('%:p:h'), TM_FILEPATH: expand('%:p'),
        TM_CURRENT_LINE: getline('.'), TM_CURRENT_WORD: matchstr(strpart(getline('.'), 0, col('.') - 1), '\k*$')
          .. matchstr(strpart(getline('.'), col('.') - 1), '^\k*'),
        TM_LINE_NUMBER: string(line('.')), TM_LINE_INDEX: string(line('.') - 1)}
    endif
    if braced && this.Peek() == ':'
      this.i += 1
      if has_key(vars, key) && !empty(vars[key])
        # Consume, but do not render or register stops inside an unused default.
        var stops = copy(this.stops)
        this.Body(true)
        this.stops = stops
        this.text = strpart(this.text, 0, start) .. vars[key]
      else
        this.Body(true)
      endif
    elseif braced && this.Peek() == '|'
      this.i += 1
      var first = true
      while this.i < len(this.chars)
        var c = this.Peek()
        this.i += 1
        if c == '|' && this.Peek() == '}'
          break
        elseif c == ','
          first = false
        else
          if c == '\' && index([',', '|', '\'], this.Peek()) >= 0
            c = this.Peek()
            this.i += 1
          endif
          if first
            this.text ..= c
          endif
        endif
      endwhile
    elseif has_key(this.stops, key)
      var previous = this.stops[key]
      this.text ..= strpart(this.text, previous[0], previous[1] - previous[0])
    elseif !numbered
      this.text ..= get(vars, key, key)
    endif
    if braced && this.Peek() == '}'
      this.i += 1
    endif
    if numbered && !has_key(this.stops, key)
      this.stops[key] = [start, strlen(this.text)]
    endif
  enddef
endclass

export def Parse(source: string): dict<any>
  var parser = Parser.new(source)
  parser.Body(false)
  if !has_key(parser.stops, '0')
    parser.stops['0'] = [strlen(parser.text), strlen(parser.text)]
  endif
  var keys = filter(keys(parser.stops), (_, k) => k != '0')->sort('n') + ['0']
  return {text: parser.text, stops: mapnew(keys, (_, k) => parser.stops[k])}
enddef
