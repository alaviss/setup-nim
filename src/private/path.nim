#
#                Wrapper for Node.JS' path module
#        Copyright (C) 2020 Leorize <leorize+oss@disroot.org>
#
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import jsffi
import utils

export `~`

wrapModule("path"):
  proc join*(paths: varargs[cstring, `~`]): cstring {.varargs.}

func `/`*(a, b: cstring): cstring {.inline.} =
  {.noSideEffect.}:
    result = join(a, b)
