#
#               Github Actions for installing Nim
#       Copyright (C) 2020 Leorize <leorize+oss@disroot.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

import asyncjs, jsffi, strutils
import private/actions/[core, exec]
import private/path

var process {.nodecl, importc.}: JsObject
let
  fs = require("fs")
  os = require("os")

template getAppDir(): cstring =
  var dir {.nodecl, importc: "__dirname"}: cstring
  dir

template addPath(path: cstring) =
  let p = path
  info "Adding '" & p & "' to PATH"
  core.addPath path

proc main(): Future[void] {.async.} =
  let path = getInput("path")
  group "Download the compiler":
    let exitCode = await exec('"' & replace($getAppDir().join "setup.sh", "\"", "\""), "-o", path, getInput("version", InputOptions(required: true)))
    if exitCode != 0:
      error "Download failed"
      return
  info "Adding annotations"
  addMatcher join(getAppDir(), ".github", "nim.json")
  if getInput("add-to-path") == "true":
    info "Adding compiler to PATH"
    let rpath = fs.realpathSync(path).to(cstring)
    addPath rpath / "bin"
    addPath os.homedir().to(cstring).join(".nimble", "bin")

when isMainModule:
  discard main()
