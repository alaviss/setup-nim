#
#               Helper tools for interacting with JS
#        Copyright (C) 2020 Leorize <leorize+oss@disroot.org>
#
#  This Source Code Form is subject to the terms of the Mozilla Public
#  License, v. 2.0. If a copy of the MPL was not distributed with this
#  file, You can obtain one at http://mozilla.org/MPL/2.0/.

import macros, jsffi

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

func isVarargsProc(n: NimNode): bool =
  doAssert n.kind in {nnkProcDef, nnkFuncDef}
  n.pragma.findChild(it.kind in {nnkSym, nnkIdent} and
                     eqIdent(it, "varargs")) != nil

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

  template errorVarargsExpected(info: NimNode) =
    error """
Varargs method must contain a parameter at the end of type `varargs`.
If the varargs can accept any type, use `varargs[JsObject, jsffi.toJs]`
""", info

  if orig.isVarargsProc():
    if orig.params.len > 1:
      let
        lastDef = params[^1]
        lastDefType = lastDef[^2]
      if lastDefType.kind != nnkBracketExpr or not lastDefType[0].eqIdent("varargs"):
        errorVarargsExpected(lastDefType)
      elif lastDef.len > 3:
        lastDef.del(lastDef.len - 3)
      else:
        params.del params.len - 1
    else:
      errorVarargsExpected(orig)

  result = newProc(genSym(nskProc, orig.name.strVal & "_wrapper"), params,
                   pragmas = copyNimTree(orig.pragma))
  result.addPragma newTree(
    nnkExprColonExpr,
    ident"importcpp",
    newLit orig.name.strVal
  )

func wrapSym(sym: NimNode): NimNode =
  ## Wrap a symbol so that it can be retrieved as a NimNode
  doAssert sym.kind == nnkSym
  let wrapper = genSym(nskTemplate)
  result = newStmtList(
    newProc(wrapper, [bindSym"untyped"], newStmtList(sym), nnkTemplateDef),
    newCall(bindSym"getAst", newCall(wrapper))
  )

func newInlineWrapper(proto, module, wrapper: NimNode): NimNode =
  doAssert proto.kind in {nnkProcDef, nnkMethodDef, nnkFuncDef}
  doAssert module.kind == nnkSym
  doAssert wrapper.kind == nnkSym
  let isVarargs = proto.isVarargsProc()
  result = newTree(nnkMacroDef)

  for i in proto:
    result.add copyNimTree(i)

  result.pragma = newEmptyNode()
  result.body = newStmtList(
    newAssignment(
      ident"result",
      newCall(bindSym"newStmtList")
    )
  )

  let
    genWrapperCall = newCall(bindSym"newCall", wrapper.wrapSym, module.wrapSym)
    storeGenWrapperCall = newLetStmt(genSym(), genWrapperCall)
  result.body.add storeGenWrapperCall
  result.body.add newCall(bindSym"add", ident"result", storeGenWrapperCall[0][0])
  if result.params.len > 1:
    for paramDefIdx in 1 ..< result.params.len:
      for paramIdx in 0 ..< result.params[paramDefIdx].len - 2:
        if paramDefIdx < result.params.len - 1:
          genWrapperCall.add result.params[paramDefIdx][paramIdx]

    if isVarargs:
      template addVarargs(arg, items, call): untyped =
        for i in arg.items:
          call.add i

      result.body.add getAst addVarargs(result.params[^1][^3], bindSym"items", storeGenWrapperCall[0][0])
    else:
      genWrapperCall.add result.params[^1][^3]

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
      result.add newInlineWrapper(p, module, wrapperSym)
    else:
      error "Only procs can be wrapped at the moment! Got " & $p.kind, p

template `~`*(s: cstring): cstring =
  ## A no-op operator
  s
template `~`*(s: string): cstring =
  ## Convienient operator to convert `string` -> `cstring`
  s.cstring
