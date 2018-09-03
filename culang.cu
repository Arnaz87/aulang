
import auro.system {
  void println (string);
  int argc ();
  string argv (int);
  void exit(int);
}

import culang.util { string readall (string); }

import culang.compiler {
  type Compiler;
  Compiler compile (string src);
  void codegen (Compiler);
  void writeCompiler(Compiler, string filename);
}

void main () {
  if (argc() == 3) {} else {
    println("Usage: " + argv(0) + " <input> <output>");
    exit(1);
  }
  string src = readall(argv(1));
  Compiler c = compile(src);
  codegen(c);
  writeCompiler(c, argv(2));
}