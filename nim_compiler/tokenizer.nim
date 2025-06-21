import tables

# to add new tokens add to the TokenType enum, if it is a keyword (collection of tokens you add it to both the enum and the keyword constant), single character tokens are to be added to the singleCharTokens dict

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
        DIVIDE,
        IDENTIFIER,
        COMMA,
        STRING,
        FOR,
        IN,
        INDENTATIONCOLON,
        WHILE

    Token* = object
        kind*: TokenType
        lexeme*: string


const keywords = {
  "for": FOR,
  "in": IN,
  "while": WHILE
}.toTable

const singleCharTokens = {
  '+': PLUS,
  '-': MINUS,
  '*': STAR,
  '^': EXPONENT,
  '(': LBRACKET,
  ')': RBRACKET,
  '{': LCURLED,
  '}': RCURLED,
  '[': LSQUARED,
  ']': RSQUARED,
  '/': DIVIDE,
  ',': COMMA,
  ':': INDENTATIONCOLON
}.toTable

proc tokenize*(input: string): seq[Token] =
  var i = 0
  var tokens: seq[Token] = @[]
  while i < input.len:
    case input[i]
    of 'a'..'z', 'A'..'Z', '_':
      var start = i
      while i < input.len and (input[i] in {'a'..'z', 'A'..'Z', '0'..'9', '_'}):
        inc i
      let word = input[start ..< i]
      if word in keywords:
        tokens.add(Token(kind: keywords[word], lexeme: word))
      else:
        tokens.add(Token(kind: IDENTIFIER, lexeme: word))
    of '0'..'9':
      var start = i
      var hasDot = false
      while i < input.len and (input[i] in {'0'..'9'} or (input[i] == '.' and not hasDot)):
        if input[i] == '.':
          hasDot = true
        inc i
      tokens.add(Token(kind: NUMBER, lexeme: input[start ..< i]))
    of '"':
      var start = i + 1
      inc i
      while i < input.len and input[i] != '"':
        inc i
      if i >= input.len:
        raise newException(ValueError, "Unterminated string literal")
      tokens.add(Token(kind: STRING, lexeme: input[start ..< i]))
      inc i
    of '\'':
      var start = i + 1
      inc i
      while i < input.len and input[i] != '\'':
        inc i
      if i >= input.len:
        raise newException(ValueError, "Unterminated string literal")
      tokens.add(Token(kind: STRING, lexeme: input[start ..< i]))
      inc i 
    of ' ', '\n', '\r', '\t':
      inc i
    else:
      if input[i] in singleCharTokens:
        tokens.add(Token(kind: singleCharTokens[input[i]], lexeme: $input[i]))
        inc i
      else:
        echo "Unknown character: ", input[i]
        inc i
  tokens.add(Token(kind: EOF, lexeme: ""))
  return tokens