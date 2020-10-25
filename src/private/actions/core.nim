#
#                Wrapper for Github Actions' core module
#          Copyright (C) 2020 Leorize <leorize+oss@disroot.org>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

import jsffi
import ".." / utils

type
  InputOptions* = object
    required: bool

  ExitCode* = enum
    Success = 0
    Failure

  CommandProperties = JsAssoc[cstring, cstring]

wrapModule("@actions/core"):
  proc exportVariable*(name: cstring, val: any)
  proc setSecret*(secret: cstring)
  proc addPath*(path: cstring)
  proc getInput*(name: cstring): cstring
  proc getInput*(name: cstring, options: InputOptions): cstring
  proc setOutput*(name: cstring, val: any)
  proc setCommandEcho*(enabled: bool)
  proc setFailed*(message: cstring)
  proc isDebug*(): bool
  proc debug*(message: cstring)
  proc error*(message: cstring)
  proc warning*(message: cstring)
  proc info*(message: cstring)
  proc startGroup(name: cstring)
  proc endGroup(name: cstring)
  proc saveState*(name: cstring, val: any)
  proc getState*(name: cstring): cstring

template group*(name: cstring, body: untyped): untyped =
  let n = name
  try:
    startGroup(n)
    body
  finally:
    endGroup(n)

proc addMatcher*(file: cstring) =
  var console {.nodecl, importc.}: JsObject
  console.log "::add-matcher::" & file
