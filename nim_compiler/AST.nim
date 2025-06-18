import tokenizer
import strutils
import math

type
  ASTNodeKind* = enum
    nkNumber,
    nkBinaryOperation

  ASTNode* = ref object
    case kind*: ASTNodeKind
    of nkNumber:
      value*: int
    of nkBinaryOperation:
      op*: TokenType
      left*, right*: ASTNode

  TokenStream* = object
    tokens*: seq[Token]
    pos*: int

proc current*(ts: TokenStream): Token =
  ts.tokens[ts.pos]

proc advance*(ts: var TokenStream) =
  if ts.pos < ts.tokens.len - 1:
    inc ts.pos

proc parseNumber*(ts: var TokenStream): ASTNode =
  let tok = ts.current()
  if tok.kind == NUMBER:
    ts.advance()
    return ASTNode(kind: nkNumber, value: parseInt(tok.lexeme))
  else:
    raise newException(ValueError, "Expected a number")

proc parseExpr*(ts: var TokenStream): ASTNode
# Parse factor: numbers and parenthesized expressions
proc parseFactor(ts: var TokenStream): ASTNode =
  let tok = ts.current()
  if tok.kind == NUMBER:
    return parseNumber(ts)
  elif tok.kind == LBRACKET:
    ts.advance()
    let node = parseExpr(ts)
    if ts.current().kind != RBRACKET:
      raise newException(ValueError, "Expected ')'")
    ts.advance()
    return node
  else:
    raise newException(ValueError, "Expected a number or '('")

# Parse exponentiation
proc parseExponent*(ts: var TokenStream): ASTNode =
  var node = parseFactor(ts)
  if ts.current().kind == EXPONENT:
    let op = ts.current().kind
    ts.advance()
    let right = parseExponent(ts) # recursive for right-associativity
    node = ASTNode(kind: nkBinaryOperation, op: op, left: node, right: right)
  return node

# Parse term: *, /
proc parseTerm*(ts: var TokenStream): ASTNode =
  var node = parseExponent(ts)
  while ts.current().kind in {STAR, DIVIDE}:
    let op = ts.current().kind
    ts.advance()
    let right = parseExponent(ts)
    node = ASTNode(kind: nkBinaryOperation, op: op, left: node, right: right)
  return node

# Parse expression: +, -
proc parseExpr*(ts: var TokenStream): ASTNode =
  var node = parseTerm(ts)
  while ts.current().kind in {PLUS, MINUS}:
    let op = ts.current().kind
    ts.advance()
    let right = parseTerm(ts)
    node = ASTNode(kind: nkBinaryOperation, op: op, left: node, right: right)
  return node

# Pretty-print the AST
proc printAST*(node: ASTNode, indent: int = 0) =
  let pad = "  ".repeat(indent)
  case node.kind
  of nkNumber:
    echo pad, "Number: ", node.value
  of nkBinaryOperation:
    echo pad, "Op: ", node.op
    printAST(node.left, indent + 1)
    printAST(node.right, indent + 1)


proc eval*(node: ASTNode): float =
  case node.kind
  of nkNumber:
    return float(node.value)
  of nkBinaryOperation:
    let leftVal = eval(node.left)
    let rightVal = eval(node.right)
    case node.op
    of PLUS:
      return leftVal + rightVal
    of MINUS:
      return leftVal - rightVal
    of STAR:
      return leftVal * rightVal
    of DIVIDE:
      return leftVal / rightVal
    of EXPONENT:
      return pow(leftVal, rightVal)
    else:
      raise newException(ValueError, "Unknown operator in eval")
  