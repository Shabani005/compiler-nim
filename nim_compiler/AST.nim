import strutils, math, tables
import tokenizer

# after adding to TokenType enum and keywords dict add to ASTNodeKind enum and object (basically like a class in OOP languages)

type
  ASTNodeKind* = enum
    nkNumber,
    nkFloat,
    nkString,
    nkIdentifier,
    nkBinaryOperation,
    nkFunctionCall,
    nkForLoop,
    nkWhileLoop

  ASTNode* = ref object
    case kind*: ASTNodeKind
    of nkNumber:
      value*: int
    of nkFloat:
      floatValue*: float
    of nkString:
      strValue*: string
    of nkIdentifier:
      name*: string
    of nkBinaryOperation:
      op*: TokenType
      left*, right*: ASTNode
    of nkFunctionCall:
      funcName*: string
      args*: seq[ASTNode]
    of nkForLoop:
      fvarName*: string
      fstartExpr*, fendExpr*: ASTNode
      fbody*: ASTNode
    of nkWhileLoop:
      wcond*: ASTNode
      wbody*: ASTNode

  TokenStream* = object
    tokens*: seq[Token]
    pos*: int

proc current*(ts: TokenStream): Token = ts.tokens[ts.pos]
proc advance*(ts: var TokenStream) = 
  if ts.pos < ts.tokens.len - 1: inc ts.pos

proc parseNumber*(ts: var TokenStream): ASTNode =
  let tok = ts.current()
  if tok.kind == NUMBER:
    ts.advance()
    if '.' in tok.lexeme:
      return ASTNode(kind: nkFloat, floatValue: parseFloat(tok.lexeme))
    else:
      return ASTNode(kind: nkNumber, value: parseInt(tok.lexeme))
  else:
    raise newException(ValueError, "Expected a number")

proc parseExpr*(ts: var TokenStream): ASTNode
proc parseFunctionCall(ts: var TokenStream): ASTNode
proc parseForLoop(ts: var TokenStream): ASTNode
proc parseWhileLoop(ts: var TokenStream): ASTNode 

proc parseFactor(ts: var TokenStream): ASTNode =
  let tok = ts.current()
  if tok.kind == NUMBER:
    return parseNumber(ts)
  elif tok.kind == IDENTIFIER:
    if ts.tokens[ts.pos + 1].kind == LBRACKET:
      return parseFunctionCall(ts)
    else:
      let name = tok.lexeme
      ts.advance()
      return ASTNode(kind: nkIdentifier, name: name)
  elif tok.kind == LBRACKET:
    ts.advance()
    let node = parseExpr(ts)
    if ts.current().kind != RBRACKET:
      raise newException(ValueError, "Expected ')'")
    ts.advance()
    return node
  elif tok.kind == STRING:
    ts.advance()
    return ASTNode(kind: nkString, strValue: tok.lexeme)
  elif tok.kind == FOR:
    return parseForLoop(ts)
  elif tok.kind == WHILE:
    return parseWhileLoop(ts)
  else:
    raise newException(ValueError, "Expected a number, identifier, 'for', or '('")

proc parseExponent*(ts: var TokenStream): ASTNode =
  var node = parseFactor(ts)
  if ts.current().kind == EXPONENT:
    let op = ts.current().kind
    ts.advance()
    let right = parseExponent(ts)
    node = ASTNode(kind: nkBinaryOperation, op: op, left: node, right: right)
  return node

proc parseTerm*(ts: var TokenStream): ASTNode =
  var node = parseExponent(ts)
  while ts.current().kind in {STAR, DIVIDE}:
    let op = ts.current().kind
    ts.advance()
    let right = parseExponent(ts)
    node = ASTNode(kind: nkBinaryOperation, op: op, left: node, right: right)
  return node

proc parseExpr*(ts: var TokenStream): ASTNode =
  var node = parseTerm(ts)
  while ts.current().kind in {PLUS, MINUS}:
    let op = ts.current().kind
    ts.advance()
    let right = parseTerm(ts)
    node = ASTNode(kind: nkBinaryOperation, op: op, left: node, right: right)
  return node

proc parseFunctionCall(ts: var TokenStream): ASTNode =
  let funcName = ts.current().lexeme
  ts.advance()
  if ts.current().kind != LBRACKET:
    raise newException(ValueError, "Expected '(' after function name")
  ts.advance()
  var args: seq[ASTNode] = @[]
  if ts.current().kind != RBRACKET:
    while true:
      args.add(parseExpr(ts))
      if ts.current().kind == RBRACKET:
        break
      elif ts.current().kind == COMMA:
        ts.advance()
      else:
        raise newException(ValueError, "Expected ',' or ')'")
  ts.advance() # skip ')'
  return ASTNode(kind: nkFunctionCall, funcName: funcName, args: args)

proc parseForLoop(ts: var TokenStream): ASTNode =
  ts.advance() # skip 'for'
  let fvarName = ts.current().lexeme
  ts.advance()
  if ts.current().kind != IN:
    raise newException(ValueError, "Expected 'in' after for variable")
  ts.advance()
  if ts.current().kind != IDENTIFIER or ts.current().lexeme != "range":
    raise newException(ValueError, "Expected 'range' after 'in'")
  ts.advance()
  if ts.current().kind != LBRACKET:
    raise newException(ValueError, "Expected '(' after 'range'")
  ts.advance()
  let fstartExpr = parseExpr(ts)
  if ts.current().kind != COMMA:
    raise newException(ValueError, "Expected ',' in range")
  ts.advance()
  let fendExpr = parseExpr(ts)
  if ts.current().kind != RBRACKET:
    raise newException(ValueError, "Expected ')' after range")
  ts.advance()
  if ts.current().kind != INDENTATIONCOLON:
    raise newException(ValueError, "Expected ':' after for loop header")
  ts.advance()
  let fbody = parseExpr(ts) 
  return ASTNode(kind: nkForLoop, fvarName: fvarName, fstartExpr: fstartExpr, fendExpr: fendExpr, fbody: fbody)

proc parseWhileLoop(ts: var TokenStream): ASTNode =
  ts.advance() # skip 'while'
  let cond = parseExpr(ts)
  if ts.current().kind != INDENTATIONCOLON:
    raise newException(ValueError, "Expected ':' after while condition")
  ts.advance()
  let body = parseExpr(ts) # or parseBlock(ts) if you support blocks
  return ASTNode(kind: nkWhileLoop, wcond: cond, wbody: body)


proc printAST*(node: ASTNode, indent: int = 0) =
  let pad = "  ".repeat(indent)
  case node.kind
  of nkNumber:
    echo pad, "Int: ", node.value
  of nkFloat:
    echo pad, "Float: ", node.floatValue
  of nkString:
    echo pad, "String: \"", node.strValue, "\""
  of nkIdentifier:
    echo pad, "Identifier: ", node.name
  of nkBinaryOperation:
    echo pad, "Op: ", node.op
    printAST(node.left, indent + 1)
    printAST(node.right, indent + 1)
  of nkFunctionCall:
    echo pad, "FunctionCall: ", node.funcName
    for i, arg in node.args:
      echo pad, "  Arg ", i, ":"
      printAST(arg, indent + 2)
  of nkForLoop:
    echo pad, "ForLoop: var ", node.fvarName
    echo pad, "  Range:"
    printAST(node.fstartExpr, indent + 2)
    printAST(node.fendExpr, indent + 2)
    echo pad, "  Body:"
    printAST(node.fbody, indent + 2)
  of nkWhileLoop:
    echo pad, "WhileLoop:"
    echo pad, "  Condition:"
    printAST(node.wcond, indent + 2)
    echo pad, "  Body:"
    printAST(node.wbody, indent + 2)

proc eval*(node: ASTNode, env: var Table[string, float]): float =
  case node.kind
  of nkNumber:
    return float(node.value)
  of nkFloat:
    return node.floatValue
  of nkString:
    return 0.0
  of nkIdentifier:
    if node.name in env:
      return env[node.name]
    else:
      raise newException(ValueError, "Undefined variable: " & node.name)
  of nkBinaryOperation:
    let leftVal = eval(node.left, env)
    let rightVal = eval(node.right, env)
    case node.op
    of PLUS: return leftVal + rightVal
    of MINUS: return leftVal - rightVal
    of STAR: return leftVal * rightVal
    of DIVIDE: return leftVal / rightVal
    of EXPONENT: return pow(leftVal, rightVal)
    else: raise newException(ValueError, "Unknown operator in eval")
  of nkFunctionCall:
    if node.funcName == "sin":
      return sin(eval(node.args[0], env))
    elif node.funcName == "cos":
      return cos(eval(node.args[0], env))
    elif node.funcName == "log":
      if node.args.len == 1:
        return ln(eval(node.args[0], env))
      elif node.args.len == 2:
        return log(eval(node.args[0], env), eval(node.args[1], env))
      else:
        raise newException(ValueError, "log() expects 1 or 2 arguments")
    elif node.funcName == "max":
      return max(eval(node.args[0], env), eval(node.args[1], env))
    elif node.funcName == "print":
      for arg in node.args:
        case arg.kind
        of nkNumber: echo arg.value
        of nkFloat: echo arg.floatValue
        of nkString: echo arg.strValue
        of nkIdentifier:
          if arg.name in env:
            echo env[arg.name]
          else:
            echo "undefined"
        else:
          echo eval(arg, env)
      return 0.0
    else:
      raise newException(ValueError, "Unknown function: " & node.funcName)
  of nkForLoop:
    let startVal = int(eval(node.fstartExpr, env))
    let endVal = int(eval(node.fendExpr, env))
    for i in startVal ..< endVal:
      env[node.fvarName] = float(i)
      discard eval(node.fbody, env)
    return 0.0
  of nkWhileLoop:
    while eval(node.wcond, env) != 0.0:
      discard eval(node.wbody, env)
    return 0.0