#
#                Wrapper for Node.JS' path module
#        Copyright (C) 2020 Leorize <leorize+oss@disroot.org>
#
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import jsffi, macros

let path = require("path")

macro join*(fragments: varargs[cstring, cstring]): cstring =
  result = newStmtList()
  let joinCall = newCall(newDotExpr(bindSym"path", ident"join"))
  for f in fragments:
    joinCall.add f
  result.add newCall(bindSym"to", joinCall, newCall(bindSym"typeof", bindsym"cstring"))

func `/`*(a, b: cstring): cstring {.inline.} =
  {.noSideEffect.}:
    join(a, b)
