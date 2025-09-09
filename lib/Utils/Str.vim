vim9script

import "../Protocol/Objects/Position.vim" as p

export def Uri(path: string): string
  return 'file://' .. path
enddef 

export def FromUri(uri: string): string
  return substitute(uri, '^file://', '', '')
enddef

# From the cursor, track backwards until triggerchar or space is found
# Return the column nr
export def GetTriggerCharIdx(triggerChars: any, line: number, col: number): dict<any>
  triggerChars->filter((_, t) => t != '-') # Dont work well with css completion
  var cursorPrefix = getline(line)->strpart(0, col - 1)
  var pcol = cursorPrefix->len()
  for c in cursorPrefix->split('\zs')->reverse()
    if index(triggerChars, c) != -1 || 
       match(c, '\s') >= 0 ||
       c == '[' || # TODO: How to fix this?
       c == '('
      break
    endif
    pcol -= 1
  endfor
  return {
     col: pcol,
     char: cursorPrefix[pcol]
  }
enddef

# Retrives the closest trigger char before or under cursor
export def GetTriggerChar(triggerChars: any): string
  var line  = line('.')
  var col = col('.')
  var char = getline(line)[col - 2] #Char before cursor
  if index(triggerChars, char) != -1 
    return char
  endif
  return ''
enddef

export def Utf8ToUtf16WithComp(utf8_str: string, utf8_idx: number): number
  var chars = str2list(utf8_str, 1)  # Unicode codepoints from UTF-8
  var utf16_count = 0

  for i in range(utf8_idx)
    if i >= len(chars)
      break
    endif
    var cp = chars[i]
    utf16_count += cp <= 0xFFFF ? 1 : 2
  endfor

  return utf16_count
enddef

export def Utf8ToUtf8WithComp(utf8_str: string, utf8_idx: number): number
  var byte_idx = 0
  var cp_count = 0

  while cp_count < utf8_idx && byte_idx < len(utf8_str)
    var cp = strcharpart(utf8_str, byte_idx, 1)
    byte_idx += strlen(cp)  # UTF-8 byte length of this codepoint
    cp_count += 1
  endwhile

  return byte_idx
enddef

export def Utf8ToUtf32WithComp(utf8_str: string, utf8_idx: number): number
  var chars = str2list(utf8_str, 1)  # Unicode codepoints
  return min([utf8_idx, len(chars)])
enddef

export def Utf16ToUtf8ByteIdxWOComp(utf8_str: string, utf16_idx: number): number
  var byte_idx = 0
  var utf16_count = 0

  while byte_idx < len(utf8_str)
    var cp_str = strcharpart(utf8_str, byte_idx, 1)
    var cp = char2nr(cp_str)

    # Skip combining marks (like U+0300 to U+036F, plus others)
    if cp >= 0x0300 && cp <= 0x036F
      byte_idx += strlen(cp_str)
      continue
    endif

    # How many UTF-16 units this base character takes
    var width = cp <= 0xFFFF ? 1 : 2

    if utf16_count + width > utf16_idx
      break
    endif

    utf16_count += width
    byte_idx += strlen(cp_str)
  endwhile

  return byte_idx
enddef

# Find the nearest root directory containing a file or directory name from the
# list of names in "files" starting with the directory "startDir".
# Based on a similar implementation in the vim-lsp plugin.
# Searches upwards starting with the directory "startDir".
# If a file name ends with '/' or '\', then it is a directory name, otherwise
# it is a file name.
# Returns '' if none of the file and directory names in "files" can be found
# in one of the parent directories.
export def FindNearestRootDir(startDir: string, files: list<any>): string
  var foundDirs: dict<bool> = {}

  for file in files
    if file->type() != v:t_string || file->empty()
      continue
    endif
    var isDir = file[-1 : ] == '/' || file[-1 : ] == '\'
    var relPath: string
    if isDir
      relPath = finddir(file, $'{startDir};')
    else
      relPath = findfile(file, $'{startDir};')
    endif
    if relPath->empty()
      continue
    endif
    var rootDir = relPath->fnamemodify(isDir ? ':p:h:h' : ':p:h')
    foundDirs[rootDir] = true
  endfor
  if foundDirs->empty()
    return ''
  endif

  # Sort the directory names by length
  var sortedList: list<string> = foundDirs->keys()->sort((a, b) => {
    return b->len() - a->len()
  })

  # choose the longest matching path (the nearest directory from "startDir")
  return sortedList[0]
enddef
