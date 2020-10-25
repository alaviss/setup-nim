# Package

version       = "0.2.0"
author        = "Leorize"
description   = "A new awesome nimble package"
license       = "GPL-3.0+"
srcDir        = "src"
namedBin      = {"setup_nim": "index.js"}.toTable
backend       = "js"


# Dependencies

requires "nim >= 1.4.0"
