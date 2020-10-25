#
#               Helper tools for interacting with JS
#        Copyright (C) 2020 Leorize <leorize+oss@disroot.org>
#
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import macros, sugar, jsffi

func addModuleDecl(n: NimNode, module: string): tuple[typ, inst: NimNode] =
  result.typ = genSym(nskType, "Module")
  result.inst = genSym(nskLet, "module")

  # type `typ` = ref object of JsRoot
  n.add newTree(
    nnkTypeSection,
    newTree(
      nnkTypeDef,
      result.typ,
      newEmptyNode(),
      newTree(
        nnkRefTy,
        newTree(
          nnkObjectTy,
          newEmptyNode(),
          newTree(nnkOfInherit, bindSym"JsRoot"),
          newEmptyNode()
        )
      )
    )
  )

  # let `inst` = to(require(`module`), `typ`)
  n.add newLetStmt(
    result.inst,
    newCall(
      bindSym"to",
      newCall(
        bindSym"require",
        newLit module
      ),
      result.typ
    )
  )

  discard # Compiler bug

func newWrapperProc(typ, orig: NimNode): NimNode =
  doAssert orig.kind == nnkProcDef
  var params: seq[NimNode]
  params.add copyNimTree(orig.params[0]) # Copy the return type
  # Add the first parameter which is the wrapping module
  params.add newTree(
    nnkIdentDefs,
    genSym(nskParam, "module"),
    typ,
    newEmptyNode()
  )
  # Copy the rest of the parameters
  if orig.params.len > 1:
    for param in orig.params[1..^1]:
      params.add copyNimTree param

  result = newProc(genSym(nskProc, orig.name.strVal & "_wrapper"), params,
                   pragmas = copyNimTree(orig.pragma))
  result.addPragma newTree(
    nnkExprColonExpr,
    ident"importcpp",
    newLit orig.name.strVal
  )

func newTemplate(n: NimNode): NimNode =
  doAssert n.kind in {nnkProcDef, nnkMethodDef, nnkFuncDef}
  result = newNimNode(nnkTemplateDef)
  for i in n:
    result.add copyNimTree i
  result.pragma = newEmptyNode()
  if n.pragma.findChild(it.kind == nnkIdent and eqIdent(it, "varargs")) != nil:
    error "varargs wrapping is not supported!"
    when false:
      result.vaSym = genSym(nskParam, "va")
      result.templ.params.add newTree(
        nnkIdentDefs,
        result.vaSym,
        newTree(
          nnkBracketExpr,
          bindSym"varargs",
          bindSym"untyped"
        ),
        newEmptyNode()
      )

macro wrapModule*(name: static[string], procs: untyped): untyped =
  expectKind procs, nnkStmtList

  result = newStmtList()
  let (moduleType, module) = result.addModuleDecl name

  for p in procs:
    if p.kind == nnkProcDef:
      let
        wrapper = newWrapperProc(moduleType, p)
        wrapperSym = wrapper[0]

      result.add wrapper

      let wrapperCall = newCall(wrapperSym, module)
      if p.params.len > 1:
        let params = collect(newSeq):
          for param in p.params[1..^1]:
            for def in param[0..^3]:
              def
        wrapperCall.add params

      let wrapperTemplate = newTemplate(p)
      wrapperTemplate.body = newStmtList(wrapperCall)
      result.add wrapperTemplate
    else:
      error "Only procs can be wrapped at the moment! Got " & $p.kind, p
