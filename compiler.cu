
/* Cobre 0.5

import cobre.system {
  void print (string);
  string readall (string);

  void quit (int);

  void error (string) as syserr;

  type file as file; 
  file open (string filename, string mode);
  void write (file, string);
  void writebyte (file, int);
}

void println (string msg) { print(msg); }
*/

// Cobre 0.6

import cobre.system {
  void println (string);
  void exit (int);
  void error (string) as syserr;
}

import cobre.io { type file; }
import culang.util {
  string readall (string);
  file _open (string filename, string dummy) as open;
  void _write (file, string) as write;
  void writebyte (file, int);
}
void quit (int status) { exit(status); }
//

import cobre.string {
  string itos(int);
  int length (string) as strlen;

  int codeof (char);
  char, int charat(string, int);
}

import culang.parser {
  type Node as Node {
    string tp;
    string val;
    int line;

    int len ();
    Node child (int);
    void print (string);
  }
  Node parse (string);
}

struct Pair {
  string key;
  int id;
}

struct Map {
  Pair[] arr;
  int pos;

  int get (Map this, string key) {
    int i = this.pos;
    // Look from the last inserted pair to the first
    while (i > 0) {
      i = i-1;
      Pair pair = this.arr[i];
      if (key == pair.key) return pair.id;
    }
    return 0-1;
    //print("Error: \"" + key + "\" not found in map");
    //quit(1);
  }

  void set (Map this, string key, int value) {
    Pair pair = new Pair(key, value);
    int p = this.pos;
    if (p < this.arr.len()) {
      this.arr[p] = pair;
      this.pos = p+1;
    } else {
      this.arr.push(pair);
      this.pos = this.arr.len();
    }
  }

  void print (Map this, string ident) {
    int i = 0;
    while (i < this.pos) {
      Pair pair = this.arr[i];
      println(ident + pair.key + ": " + itos(pair.id));
      i = i+1;
    }
  }

  bool any (Map this) { return this.arr.len() > 0; }
}

Map newMap () { return new Map(new Pair[](), 0); }

struct Module {
  string kind; // global, define, build, hidden
  string name;
  string argument;
  string[] items;
  string[] itemnames;
  int line;
}

Module globalModule (string name, int line) {
  return new Module("global", name, "", new string[](), new string[](), line);
}

Module defineModule (string[] items, string[] itemnames, int line) {
  return new Module("define", "", "", items, itemnames, line);
}

Module buildModule (string base, string argument, int line) {
  return new Module("build", base, argument, new string[](), new string[](), line);
}

Module useModule (string base, string name, int line) {
  return new Module("use", base, name, new string[](), new string[](), line);
}

struct Type {
  int id;
  string mod;
  string name;
  Map getters;
  Map setters;
  Map methods;
  Map casts;
  int constructor;
}

Type newType (Compiler c, string mod, string name) {
  int id = c.types.len();
  Type t = new Type(id, mod, name, newMap(), newMap(), newMap(), newMap(), 0-1);
  c.types.push(t);
  return t;
}

import cobre.`null` (Node) {
  type `` as NodeNull {
    bool isnull ();
    Node get ();
  }
  NodeNull `null` () as nullNode;
  NodeNull `new` (Node) as newNullNode;
}

struct Line {
  int inst;
  int line;
}

struct Function {
  int id;
  string mod; // "" for defined function
  string name;
  string[] outs;
  string[] ins;
  string[] in_names;
  NodeNull node;
  Inst[] code;
  int line;
  Line[] lineinfo;

  bool hasCode (Function this) {
    if (this.node.isnull()) return 1<0;
    else return 0<1;
  }
}

Function newFunction (Compiler c) {
  int id = c.functions.len();
  Function f = new Function(id, "", "", new string[](), new string[](), new string[](), nullNode(), new Inst[](), 0, new Line[]());
  c.functions.push(f);
  return f;
}

struct Constant {
  string kind;
  string val;
}

struct Inst {
  string inst;
  int a;
  int b;
  string lbl;
  int[] args;
}

struct Cast {
  string from;
  string to;
  int fn;
}

struct Compiler {
  Node tree;
  Map typeMap;
  Map fnMap;
  Map modMap;
  Module[] modules;
  Type[] types;
  Function[] functions;
  Map tpExports;
  Map fnExports;
  Map modExports;
  Constant[] constants;
  Cast[] casts;

  int gettp (Compiler this, string name, int line) {
    int id = this.typeMap[name];
    if (id < 0) errorln("Unknown type \"" + name + "\"", line);
    return id;
  }

  // Returns the id and the type, which can be:
  // -1: not found, 0: module, 1: type, 2: function, 3: constant
  int, int getitem (Compiler this, string name, int line) {
    int id = this.typeMap[name];
    if (id >= 0) return id, 1;
    int id = this.fnMap[name];
    if (id >= 0) return id, 2;
    int id = this.modMap[name];
    if (id >= 0) return id, 0;
    errorln("Unkown item \"" + name + "\"", line);
  }

  void setModule(Compiler this, string key, Module mod) {
    int id = this.modules.len();
    this.modules.push(mod);
    this.modMap[key] = id;
  }

  string pushModule (Compiler this, Module mod) {
    int id = this.modules.len();
    this.modules.push(mod);
    string name = "__mod_" + itos(id);
    this.modMap[name] = id;
    return name;
  }
}


// =============================== //
//              Codegen            //
// =============================== //

struct Scope {
  Compiler c;
  Function fn;
  Map vars;
  Map labels;
  int[] regtypes;
  int regcount;
  int lblcount;

  int getvar (Scope this, string name, Node node) {
    int id = this.vars[name];
    if (id < 0) error(node, "Unknown variable \"" + name + "\"");
    return id;
  }

  int gettp (Scope this, string name) {
    return this.c.typeMap[name];
  }

  int decl (Scope this, int tp) {
    int reg = this.regcount;
    this.regtypes.push(tp);
    this.regcount = reg+1;
    return reg;
  }

  void inst (Scope this, string inst, int a, int b) {
    this.fn.code.push(new Inst(inst, a, b, "", new int[]()));
  }

  void flow (Scope this, string inst, string lbl, int b) {
    this.fn.code.push(new Inst(inst, 0, b, lbl, new int[]()));
  }

  string lbl (Scope this) {
    int lbl = this.lblcount;
    this.lblcount = lbl + 1;
    return itos(lbl);
  }

  void call (Scope this, int fn, int[] args) {
    this.fn.code.push(new Inst("call", fn, 0, "", args));
  }

  void constant (Scope this, int id) {
    int funlen = this.c.functions.len();
    this.call(funlen + id, new int[]());
  }

  void uselbl (Scope this, string name) {
    this.labels[name] = this.fn.code.len();
  }
}

string compileTypeName (Compiler this, Node node) {
  int id; string name;
  if (node.tp == "array") {
    string innerName = compileTypeName(this, node.child(0));
    name = innerName + "[]";
    if (this.typeMap[name] < 0) {
      string[] args = new string[](), argnames = new string[]();
      args.push(innerName);
      argnames.push("0");

      string basemod = this.pushModule(globalModule("cobre\x1farray", node.line));
      string argmod = this.pushModule(defineModule(args, argnames, node.line));
      string moduleid = this.pushModule(buildModule(basemod, argmod, node.line));

      Type tp = newType(this, moduleid, "");
      this.typeMap[name] = tp.id;

      Function getfn = newFunction(this);
      getfn.mod = moduleid;
      getfn.ins.push(name);
      getfn.ins.push("int");
      getfn.outs.push(innerName);
      getfn.name = "get";
      tp.methods["get"] = getfn.id;

      Function setfn = newFunction(this);
      setfn.mod = moduleid;
      setfn.ins.push(name);
      setfn.ins.push("int");
      setfn.ins.push(innerName);
      setfn.name = "set";
      tp.methods["set"] = setfn.id;

      Function pushfn = newFunction(this);
      pushfn.mod = moduleid;
      pushfn.ins.push(name);
      pushfn.ins.push(innerName);
      pushfn.name = "push";
      tp.methods["push"] = pushfn.id;

      Function lenfn = newFunction(this);
      lenfn.mod = moduleid;
      lenfn.ins.push(name);
      lenfn.outs.push("int");
      lenfn.name = "len";
      tp.methods["len"] = lenfn.id;

      Function emptyfn = newFunction(this);
      emptyfn.mod = moduleid;
      emptyfn.outs.push(name);
      emptyfn.name = "empty";
      tp.constructor = emptyfn.id;
    }
    return name;
  } else if (node.tp == "type") {
    return node.val;
  } else syserr("???");
}

void errorln (string msg, int line) {
  string pos = "";
  if (line < 0) {} else {
    pos = ", at line " + itos(line);
  }
  println("Compile error: " + msg + pos);
  quit(1);
}

void error (Node node, string msg) { errorln(msg, node.line); }

Scope newScope (Compiler c, Function fn) {
  return new Scope(c, fn, newMap(), newMap(), new int[](), 0, 0);
}

int[] compileCall (Scope this, Node node) {
  Node base = node.child(0);
  Node argsnode = node.child(1);
  if (base.tp == "var") {
    string name = base.val;
    int id = this.c.fnMap[name];
    if (id < 0) error(node, "Unknown function \"" + name + "\"");
    Function fn = this.c.functions[id];

    if (argsnode.len() == fn.ins.len()) {} else {
      error(node, "Function " + name + " accepts " + itos(fn.ins.len()) +
        " arguments, but " + itos(argsnode.len()) + " were passed");
    }

    int[] args = new int[]();
    int i = 0;
    while (i < argsnode.len()) {
      int reg = compileExpr(this, argsnode.child(i));
      args.push(reg);
      i = i+1;
    }

    this.fn.lineinfo.push(new Line(this.fn.code.len(), node.line));
    this.call(id, args);

    int[] rets = new int[]();
    int i = 0;
    while (i < fn.outs.len()) {
      int tpid = this.c.typeMap[fn.outs[i]];
      rets.push(this.decl(tpid));
      i = i+1;
    }

    return rets;
  } else if (base.tp == "field") {
    string name = base.val;
    int basereg = compileExpr(this, base.child(0));
    Type tp = this.c.types[this.regtypes[basereg]];
    int fnid = tp.methods[name];
    if (fnid < 0) error(base, "Unknown method \"" + name + "\"");
    Function fn = this.c.functions[fnid];

    if (argsnode.len()+1 == fn.ins.len()) {} else {
      error(node, "Method " + name + " accepts " + itos(fn.ins.len()) +
        " arguments, but " + itos(argsnode.len()+1) + " were passed");
    }

    int[] args = new int[]();
    args.push(basereg);
    int i = 0;
    while (i < argsnode.len()) {
      int reg = compileExpr(this, argsnode.child(i));
      args.push(reg);
      i = i+1;
    }

    this.fn.lineinfo.push(new Line(this.fn.code.len(), node.line));
    this.call(fnid, args);

    int[] rets = new int[]();
    int i = 0;
    while (i < fn.outs.len()) {
      int tpid = this.c.typeMap[fn.outs[i]];
      rets.push(this.decl(tpid));
      i = i+1;
    }

    return rets;
  } else {
    error(node, "Call only supported for top level functions");
  }
}

int compileExpr (Scope this, Node node) {
  if (node.tp == "var") return this.getvar(node.val, node);
  if (node.tp == "num") {
    int id = this.c.constants.len();
    this.c.constants.push(new Constant("int", node.val));
    this.constant(id);
    int tp = this.gettp("int");
    int reg = this.decl(tp);
    return reg;
  }
  if (node.tp == "str") {
    int rawid = this.c.constants.len();
    this.c.constants.push(new Constant("bin", node.val));
    int id = this.c.constants.len();
    this.c.constants.push(new Constant("str", ""));

    int[] args;

    // TODO: Add static instructions
    int tp = this.gettp("string");
    this.constant(id);
    int reg = this.decl(tp);
    return reg;
  }
  if (node.tp == "binop") {
    int a = compileExpr(this, node.child(0));
    int b = compileExpr(this, node.child(1));
    int tpa = this.regtypes[a];
    int tpb = this.regtypes[b];

    int[] args = new int[](); 
    args.push(a); args.push(b);
    // int
    if (tpa == 2) if (tpb == 2) {
      if     (node.val == "==") this.call(1, args);
      else if (node.val == ">") this.call(3, args);
      else if (node.val == "<") this.call(4, args);
      else if (node.val == "+") this.call(2, args);
      else if (node.val == "-") this.call(7, args);
      else if (node.val == "*") this.call(8, args);
      else if (node.val == "/") this.call(9, args);
      else if (node.val == ">=") this.call(10, args);
      else if (node.val == "<=") this.call(11, args);
      else {
        error(node, "Unsupported int operation: " + node.val);
      }
      return this.decl(2);
    }
    // string
    if (tpa == 3) if (tpb == 3) {
      if     (node.val == "==") this.call(5, args);
      else if (node.val == "+") this.call(6, args);
      else {
        error(node, "Unsupported string operation: " + node.val);
      }
      return this.decl(3);
    }
    Type xtpa = this.c.types[tpa];
    Type xtpb = this.c.types[tpb];
    error(node, "Operation " + node.val + " not supported for " + xtpa.name + " and " + xtpb.name);
  }
  if (node.tp == "call") {
    int[] rets = compileCall(this, node);
    if (rets.len() == 0) {
      error(node, "Function is of type void");
    }
    return rets[0];
  }
  if (node.tp == "field") {
    int basereg = compileExpr(this, node.child(0));
    Type tp = this.c.types[this.regtypes[basereg]];
    int fnid = tp.getters[node.val];
    if (fnid < 0) error(node, "No getter for field \"" + node.val + "\"");

    Function fn = this.c.functions[fnid];
    int rettp = this.c.gettp(fn.outs[0], fn.line);

    int[] args = new int[]();
    args.push(basereg);
    this.call(fnid, args);
    return this.decl(rettp);
  }
  if (node.tp == "index") {
    int index = compileExpr(this, node.child(1));
    int base = compileExpr(this, node.child(0));
    Type tp = this.c.types[this.regtypes[base]];
    int fnid = tp.methods["get"];
    if (fnid < 0) error(node, "Unknown method \"get\"");
    Function fn = this.c.functions[fnid];
    if (fn.outs.len() == 1) {} else error(node, "get method has to return 1 value");
    int rettp = this.c.gettp(fn.outs[0], fn.line);

    if (fn.ins.len() == 2) {
      int[] args = new int[]();
      args.push(base);
      args.push(index);
      this.call(fnid, args);
      return this.decl(rettp);
    } else error(node, "get method must receive 2 parameters");
  }
  if (node.tp == "new") {
    Node ch = node.child(0);

    string tpname = compileTypeName(this.c, ch);
    int tpid = this.gettp(tpname);

    Type tp = this.c.types[tpid];
    int fnid = tp.constructor;
    if (fnid < 0) error(node, "Unknown constructor for " + tpname);
    Function fn = this.c.functions[fnid];
    int expected = fn.ins.len();
    Node exprlist = node.child(1);
    int count = exprlist.len();
    if (expected == count) {} else {
      error(node, "Constructor expects " + itos(expected) + " parameters, but " + itos(count) + " were passed");
    }

    int[] args = new int[]();
    int i = 0;
    while (i < count) {
      int reg = compileExpr(this, exprlist.child(i));
      args.push(reg);
      i = i+1;
    }
    this.call(fnid, args);
    return this.decl(tpid);
  }
  if (node.tp == "cast") {
    int basereg = compileExpr(this, node.child(0));
    string tpname = compileTypeName(this.c, node.child(1));
    Type tp = this.c.types[this.regtypes[basereg]];
    int fnid = tp.casts[tpname];
    if (fnid < 0) error(node, "Unknown cast to \"" + tpname + "\"");

    Function fn = this.c.functions[fnid];
    int rettp = this.c.gettp(tpname, node.line);

    int[] args = new int[]();
    args.push(basereg);
    this.call(fnid, args);
    return this.decl(rettp);
  }
  error(node, "Unsupported expression: " + node.tp);
}

void assign (Scope this, Node left, int reg) {
  int valtp = this.regtypes[reg];
  if (left.tp == "var") {
    int id = this.getvar(left.val, left);
    if (this.regtypes[id] == valtp) {
      this.inst("set", id, reg);
    } else {
      error(left, "Type mismatch");
    }
  } else if (left.tp == "index") {
    int index = compileExpr(this, left.child(1));
    int base = compileExpr(this, left.child(0));
    Type tp = this.c.types[this.regtypes[base]];
    int fnid = tp.methods["set"];
    if (fnid < 0) error(left, "Unknown method \"set\"");
    Function fn = this.c.functions[fnid];
    if (fn.outs.len() > 0) error(left, "set method has to be void");
    if (fn.ins.len() == 3) {
      int[] args = new int[]();
      args.push(base);
      args.push(index);
      args.push(reg);
      this.call(fnid, args);
    } else error(left, "set method must receive 3 parameters");
  } else if (left.tp == "field") {
    int basereg = compileExpr(this, left.child(0));
    Type tp = this.c.types[this.regtypes[basereg]];
    int fnid = tp.setters[left.val];
    if (fnid < 0) error(left, "No setter for field \"" + left.val + "\"");

    Function fn = this.c.functions[fnid];
    //int valtp = this.c.typeMap[fn.ins[0]];

    int[] args = new int[]();
    args.push(basereg);
    args.push(reg);
    this.call(fnid, args);
  } else {
    error(left, "Cannot assign to a " + left.tp + " expression");
  }
}

void compileStmt (Scope this, Node node) {
  if (node.tp == "block") {
    int i = 0;
    while (i < node.len()) {
      compileStmt(this, node.child(i));
      i = i+1;
    }
    return;
  }
  if (node.tp == "decl") {
    int tp = this.gettp(compileTypeName(this.c, node.child(0)));
    int i = 1;
    while (i < node.len()) {
      Node part = node.child(i);
      string name = part.val;
      int reg;
      if (part.len() > 0) {
        Node val = part.child(0);
        reg = compileExpr(this, part.child(0));
        if (val.tp == "var") {
          this.inst("var", 0,0);
          int newreg = this.decl(tp);
          this.inst("set", newreg, reg);
          reg = newreg;
        }
      } else {
        this.inst("var", 0,0);
        reg = this.decl(tp);
      }
      this.vars[name] = reg;
      i = i+1;
    }
    return;
  }
  if (node.tp == "assignment") {
    Node left = node.child(0);
    Node right = node.child(1);

    if (left.len() > 1) {
      if (right.tp == "call") {
        int[] regs = compileCall(this, right);
        if (regs.len() < left.len()) {
          error(node, "Cannot assign " + itos(regs.len()) + " values to " + itos(left.len()) + " expressions");
        }
        int i = 0;
        while (i < left.len()) {
          assign(this, left.child(i), regs[i]);
          i = i+1;
        }
        return;
      } else {
        error(node, "Multiple assignments only works with function calls");
      }
    } else {
      int r = compileExpr(this, right);
      assign(this, left.child(0), r);
      return;
    }
  }
  if (node.tp == "while") {
    string start = this.lbl();
    string end = this.lbl();
    this.uselbl(start);
    int cond = compileExpr(this, node.child(0));
    this.flow("nif", end, cond);
    compileStmt(this, node.child(1));
    this.flow("jmp", start, 0);
    this.uselbl(end);
    return;
  }
  if (node.tp == "if") {
    string els = this.lbl();
    string end = this.lbl();
    int cond = compileExpr(this, node.child(0));
    this.flow("nif", els, cond);
    compileStmt(this, node.child(1));
    this.flow("jmp", end, 0);
    this.uselbl(els);
    if (node.len() == 3) {
      compileStmt(this, node.child(2));
    }
    this.uselbl(end);
    return;
  }
  if (node.tp == "call") {
    int[] rets = compileCall(this, node);
    return;
  }
  if (node.tp == "return") {
    Node exprlist = node.child(0);
    int count = exprlist.len();
    int expected = this.fn.outs.len();
    if (count == expected) {} else {
      error(node, "Function returns " + itos(expected) + " values, but " + itos(count) + " were returned");
    }
    int[] args = new int[]();
    int i = 0;
    while (i < count) {
      Node expr = exprlist.child(i);
      int reg = compileExpr(this, expr);
      args.push(reg);
      i = i+1;
    }
    this.fn.code.push(new Inst("end", 0, 0, "", args));
    return;
  }
  if (node.tp == "goto") {
    this.flow("jmp", node.val, 0); // jmp
    return;
  }
  if (node.tp == "label") {
    this.uselbl(node.val);
    return;
  }
  error(node, "Unknown statement: " + node.tp);
}

void codegen (Compiler c) {
  int i = 0;
  while (i < c.functions.len()) {
    Function fn = c.functions[i];

    if (fn.hasCode()) {
      Scope scope = newScope(c, fn);

      int j = 0;
      while (j < fn.ins.len()) {
        int tp = scope.gettp(fn.ins[j]);
        int reg = scope.decl(tp);
        scope.vars[fn.in_names[j]] = reg;
        j = j+1;
      }

      compileStmt(scope, fn.node.get());

      // Automatic void return
      if (fn.outs.len() == 0)
        scope.inst("end", 0,0);

      // Convert label names to label indices
      int j = 0;
      while (j < fn.code.len()) {
        Inst inst = fn.code[j];
        string k = inst.inst;
        if (k == "jmp") inst.a = scope.labels[inst.lbl];
        if (k == "jif") inst.a = scope.labels[inst.lbl];
        if (k == "nif") inst.a = scope.labels[inst.lbl];
        j = j+1;
      }
    }

    i = i+1;
  }
}

// =============================== //
//             Compiling           //
// =============================== //

void makeBasics (Compiler c) {
  c.setModule("argument", new Module("hidden", "", "", new string[](), new string[](), 0-1));
  // Exported module
  c.pushModule(new Module("hidden", "", "", new string[](), new string[](), 0-1));

  string boolM = c.pushModule(globalModule("cobre\x1fbool", 0-1)); // #2
  string intM = c.pushModule(globalModule("cobre\x1fint", 0-1)); // #3
  string strM = c.pushModule(globalModule("cobre\x1fstring", 0-1)); // #4
  string bufferM = c.pushModule(globalModule("cobre\x1fbuffer", 0-1)); // #5

  newType(c, boolM, "bool");
  newType(c, bufferM, "buffer");
  newType(c, intM, "int");
  newType(c, strM, "string");
  newType(c, strM, "char");

  c.typeMap["bool"] = 0;
  c.typeMap["__bin__"] = 1;
  c.typeMap["int"] = 2;
  c.typeMap["string"] = 3;
  c.typeMap["char"] = 4;

  // #0
  Function fn = newFunction(c);
  fn.mod = strM;
  fn.name = "new";
  fn.ins.push("__bin__");
  fn.outs.push("string");

  // #1
  Function fn = newFunction(c);
  fn.mod = intM;
  fn.name = "eq";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("bool");

  // #2
  Function fn = newFunction(c);
  fn.mod = intM;
  fn.name = "add";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("int");

  // #3
  Function fn = newFunction(c);
  fn.mod = intM;
  fn.name = "gt";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("bool");

  // #4
  Function fn = newFunction(c);
  fn.mod = intM;
  fn.name = "lt";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("bool");

  // #5
  Function fn = newFunction(c);
  fn.mod = strM;
  fn.name = "eq";
  fn.ins.push("string");
  fn.ins.push("string");
  fn.outs.push("bool");

  // #6
  Function fn = newFunction(c);
  fn.mod = strM;
  fn.name = "concat";
  fn.ins.push("string");
  fn.ins.push("string");
  fn.outs.push("string");

  // #7
  Function fn = newFunction(c);
  fn.mod = intM;
  fn.name = "sub";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("int");

  // #8
  Function fn = newFunction(c);
  fn.mod = intM;
  fn.name = "mul";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("int");

  // #9
  Function fn = newFunction(c);
  fn.mod = intM;
  fn.name = "div";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("int");

  // #10
  Function fn = newFunction(c);
  fn.mod = intM;
  fn.name = "ge";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("bool");

  // #11
  Function fn = newFunction(c);
  fn.mod = intM;
  fn.name = "le";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("bool");
}

// Basic functions:
// 0: new string
// 1: int eq
// 2: int add
// 3: int greater than
// 4: int less than
// 5: string eq
// 6: string concat
// 7: int sub
// 8: int mul
// 9: int div
// 10: int greater or equal
// 11: int less or equal

Function, string fnFromNode (Compiler c, Node node) {
  string alias = node.child(2).val;
  if (alias == "") alias = node.val;
  Function f = newFunction(c);
  f.name = node.val;
  f.line = node.line;

  Node innd = node.child(0);
  int k = 0;
  while (k < innd.len()) {
    Node argnd = innd.child(k);
    f.ins.push(compileTypeName(c, argnd.child(0)));
    f.in_names.push(argnd.child(1).val);
    k = k+1;
  }

  Node outnd = node.child(1);
  int k = 0;
  while (k < outnd.len()) {
    f.outs.push(compileTypeName(c, outnd.child(k)));
    k = k+1;
  }

  return f, alias;
}

void thisArg (Function fn, string arg) {
  string[] oldArr = fn.ins;
  string[] newArr = new string[]();
  newArr.push(arg);
  int i = 0;
  while (i < oldArr.len()) {
    newArr.push(oldArr[i]);
    i = i+1;
  }
  fn.ins = newArr;

  string[] oldArr = fn.in_names;
  string[] newArr = new string[]();
  newArr.push("this");
  int i = 0;
  while (i < oldArr.len()) {
    newArr.push(oldArr[i]);
    i = i+1;
  }
  fn.in_names = newArr;
}

void makeImports (Compiler c) {
  int i = 0;
  while (i < c.tree.len()) {
    Node node = c.tree.child(i);
    string modid = "";
    if (node.tp == "import-module") {
      modid = node.val;
    } else if (node.tp == "import") {
      modid = c.pushModule(globalModule(node.val, node.line));
    }
    if (modid == "") {} else {
      if (node.len() == 0) error(node, "bodyless imports are not supported");

      Node bodynode = node.child(0);
      Node argsnd = bodynode.child(0);
      if (argsnd.tp == "none") {
        // Nothing, no arguments
      } else if (argsnd.tp == "arglist") {
        string[] args = new string[]();
        string[] argnames = new string[]();
        int j = 0;
        while (j < argsnd.len()) {
          Node argnd = argsnd.child(j);
          if (argnd.tp == "name") {
            args.push(argnd.val);
            argnames.push(itos(j));
          } else if (argnd.tp == "alias") {
            args.push(argnd.child(0).val);
            argnames.push(argnd.val);
          } else error(node, "Unknown " + itos(j) + "-th argument node: " + argnd.tp);
          j = j+1;
        }

        string argmodid = c.pushModule(defineModule(args, argnames, node.line));
        modid = c.pushModule(buildModule(modid, argmodid, node.line));
      } else if (argsnd.tp == "module") {
        error(node, "Module arguments not yet supported");
      } else {
        error(node, "Unknown argument node: " + argsnd.tp);
      }

      int j = 1; // Skip first child, it's the argument node
      while (j < bodynode.len()) {
        Node item = bodynode.child(j);

        if (item.tp == "type") {
          string tp_alias = item.child(0).val;
          if (tp_alias == "") tp_alias = item.val;
          Type tp = newType(c, modid, item.val);
          c.typeMap[tp_alias] = tp.id;

          int k = 1;
          while (k < item.len()) {
            Node member = item.child(k);

            string suffix = "";
            if (item.val == "") {} else { suffix = "\x1d" + item.val; }

            if (member.tp == "function") {
              Function f; string fn_alias;
              f, fn_alias = fnFromNode(c, member);
              f.mod = modid;
              f.name = f.name + suffix;
              thisArg(f, tp_alias);
              tp.methods[fn_alias] = f.id;
            } else if (member.tp == "decl") {
              string name = member.val;
              string tpnm = member.child(0).val;

              string getname = name + "\x1dget" + suffix;
              string setname = name + "\x1dset" + suffix;

              Function getfn = newFunction(c);
              getfn.name = name + "\x1dget" + suffix;
              getfn.ins.push(tp_alias);
              getfn.outs.push(tpnm);
              getfn.mod = modid;

              Function setfn = newFunction(c);
              setfn.name = name + "\x1dset" + suffix;
              setfn.ins.push(tp_alias);
              setfn.ins.push(tpnm);
              setfn.mod = modid;

              tp.getters[name] = getfn.id;
              tp.setters[name] = setfn.id;
            } else if (member.tp == "new") {
              Function f = newFunction(c);

              Node innd = member.child(0);
              int l = 0;
              while (l < innd.len()) {
                Node argnd = innd.child(l);
                f.ins.push(argnd.child(0).val);
                f.in_names.push(argnd.child(1).val);
                l = l+1;
              }

              f.mod = modid;
              f.name = "new";
              f.outs.push(tp_alias);
              tp.constructor = f.id;

            } else {
              println("Unknown type member " + member.tp);
              quit(1);
            }
            k = k+1;
          }
        } else if (item.tp == "function") {
          Function f; string alias;
          f, alias = fnFromNode(c, item);
          f.mod = modid;
          c.fnMap[alias] = f.id;
        } else if (item.tp == "module") {
          Module mod = useModule(modid, item.val, item.line);
          string alias = item.child(0).val;
          if (alias == "") alias = item.val;
          c.setModule(alias, mod);
        } else {
          println("Unknown imported item: " + item.tp);
          quit(1);
        }
        j = j+1;
      }
    }

    if (node.tp == "module-assign") {
      string name = node.val;
      Node valnode = node.child(0);
      if (valnode.tp == "import") {
        c.setModule(name, globalModule(valnode.val, node.line));
      } else error(node, "Only import assignments");
    } else if (node.tp == "module-def") {
      error(node, "Module definitions not yet supported");
    }
    i = i+1;
  }
}

void makeTypes (Compiler c) {
  int i = 0;
  while (i < c.tree.len()) {
    Node node = c.tree.child(i);
    bool pub = 0<1;
    if (node.tp == "private") {
      node = node.child(0);
      pub = 1<0;
    }

    if (node.tp == "type") {
      string base = compileTypeName(c, node.child(0));
      string[] args = new string[](), argnames = new string[]();
      args.push(base);
      argnames.push("0");

      string basemod = c.pushModule(globalModule("cobre\x1ftypeshell", node.line));
      string argmod = c.pushModule(defineModule(args, argnames, node.line));
      string moduleid = c.pushModule(buildModule(basemod, argmod, node.line));

      string alias = node.val;
      Type tp = newType(c, moduleid, "");
      c.typeMap[alias] = tp.id;
      if (pub) c.tpExports[alias] = tp.id;

      Function from = newFunction(c);
      from.mod = moduleid;
      from.ins.push(base);
      from.outs.push(alias);
      from.name = "new";

      Function to = newFunction(c);
      to.mod = moduleid;
      to.ins.push(alias);
      to.outs.push(base);
      to.name = "get";

      c.casts.push(new Cast(base, alias, from.id));
      c.casts.push(new Cast(alias, base, to.id));
    }
    if (node.tp == "struct") {
      string[] args = new string[]();
      string[] argnames = new string[]();

      string basemod = c.pushModule(globalModule("cobre\x1frecord", node.line));
      string argmod = c.pushModule(defineModule(args, argnames, node.line));
      string moduleid = c.pushModule(buildModule(basemod, argmod, node.line));

      string alias = node.val;
      Type tp = newType(c, moduleid, "");
      c.typeMap[alias] = tp.id;
      if (pub) c.tpExports[alias] = tp.id;

      Function constructor = newFunction(c);
      constructor.mod = moduleid;
      constructor.name = "new";
      constructor.outs.push(alias);
      tp.constructor = constructor.id;

      int fieldid = 0;
      int j = 0;
      while (j < node.len()) {
        Node member = node.child(j);
        if (member.tp == "decl") {
          string name = member.val;
          string ftp = compileTypeName(c, member.child(0));

          argnames.push(itos(args.len()));
          args.push(ftp);
          constructor.ins.push(ftp);

          Function getter = newFunction(c);
          getter.line = member.line;
          getter.mod = moduleid;
          getter.ins.push(alias);
          getter.outs.push(ftp);
          getter.name = "get" + itos(fieldid);

          Function setter = newFunction(c);
          setter.line = member.line;
          setter.mod = moduleid;
          setter.ins.push(alias);
          setter.ins.push(ftp);
          setter.name = "set" + itos(fieldid);

          tp.getters[name] = getter.id;
          tp.setters[name] = setter.id;

          if (pub) c.fnExports[name + "\x1dget\x1d" + alias] = getter.id;
          if (pub) c.fnExports[name + "\x1dset\x1d" + alias] = setter.id;

          fieldid = fieldid + 1;
        } else if (member.tp == "function") {
          Function f; string fn_alias;
          f, fn_alias = fnFromNode(c, member);
          f.name = fn_alias;
          f.node = newNullNode(member.child(3));
          tp.methods[fn_alias] = f.id;
          c.fnExports[fn_alias + "\x1d" + alias] = f.id;
        } else {
          println("Unknown struct member " + member.tp);
          quit(1);
        }
        j = j+1;
      }
    }
    i = i+1;
  }
}

void makeCasts (Compiler c) {
  int i = 0;
  while (i < c.casts.len()) {
    Cast cast = c.casts[i];
    int tpid = c.typeMap[cast.from];
    Type tp = c.types[tpid];
    tp.casts[cast.to] = cast.fn;
    i = i+1;
  }
}

void makeFunctions (Compiler c) {
  int i = 0;
  while (i < c.tree.len()) {
    Node node = c.tree.child(i);
    bool pub = 0<1;
    if (node.tp == "private") {
      node = node.child(0);
      pub = 1<0;
    }
    if (node.tp == "function") {
      Function f; string name;
      f, name = fnFromNode(c, node);
      f.name = name;
      f.node = newNullNode(node.child(3));
      c.fnMap[name] = f.id;
      if (pub) c.fnExports[name] = f.id;
    }
    i = i+1;
  }
}

void makeExports (Compiler c) {
  int i = 0;
  while (i < c.tree.len()) {
    Node node = c.tree.child(i);
    if (node.tp == "export") {
      string name = node.val;
      int k, id;
      id, k = c.getitem(node.child(0).val, node.line);
      if (k == 1) c.tpExports[name] = id;
      else if (k == 2) c.fnExports[name] = id;
      else if (k == 0) c.modExports[name] = id;
      else error(node, "Cannot export " + name);
    }
    i = i+1;
  }
}

Compiler compile (string src) {
  Node parsed = parse(src);

  Compiler c = new Compiler(
    parsed,
    newMap(),
    newMap(),
    newMap(),
    new Module[](),
    new Type[](),
    new Function[](),
    newMap(),
    newMap(),
    newMap(),
    new Constant[](),
    new Cast[]()
  );

  makeBasics(c);
  makeImports(c);
  makeTypes(c);
  makeCasts(c);
  makeFunctions(c);
  makeExports(c);

  return c;
}

// =============================== //
//           File Writing          //
// =============================== //

void wnum (file f, int n) {
  if (n > 127) wnum(f, n/128);
  while (n > 127) n = n - ((n/128)*128);
  writebyte(f, n + 128);
}

void writenum (file f, int n) {
  if (n > 127) wnum(f, n/128);
  while (n > 127) n = n - ((n/128)*128);
  writebyte(f, n);
}

void writestr (file f, string s) {
  writenum(f, strlen(s));
  write(f, s);
}

void writeExports (Compiler c, file f) {
  int exportcount = c.fnExports.arr.len() + c.tpExports.arr.len() + c.modExports.arr.len();
  writebyte(f, 2); // Export module, kind 2 is defined
  writenum(f, exportcount);
  int i = 0;
  while (i < c.tpExports.arr.len()) {
    Pair p = c.tpExports.arr[i];
    writebyte(f, 1);
    writenum(f, p.id);
    writestr(f, p.key);
    i = i+1;
  }

  int i = 0;
  while (i < c.fnExports.arr.len()) {
    Pair p = c.fnExports.arr[i];
    writebyte(f, 2);
    writenum(f, p.id);
    writestr(f, p.key);
    i = i+1;
  }

  int i = 0;
  while (i < c.modExports.arr.len()) {
    Pair p = c.modExports.arr[i];
    writebyte(f, 0);
    writenum(f, p.id);
    writestr(f, p.key);
    i = i+1;
  }
}

void writeModules (Compiler c, file f) {
  writenum(f, c.modules.len() - 1); // The argument module (0) is not counted

  writeExports(c, f);

  int i = 2; // Omit argument and export (exports already written)
  while (i < c.modules.len()) {
    Module m = c.modules[i];

    if (m.kind == "global") {
      writebyte(f, 1);
      writestr(f, m.name);
    } else if (m.kind == "use") {
      writebyte(f, 3);
      writenum(f, c.modMap[m.name]);
      writestr(f, m.argument);
    } else if (m.kind == "define") {
      writebyte(f, 2);
      writebyte(f, m.items.len());
      int j = 0;
      while (j < m.items.len()) {
        int id, k;
        id, k = c.getitem(m.items[j], m.line);
        // getitem second result is compatible with the module format
        writebyte(f, k);
        writenum(f, id);
        writestr(f, m.itemnames[j]);
        j = j+1;
      }
    } else if (m.kind == "build") {
      writebyte(f, 4);
      int baseid = c.modMap[m.name];
      int argid = c.modMap[m.argument];
      writenum(f, baseid);
      writenum(f, argid);
    } else errorln("Unknown module kind " + m.kind, 0-1);
    i = i+1;
  }
}

void writeFunctions (Compiler c, file f) {
  writenum(f, c.functions.len());

  int i = 0;
  while (i < c.functions.len()) {
    Function fn = c.functions[i];

    if (fn.hasCode()) writebyte(f, 1);
    else writenum(f, c.modMap[fn.mod]+2);

    writenum(f, fn.ins.len());
    int j = 0;
    while (j < fn.ins.len()) {
      string tpname = fn.ins[j];
      int tpid = c.gettp(tpname, fn.line);
      writenum(f, tpid);
      j = j+1;
    }

    writenum(f, fn.outs.len());
    int j = 0;
    while (j < fn.outs.len()) {
      string tpname = fn.outs[j];
      int tpid = c.gettp(tpname, fn.line);
      writenum(f, tpid);
      j = j+1;
    }

    if (fn.hasCode()) {} else writestr(f, fn.name);

    i = i+1;
  }
}

void writeCode (file f, Inst[] code) {
  writenum(f, code.len());

  int i = 0;
  while (i < code.len()) {
    Inst inst = code[i];
    string k = inst.inst;
    if (k == "end") {
      writebyte(f, 0);
      int j = 0;
      while (j < inst.args.len()) {
        writenum(f, inst.args[j]);
        j = j+1;
      }
    }
    else if (k == "var") writebyte(f, 2);
    else if (k == "set") {
      writebyte(f, 4);
      writenum(f, inst.a);
      writenum(f, inst.b);
    }
    else if (k == "jmp") {
      writebyte(f, 5);
      writenum(f, inst.a);
    }
    else if (k == "jif") {
      writebyte(f, 6);
      writenum(f, inst.a);
      writenum(f, inst.b);
    }
    else if (k == "nif") {
      writebyte(f, 7);
      writenum(f, inst.a);
      writenum(f, inst.b);
    }
    else if (k == "call") {
      int fnid = inst.a;
      writenum(f, fnid + 16);
      int j = 0;
      while (j < inst.args.len()) {
        writenum(f, inst.args[j]);
        j = j+1;
      }
    }
    else errorln("Unknown instruction: " + k, 0-1);
    i = i+1;
  }
}

void writeBodies (Compiler c, file f) {
  int i = 0;
  while (i < c.functions.len()) {
    Function fn = c.functions[i];
    if (fn.hasCode()) 
      writeCode(f, fn.code);
    i = i+1;
  }
}

int atoi (string str) {
  int value = 0;
  int pos = 0;
  while (pos < strlen(str)) {
    char ch;
    ch, pos = charat(str, pos);
    int code = codeof(ch);
    value = (value*10) + (code-48);
  }
  return value;
}

void writeMetadata (Compiler c, file f) {

  // Third item, function list
  int fcount = 0;
  int i = 0;
  while (i < c.functions.len()) {
    Function fn = c.functions[i];
    if (fn.hasCode()) fcount = fcount+1;
    i = i+1;
  }

  int itemcount = fcount + 2; // "source map" + file + functions

  writenum(f, 4); // 1 items (1<<2)
    writenum(f, itemcount*4); // items
      writenum(f, 42); // 10 chars (10<<2 | 2)
      write(f, "source map");

      writenum(f, 8); // 2 items (2<<2)
        writenum(f, 18); // 10 chars (4<<2 | 2)
        write(f, "file");
        writenum(f, 38); // 10 chars (9<<2 | 2)
        write(f, "<file.cu>");

  int i = 0;
  while (i < c.functions.len()) {
    Function fn = c.functions[i];
    if (fn.hasCode()) {
      writenum(f, 5*4); // 5 items

      writenum(f, 34); // 8 characters
      write(f, "function");

      writenum(f, (i*2)+1);

      writenum(f, 8); // 2 items
        writenum(f, 18); // 4 chars
        write(f, "name");

        writenum(f, (strlen(fn.name)*4)+2);
        write(f, fn.name);

      writenum(f, 8); // 2 items
        writenum(f, 18); // 4 chars
        write(f, "line");

        writenum(f, (fn.line*2)+1);

      int lcount = fn.lineinfo.len();
      writenum(f, (lcount+1)*4);
        writenum(f, 18); // 4 chars
        write(f, "code");

        int j = 0;
        while (j < fn.lineinfo.len()) {
          Line ln = fn.lineinfo[j];
          writenum(f, 8); // 2 items
          writenum(f, (ln.inst*2)+1);
          writenum(f, (ln.line*2)+1);
          j = j+1;
        }
    }
    i = i+1;
  }
}

void writeCompiler (Compiler c, string filename) {
  file f = open(filename, "w");
  write(f, "Cobre 0.6");
  writebyte(f, 0); // end signature

  writeModules(c, f);

  writenum(f, c.types.len());
  int i = 0;
  while (i < c.types.len()) {
    Type tp = c.types[i];
    writenum(f, c.modMap[tp.mod]+1);
    writestr(f, tp.name);
    i = i+1;
  }

  writeFunctions(c, f);

  writenum(f, c.constants.len());
  int i = 0;
  while (i < c.constants.len()) {
    Constant cns = c.constants[i];
    if (cns.kind == "int") {
      writebyte(f, 1); // kind 1 is an int constant
      writenum(f, atoi(cns.val));
    }
    if (cns.kind == "bin") {
      writebyte(f, 2); // kind 2 is a binary constant
      writestr(f, cns.val);
    }
    if (cns.kind == "str") {
      // Strings ar built using the bin constant just before them
      int binindex = (i-1) + c.functions.len();
      int function = 0; // new string function index
      writenum(f, function + 16);
      writenum(f, binindex);
    }
    i = i+1;
  }

  writeBodies(c, f);

  writeMetadata(c, f);
}



// =============================== //
//             Interface           //
// =============================== //

void printCompiler (Compiler c) {
  println("Module Map:");
  c.modMap.print("");

  println("Type Map:");
  c.typeMap.print("");

  println("\nFunction Map:");
  c.fnMap.print("");

  println("\nModules:");
  int i = 0;
  while (i < c.modules.len()) {
    Module m = c.modules[i];
    string desc;
    if (m.kind == "hidden") desc = "hidden";
    else if (m.kind == "global") desc = "global " + m.name;
    else if (m.kind == "use") desc = "use " + m.name + "." + m.argument;
    else if (m.kind == "build") desc = "build " + m.name + " (" + m.argument + ")";
    else if (m.kind == "define") {
      desc = "define { ";
      int j = 0;
      while (j < m.items.len()) {
        desc = desc + m.itemnames[j] + ": " + m.items[j] + "; ";
        j = j+1;
      }
      desc = desc + "}";
    }
    println("[" + itos(i) + "]: " + desc);
    i = i+1;
  }

  println("\nTypes:");
  int i = 0;
  while (i < c.types.len()) {
    Type t = c.types[i];
    println("[" + itos(i) + "]: " + t.mod + "." + t.name);
    if (t.constructor < 0) {} else {
      println("  new: " + itos(t.constructor));
    }
    if (t.getters.any()) {
      println("  getters:");
      t.getters.print("    ");
    }
    if (t.setters.any()) {
      println("  setters:");
      t.setters.print("    ");
    }
    if (t.methods.any()) {
      println("  methods:");
      t.methods.print("    ");
    }
    if (t.casts.any()) {
      println("  casts to:");
      t.casts.print("    ");
    }
    i = i+1;
  }

  println("\nFunctions:");
  int i = 0;
  while (i < c.functions.len()) {
    Function f = c.functions[i];

    string args = " ( ";
    int j = 0;
    while (j < f.ins.len()) {
      args = args + f.ins[j] + " ";
      j = j+1;
    }
    args = args + ") -> ( ";
    int j = 0;
    while (j < f.outs.len()) {
      args = args + f.outs[j] + " ";
      j = j+1;
    }
    args = args + ")";


    if (f.hasCode()) {
      //println("[" + itos(i) + "]: <Code>" + args);
      println("[" + itos(i) + "]: " + args);
      int j = 0;
      while (j < f.code.len()) {
        println("  " + f.code[j].inst);
        j = j+1;
      }
    } else {
      println("[" + itos(i) + "]: " + f.mod + "." + f.name + args);
    }
    i = i+1;
  }

  println("\nType exports:");
  c.tpExports.print("");

  println("\nFunction exports:");
  c.fnExports.print("");

  println("\nModule exports:");
  c.modExports.print("");
}

void main () {
  string src = readall("test.cu");
  Compiler c = compile(src);

  codegen(c);

  printCompiler(c);
  writeCompiler(c, "out");
}