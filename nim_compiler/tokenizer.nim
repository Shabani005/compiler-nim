# there must be a way to make it more plug and play but this is good enough for now

type 
    TokenType* = enum
        PLUS, 
        MINUS, 
        STAR, 
        EXPONENT, 
        LBRACKET, 
        RBRACKET, 
        LCURLED, 
        RCURLED, 
        LSQUARED, 
        RSQUARED,
        NUMBER, 
        EOF,
        DIVIDE

    Token* = object
        kind*: TokenType
        lexeme*: string

proc tokenize*(input: string): seq[Token] =
  var i = 0
  var tokens: seq[Token] = @[]
  while i < input.len:
    case input[i]
    of ' ':
      inc i
    of '+':
      tokens.add(Token(kind: PLUS, lexeme: "+"))
      inc i
    of '-':
      tokens.add(Token(kind: MINUS, lexeme: "-"))
      inc i
    of '*':
      tokens.add(Token(kind: STAR, lexeme: "*"))
      inc i
    of '^':
      tokens.add(Token(kind: EXPONENT, lexeme: "^"))
      inc i
    of '(':
      tokens.add(Token(kind: LBRACKET, lexeme: "("))
      inc i
    of ')':
      tokens.add(Token(kind: RBRACKET, lexeme: ")"))
      inc i
    of '{':
      tokens.add(Token(kind: LCURLED, lexeme: "{"))
      inc i
    of '}':
      tokens.add(Token(kind: RCURLED, lexeme: "}"))
      inc i
    of '[':
      tokens.add(Token(kind: LSQUARED, lexeme: "["))
      inc i
    of ']':
      tokens.add(Token(kind: RSQUARED, lexeme: "]"))
      inc i
    of '/':
        tokens.add(Token(kind: DIVIDE, lexeme: "/"))
        inc i 
    of '0'..'9':
      var start = i
      while i < input.len and input[i] in {'0'..'9'}:
        inc i
      tokens.add(Token(kind: NUMBER, lexeme: input[start ..< i]))
    else:
      echo "Unknown character: ", input[i]
      inc i
  tokens.add(Token(kind: EOF, lexeme: ""))
  return tokens


let tokens = tokenize("42 + (7 - 3) * 2/5")
for t in tokens:
  echo t.kind, " : ", t.lexeme