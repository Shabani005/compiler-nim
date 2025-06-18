import cligen
import nim_compiler/AST
import nim_compiler/tokenizer
import tables, os

proc runFile(filename: string) =
  let input = readFile(filename)
  let tokens = tokenize(input)
  var ts = TokenStream(tokens: tokens, pos: 0)
  var env = initTable[string, float]()
  while ts.current().kind != EOF:
    let ast = parseExpr(ts)
    discard eval(ast, env)

proc main(args: seq[string]) =
  if args.len == 0:
    echo "Usage: nim_compiler <scriptfile>"
    quit(1)
  let filename = args[0]
  if not fileExists(filename):
    echo "File not found: ", filename
    quit(1)
  runFile(filename)

when isMainModule:
  dispatch(main)