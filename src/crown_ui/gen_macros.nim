import macros

proc replaceReturn(node:  NimNode) =
  var z = 0
  for s in node:
    var son = node[z]
    let toString = ident("$")
    if son.kind == nnkReturnStmt:
      if son[0].kind != nnkEmpty:
        let value =  nnkCall.newTree(toString, son[0]) 
        node[z] = nnkReturnStmt.newTree(value)
    elif son.kind == nnkAsgn and son[0].kind == nnkIdent and $son[0] == "result":
      node[z] = nnkAsgn.newTree(son[0], nnkCall.newTree(toString, son[1]))
    else:
      replaceReturn(son)
    inc z

macro exportTheme*(prc:untyped):untyped =
  result = copyNimTree(prc)
  result.params[0] = ident("string")
  result.body.replaceReturn
  result.body.add  newAssignment(ident"result", newCall(ident"$", ident"result"))
