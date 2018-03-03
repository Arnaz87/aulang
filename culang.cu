
import cobre.system {
  void print (string);
  string readall (string);

  int argc ();
  string args (int);
  void quit(int);
}

import culang.compiler {
  type Compiler;
  Compiler compile (string src);
  void codegen (Compiler);
  void writeCompiler(Compiler, string filename);
}

void main () {
  if (argc() == 3) {} else {
    print("Usage: " + args(0) + " <input> <output>");
    quit(1);
  }
  string src = readall(args(1));
  Compiler c = compile(src);
  codegen(c);
  writeCompiler(c, args(2));
}