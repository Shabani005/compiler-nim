import nim_compiler/AST
import nim_compiler/tokenizer

proc main() =
  let input = "2 + 3 * (4 - 1) ^ 2 / 5"
  let tokens = tokenize(input)
  var ts = TokenStream(tokens: tokens, pos: 0)
  let ast = parseExpr(ts)
  echo eval(ast)

main()