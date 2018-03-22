
import cobre.system {
  void print (string);
  void quit (int);
  string readall (string);

  type file as file; 
  file open (string filename, string mode);
  void write (file, string);
  void writebyte (file, int);
}

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

import cobre.array (Pair) {
  type `` as PairArr {
    Pair get (int);
    void set (int, Pair);
    int len ();
    void push (Pair);
  }
  PairArr empty () as emptyPairArr;
}

struct Map {
  PairArr arr;
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
      print(ident + pair.key + ": " + itos(pair.id));
      i = i+1;
    }
  }

  bool any (Map this) { return this.arr.len() > 0; }
}

Map newMap () { return new Map(emptyPairArr(), 0); }

import cobre.array (Node) {
  type `` as NodeArr {
    Node get (int);
    void set (int, Node);
    int len ();
    void push (Node);
  }
  NodeArr empty () as emptyNodeArr;
}

import cobre.array (string) {
  type `` as StrArr {
    string get (int);
    void set (int, string);
    int len ();
    void push (string);
  }
  StrArr empty () as emptyStrArr;
}

struct Module {
  string name;
  StrArr args;
  StrArr argnames;
  int line;
}

struct Type {
  int module;
  string name;
  Map getters;
  Map setters;
  Map methods;
  Map casts;
  int constructor;
}

Type newType (int module, string name) {
  return new Type(module, name, newMap(), newMap(), newMap(), newMap(), 0-1);
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

import cobre.array (Line) {
  type `` as LineArr {
    Line get (int);
    void set (int, Line);
    int len ();
    void push (Line);
  }
  LineArr empty () as emptyLineArr;
}

struct Function {
  int module; // -1 for defined function
  string name;
  StrArr outs;
  StrArr ins;
  StrArr in_names;
  NodeNull node;
  InstArr code;
  int line;
  LineArr lineinfo;

  bool hasCode (Function this) {
    if (this.node.isnull()) return 1<0;
    else return 0<1;
  }
}

Function newFunction () {
  return new Function(0-1, "", emptyStrArr(), emptyStrArr(), emptyStrArr(), nullNode(), emptyInstArr(), 0, emptyLineArr());
}

import cobre.array (Module) {
  type `` as ModuleArr {
    Module get (int);
    void set (int, Module);
    int len ();
    void push (Module);
  }
  ModuleArr empty () as emptyModuleArr;
}

import cobre.array (Type) {
  type `` as TypeArr {
    Type get (int);
    void set (int, Type);
    int len ();
    void push (Type);
  }
  TypeArr empty () as emptyTypeArr;
}

import cobre.array (Function) {
  type `` as FunctionArr {
    Function get (int);
    void set (int, Function);
    int len ();
    void push (Function);
  }
  FunctionArr empty () as emptyFunctionArr;
}

struct Constant {
  string kind;
  string val;
}

import cobre.array (Constant) {
  type `` as ConstArr {
    Constant get (int);
    void set (int, Constant);
    int len ();
    void push (Constant);
  }
  ConstArr empty () as emptyConstArr;
}

import cobre.array (int) {
  type `` as IntArr {
    int get (int);
    void set (int, int);
    int len ();
    void push (int);
  }
  IntArr empty () as emptyIntArr;
}

struct Inst {
  int inst;
  int a;
  int b;
  string lbl;
  IntArr args;
}

import cobre.array (Inst) {
  type `` as InstArr {
    Inst get (int);
    void set (int, Inst);
    int len ();
    void push (Inst);
  }
  InstArr empty () as emptyInstArr;
}

struct Cast {
  string from;
  string to;
  int fn;
}

import cobre.array (Cast) {
  type `` as CastArr {
    Cast get (int);
    void set (int, Cast);
    int len ();
    void push (Cast);
  }
  CastArr empty () as emptyCastArr;
}

struct Compiler {
  Node tree;
  Map typeMap;
  Map fnMap;
  ModuleArr modules;
  TypeArr types;
  FunctionArr functions;
  Map tpExports;
  Map fnExports;
  ConstArr constants;
  CastArr casts;

  int gettp (Compiler this, string name, int line) {
    int id = this.typeMap[name];
    if (id < 0) errorln("Unkown type \"" + name + "\"", line);
    return id;
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
  IntArr regtypes;
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

  void inst (Scope this, int i, int a, int b) {
    this.fn.code.push(new Inst(i, a, b, "", emptyIntArr()));
  }

  void flow (Scope this, int i, string lbl, int b) {
    this.fn.code.push(new Inst(i, 0, b, lbl, emptyIntArr()));
  }

  string lbl (Scope this) {
    int lbl = this.lblcount;
    this.lblcount = lbl + 1;
    return itos(lbl);
  }

  void call (Scope this, int fn, IntArr args) {
    this.fn.code.push(new Inst(16, fn, 0, "", args));
  }

  void uselbl (Scope this, string name) {
    this.labels[name] = this.fn.code.len();
  }
}

void errorln (string msg, int line) {
  string pos = "";
  if (line < 0) {} else {
    pos = ", at line " + itos(line);
  }
  print("Compile error: " + msg + pos);
  quit(1);
}

void error (Node node, string msg) { errorln(msg, node.line); }

Scope newScope (Compiler c, Function fn) {
  return new Scope(c, fn, newMap(), newMap(), emptyIntArr(), 0, 0);
}

IntArr compileCall (Scope this, Node node) {
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

    IntArr args = emptyIntArr();
    int i = 0;
    while (i < argsnode.len()) {
      int reg = compileExpr(this, argsnode.child(i));
      args.push(reg);
      i = i+1;
    }

    this.fn.lineinfo.push(new Line(this.fn.code.len(), node.line));
    this.call(id, args);

    IntArr rets = emptyIntArr();
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

    IntArr args = emptyIntArr();
    args.push(basereg);
    int i = 0;
    while (i < argsnode.len()) {
      int reg = compileExpr(this, argsnode.child(i));
      args.push(reg);
      i = i+1;
    }

    this.fn.lineinfo.push(new Line(this.fn.code.len(), node.line));
    this.call(fnid, args);

    IntArr rets = emptyIntArr();
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
    this.inst(4, id, 0); // kind 4 is sget, static get
    int tp = this.gettp("int");
    int reg = this.decl(tp);
    return reg;
  }
  if (node.tp == "str") {
    int rawid = this.c.constants.len();
    this.c.constants.push(new Constant("str", node.val));
    int id = this.c.constants.len();
    this.c.constants.push(new Constant("null", "string"));

    IntArr args;

    // TODO: Add static instructions
    int tp = this.gettp("string");
    this.inst(4, id, 0); // kind 4 is sget, static get
    int reg = this.decl(tp);
    return reg;
  }
  if (node.tp == "binop") {
    int a = compileExpr(this, node.child(0));
    int b = compileExpr(this, node.child(1));
    int tpa = this.regtypes[a];
    int tpb = this.regtypes[b];

    IntArr args = emptyIntArr(); 
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
    IntArr rets = compileCall(this, node);
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

    IntArr args = emptyIntArr();
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
      IntArr args = emptyIntArr();
      args.push(base);
      args.push(index);
      this.call(fnid, args);
      return this.decl(rettp);
    } else error(node, "get method must receive 2 parameters");
  }
  if (node.tp == "new") {
    string tpname = node.val;
    int tpid = this.c.gettp(tpname, node.line);
    Type tp = this.c.types[tpid];
    int fnid = tp.constructor;
    if (fnid < 0) error(node, "Unknown constructor for " + tpname);
    Function fn = this.c.functions[fnid];
    int expected = fn.ins.len();
    Node exprlist = node.child(0);
    int count = exprlist.len();
    if (expected == count) {} else {
      error(node, "Constructor expects " + itos(expected) + " parameters, but " + itos(count) + " were passed");
    }

    IntArr args = emptyIntArr();
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
    Type tp = this.c.types[this.regtypes[basereg]];
    int fnid = tp.casts[node.val];
    if (fnid < 0) error(node, "Unknown cast to \"" + node.val + "\"");

    Function fn = this.c.functions[fnid];
    int rettp = this.c.gettp(node.val, node.line);

    IntArr args = emptyIntArr();
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
      this.inst(3, id, reg);
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
      IntArr args = emptyIntArr();
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

    IntArr args = emptyIntArr();
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
    int tp = this.gettp(node.val);
    int i = 0;
    while (i < node.len()) {
      Node part = node.child(i);
      string name = part.val;
      int reg;
      if (part.len() > 0) {
        Node val = part.child(0);
        reg = compileExpr(this, part.child(0));
        if (val.tp == "var") {
          this.inst(1, 0,0); // var
          int newreg = this.decl(tp);
          this.inst(3, newreg, reg); // set
          reg = newreg;
        }
      } else {
        this.inst(1, 0,0);
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
        IntArr regs = compileCall(this, right);
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
    this.flow(8, end, cond); // nif
    compileStmt(this, node.child(1));
    this.flow(6, start, 0); // jmp
    this.uselbl(end);
    return;
  }
  if (node.tp == "if") {
    string els = this.lbl();
    string end = this.lbl();
    int cond = compileExpr(this, node.child(0));
    this.flow(8, els, cond); // nif
    compileStmt(this, node.child(1));
    this.flow(6, end, 0); // jmp
    this.uselbl(els);
    if (node.len() == 3) {
      compileStmt(this, node.child(2));
    }
    this.uselbl(end);
    return;
  }
  if (node.tp == "call") {
    IntArr rets = compileCall(this, node);
    return;
  }
  if (node.tp == "return") {
    Node exprlist = node.child(0);
    int count = exprlist.len();
    int expected = this.fn.outs.len();
    if (count == expected) {} else {
      error(node, "Function returns " + itos(expected) + " values, but " + itos(count) + " were returned");
    }
    IntArr args = emptyIntArr();
    int i = 0;
    while (i < count) {
      Node expr = exprlist.child(i);
      int reg = compileExpr(this, expr);
      args.push(reg);
      i = i+1;
    }
    this.fn.code.push(new Inst(0, 0, 0, "", args));
    return;
  }
  if (node.tp == "goto") {
    this.flow(6, node.val, 0); // jmp
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
        scope.inst(0, 0,0);

      // Convert label names to label indices
      int j = 0;
      while (j < fn.code.len()) {
        Inst inst = fn.code[j];
        int k = inst.inst;
        if (k == 6) inst.a = scope.labels[inst.lbl];
        if (k == 7) inst.a = scope.labels[inst.lbl];
        if (k == 8) inst.a = scope.labels[inst.lbl];
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
  c.modules.push(new Module("cobre.core", emptyStrArr(), emptyStrArr(), 0-1)); // #2
  c.modules.push(new Module("cobre.int", emptyStrArr(), emptyStrArr(), 0-1)); // #3
  c.modules.push(new Module("cobre.string", emptyStrArr(), emptyStrArr(), 0-1)); // #4

  c.types.push(newType(2, "bool"));
  c.types.push(newType(2, "bin"));
  c.types.push(newType(3, "int"));
  c.types.push(newType(4, "string"));
  c.types.push(newType(4, "char"));

  c.typeMap["bool"] = 0;
  c.typeMap["__bin__"] = 1;
  c.typeMap["int"] = 2;
  c.typeMap["string"] = 3;
  c.typeMap["char"] = 4;

  // #0
  Function fn = newFunction();
  fn.module = 4;
  fn.name = "new";
  fn.ins.push("__bin__");
  fn.outs.push("string");
  c.functions.push(fn);

  // #1
  Function fn = newFunction();
  fn.module = 3;
  fn.name = "eq";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("bool");
  c.functions.push(fn);

  // #2
  Function fn = newFunction();
  fn.module = 3;
  fn.name = "add";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("int");
  c.functions.push(fn);

  // #3
  Function fn = newFunction();
  fn.module = 3;
  fn.name = "gt";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("bool");
  c.functions.push(fn);

  // #4
  Function fn = newFunction();
  fn.module = 3;
  fn.name = "lt";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("bool");
  c.functions.push(fn);

  // #5
  Function fn = newFunction();
  fn.module = 4;
  fn.name = "eq";
  fn.ins.push("string");
  fn.ins.push("string");
  fn.outs.push("bool");
  c.functions.push(fn);

  // #6
  Function fn = newFunction();
  fn.module = 4;
  fn.name = "concat";
  fn.ins.push("string");
  fn.ins.push("string");
  fn.outs.push("string");
  c.functions.push(fn);

  // #7
  Function fn = newFunction();
  fn.module = 3;
  fn.name = "sub";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("int");
  c.functions.push(fn);

  // #8
  Function fn = newFunction();
  fn.module = 3;
  fn.name = "mul";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("int");
  c.functions.push(fn);

  // #9
  Function fn = newFunction();
  fn.module = 3;
  fn.name = "div";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("int");
  c.functions.push(fn);

  // #10
  Function fn = newFunction();
  fn.module = 3;
  fn.name = "gte";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("bool");
  c.functions.push(fn);

  // #11
  Function fn = newFunction();
  fn.module = 3;
  fn.name = "lte";
  fn.ins.push("int");
  fn.ins.push("int");
  fn.outs.push("bool");
  c.functions.push(fn);
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


Function, string fnFromNode (Node node) {
  string alias = node.child(2).val;
  if (alias == "") alias = node.val;
  Function f = newFunction();
  f.name = node.val;
  f.line = node.line;

  Node innd = node.child(0);
  int k = 0;
  while (k < innd.len()) {
    Node argnd = innd.child(k);
    f.ins.push(argnd.child(0).val);
    f.in_names.push(argnd.child(1).val);
    k = k+1;
  }

  Node outnd = node.child(1);
  int k = 0;
  while (k < outnd.len()) {
    f.outs.push(outnd.child(k).val);
    k = k+1;
  }

  return f, alias;
}

void thisArg (Function fn, string arg) {
  StrArr oldArr = fn.ins;
  StrArr newArr = emptyStrArr();
  newArr.push(arg);
  int i = 0;
  while (i < oldArr.len()) {
    newArr.push(oldArr[i]);
    i = i+1;
  }
  fn.ins = newArr;

  StrArr oldArr = fn.in_names;
  StrArr newArr = emptyStrArr();
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
    if (node.tp == "import") {
      int id = c.modules.len() + 2;

      StrArr args = emptyStrArr();
      StrArr argnames = emptyStrArr();
      Node argsnd = node.child(0);
      int j = 0, k = 0;
      while (j < argsnd.len()) {
        Node argnd = argsnd.child(j);
        if (argnd.tp == "name") {
          args.push(argnd.val);
          argnames.push(itos(k));
          k = k+1;
        } else if (argnd.tp == "alias") {
          argnames.push(argnd.val);
          args.push(argnd.child(0).val);
        }
        j = j+1;
      }
      c.modules.push(new Module(node.val, args, argnames, node.line));


      int j = 1; // Skip first child, it's the argument node
      while (j < node.len()) {
        Node item = node.child(j);
        if (item.tp == "type") {
          int typeid = c.types.len();
          string tp_alias = item.child(0).val;
          if (tp_alias == "") tp_alias = item.val;
          Type tp = newType(id, item.val);
          c.types.push(tp);
          c.typeMap[tp_alias] = typeid;

          int k = 1;
          while (k < item.len()) {
            Node member = item.child(k);

            string suffix = "";
            if (item.val == "") {} else { suffix = ":" + item.val; }

            if (member.tp == "function") {
              int fnid = c.functions.len();
              Function f; string fn_alias;
              f, fn_alias = fnFromNode(member);
              f.module = id;
              f.name = f.name + suffix;
              thisArg(f, tp_alias);
              c.functions.push(f);
              tp.methods[fn_alias] = fnid;
            } else if (member.tp == "decl") {
              string name = member.val;
              string tpnm = member.child(0).val;

              string getname = name + ":get" + suffix;
              string setname = name + ":set" + suffix;

              int getid = c.functions.len();

              Function getfn = newFunction();
              getfn.name = name + ":get" + suffix;
              getfn.ins.push(tp_alias);
              getfn.outs.push(tpnm);
              getfn.module = id;

              Function setfn = newFunction();
              setfn.name = name + ":set" + suffix;
              setfn.ins.push(tp_alias);
              setfn.ins.push(tpnm);
              setfn.module = id;

              c.functions.push(getfn);
              c.functions.push(setfn);

              tp.getters[name] = getid;
              tp.setters[name] = getid+1;
            } else {
              print("Unknown type member " + member.tp);
              quit(1);
            }
            k = k+1;
          }
        } else if (item.tp == "function") {
          int fnid = c.functions.len();
          Function f; string alias;
          f, alias = fnFromNode(item);
          f.module = id;
          c.functions.push(f);
          c.fnMap[alias] = fnid;
        } else {
          print("Unknown imported item: " + item.tp);
          quit(1);
        }
        j = j+1;
      }
    }
    i = i+1;
  }
}

void makeTypes (Compiler c) {
  int i = 0;
  while (i < c.tree.len()) {
    Node node = c.tree.child(i);
    if (node.tp == "type") {
      int moduleid = c.modules.len() + 2;
      string base = node.child(0).val;
      StrArr args = emptyStrArr(), argnames = emptyStrArr();
      args.push(base);
      argnames.push("0");
      c.modules.push(new Module("cobre.typeshell", args, argnames, node.line));

      int typeid = c.types.len();
      string alias = node.val;
      Type tp = newType(moduleid, "");
      c.types.push(tp);
      c.typeMap[alias] = typeid;
      c.tpExports[alias] = typeid;

      int fromid = c.functions.len();
      Function from = newFunction();
      from.module = moduleid;
      from.ins.push(base);
      from.outs.push(alias);
      from.name = "new";

      Function to = newFunction();
      to.module = moduleid;
      to.ins.push(alias);
      to.outs.push(base);
      to.name = "get";

      c.functions.push(from);
      c.functions.push(to);

      c.casts.push(new Cast(base, alias, fromid));
      c.casts.push(new Cast(alias, base, fromid+1));
    }
    if (node.tp == "struct") {
      int moduleid = c.modules.len() + 2;
      StrArr args = emptyStrArr();
      StrArr argnames = emptyStrArr();
      c.modules.push(new Module("cobre.record", args, argnames, node.line));

      int typeid = c.types.len();
      string alias = node.val;
      Type tp = newType(moduleid, "");
      c.types.push(tp);
      c.typeMap[alias] = typeid;
      c.tpExports[alias] = typeid;

      Function constructor = newFunction();
      constructor.module = moduleid;
      constructor.name = "new";
      constructor.outs.push(alias);
      int newid = c.functions.len();
      c.functions.push(constructor);
      tp.constructor = newid;

      int fieldid = 0;
      int j = 0;
      while (j < node.len()) {
        Node member = node.child(j);
        if (member.tp == "decl") {
          string name = member.val;
          string ftp = member.child(0).val;

          argnames.push(itos(args.len()));
          args.push(ftp);
          constructor.ins.push(ftp);

          int getid = c.functions.len();
          Function getter = newFunction();
          getter.line = member.line;
          getter.module = moduleid;
          getter.ins.push(alias);
          getter.outs.push(ftp);
          getter.name = "get" + itos(fieldid);

          Function setter = newFunction();
          setter.line = member.line;
          setter.module = moduleid;
          setter.ins.push(alias);
          setter.ins.push(ftp);
          setter.name = "set" + itos(fieldid);

          c.functions.push(getter);
          c.functions.push(setter);

          tp.getters[name] = getid;
          tp.setters[name] = getid+1;

          c.fnExports[name + ":get:" + alias] = getid;
          c.fnExports[name + ":set:" + alias] = getid+1;

          fieldid = fieldid + 1;
        } else if (member.tp == "function") {
          int fnid = c.functions.len();
          Function f; string fn_alias;
          f, fn_alias = fnFromNode(member);
          f.name = fn_alias;
          f.node = newNullNode(member.child(3));
          c.functions.push(f);
          tp.methods[fn_alias] = fnid;
          c.fnExports[fn_alias + ":" + alias] = fnid;
        } else {
          print("Unknown struct member " + member.tp);
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
    if (node.tp == "function") {
      int id = c.functions.len();
      Function f; string name;
      f, name = fnFromNode(node);
      f.name = name;
      f.node = newNullNode(node.child(3));
      c.functions.push(f);
      c.fnMap[name] = id;
      c.fnExports[name] = id;
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
    emptyModuleArr(),
    emptyTypeArr(),
    emptyFunctionArr(),
    newMap(),
    newMap(),
    emptyConstArr(),
    emptyCastArr()
  );

  makeBasics(c);
  makeImports(c);
  makeTypes(c);
  makeCasts(c);
  makeFunctions(c);

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
  int exportcount = c.fnExports.arr.len() + c.tpExports.arr.len();
  writebyte(f, 1); // Export module, kind 1 is defined
  writenum(f, exportcount);
  int i = 0;
  while (i < c.tpExports.arr.len()) {
    Pair p = c.tpExports.arr[i];
    writebyte(f, 1); // Item kind 1 is type
    writenum(f, p.id);
    writestr(f, p.key);
    i = i+1;
  }

  int i = 0;
  while (i < c.fnExports.arr.len()) {
    Pair p = c.fnExports.arr[i];
    writebyte(f, 2); // Item kind 2 is function
    writenum(f, p.id);
    writestr(f, p.key);
    i = i+1;
  }
}

void writeModules (Compiler c, file f) {
  int count = c.modules.len() + 1;

  int argcount = 0; // Number of modules with arguments
  int i = 0;
  while (i < c.modules.len()) {
    if (c.modules[i].args.len() > 0)
      argcount = argcount + 1;
    i = i+1;
  }

  writenum(f, count + argcount + argcount); // For now, omit argument modules

  writeExports(c, f);

  // This one is an index, so it does count this module's argument
  int argi = count+1;
  int i = 0;
  while (i < c.modules.len()) {
    Module m = c.modules[i];
    if (m.args.len() > 0) {
      // Every module with argumetns consists of three modules
      // the imported functor, the argument module
      // and the applied functor.
      // This one is the last
      writebyte(f, 4); // Kind 4 is build functor
      writenum(f, argi); // The functor
      writenum(f, argi+1); // The argument
      argi = argi+2;
    } else {
      writebyte(f, 0); // Kind 0 is import
      writestr(f, m.name);
    }
    i = i+1;
  }

  // Now the two parts of a functor module
  int i = 0;
  while (i < c.modules.len()) {
    Module m = c.modules[i];
    if (m.args.len() > 0) {
      writebyte(f, 2); // Kind 2 is import functor
      writestr(f, m.name);

      writebyte(f, 1); // Kind 1 is defined module
      writebyte(f, m.args.len());
      int j = 0;
      while (j < m.args.len()) {
        string tpname = m.args[j];
        int tpid = c.gettp(tpname, m.line);
        writebyte(f, 1); // Item kind 1 is type
        writenum(f, tpid);
        writestr(f, m.argnames[j]);
        j = j+1;
      }
    }
    i = i+1;
  }
}

void writeFunctions (Compiler c, file f) {
  writenum(f, c.functions.len());

  int i = 0;
  while (i < c.functions.len()) {
    Function fn = c.functions[i];

    if (fn.hasCode()) {
      writebyte(f, 2); // Kind 2 is function with code
    } else {
      writebyte(f, 1); // Kind 1 is imported function
      writenum(f, fn.module);
      writestr(f, fn.name);
    }

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

    i = i+1;
  }
}

void writeCode (file f, InstArr code) {
  writenum(f, code.len());

  int i = 0;
  while (i < code.len()) {
    Inst inst = code[i];
    int k = inst.inst;
    if (k == 0) {
      writebyte(f, 0);
      int j = 0;
      while (j < inst.args.len()) {
        writenum(f, inst.args[j]);
        j = j+1;
      }
    }
    if (k == 1) writebyte(f, 1);
    if (k == 3) {
      writebyte(f, 3);
      writenum(f, inst.a);
      writenum(f, inst.b);
    }
    if (k == 4) {
      writebyte(f, 4);
      writenum(f, inst.a);
    }
    if (k == 6) {
      writebyte(f, 6);
      writenum(f, inst.a);
    }
    if (k == 7) {
      writebyte(f, 7);
      writenum(f, inst.a);
      writenum(f, inst.b);
    }
    if (k == 8) {
      writebyte(f, 8);
      writenum(f, inst.a);
      writenum(f, inst.b);
    }
    if (k == 16) {
      int fnid = inst.a;
      writenum(f, fnid + 16);
      int j = 0;
      while (j < inst.args.len()) {
        writenum(f, inst.args[j]);
        j = j+1;
      }
    }
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

void writeStatics (Compiler c, file f) {
  int instcount = 0;
  int i = 0;
  while (i < c.constants.len()) {
    if (c.constants[i].kind == "str") instcount = instcount+3;
    i = i+1;
  }

  writenum(f, instcount+1);

  int r = 0;
  int i = 0;
  while (i < c.constants.len()) {
    if (c.constants[i].kind == "str") {
      // [r] = sget [i]
      writebyte(f, 4);
      writenum(f, i);
      // [r+1] = string.new([r])
      writebyte(f, 16);
      writenum(f, r);
      // sset [i+1] [r+1]
      writebyte(f, 5);
      writenum(f, i+1);
      writenum(f, r+1);
      r = r+2;
    }
    i = i+1;
  }

  writebyte(f, 0); // return;
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
  write(f, "Cobre ~4");
  writebyte(f, 0); // end signature

  writeModules(c, f);

  writenum(f, c.types.len());
  int i = 0;
  while (i < c.types.len()) {
    Type tp = c.types[i];
    writebyte(f, 1); // Kind 1 is import
    writenum(f, tp.module);
    writestr(f, tp.name);
    i = i+1;
  }

  writeFunctions(c, f);

  writenum(f, c.constants.len());
  int i = 0;
  while (i < c.constants.len()) {
    Constant cns = c.constants[i];
    if (cns.kind == "int") {
      writebyte(f, 2); // kind 2 is an int constant
      writenum(f, atoi(cns.val));
    }
    if (cns.kind == "null") {
      int tpid = c.typeMap[cns.val];
      writenum(f, tpid + 16);
    }
    if (cns.kind == "str") {
      // Binary data and strings are written the same way
      writebyte(f, 3); // kind 3 is a binary constant
      writestr(f, cns.val);
    }
    i = i+1;
  }

  writeBodies(c, f);

  writeStatics(c, f);

  writeMetadata(c, f);
}



// =============================== //
//             Interface           //
// =============================== //

void printCompiler (Compiler c) {
  print("Type Map:");
  c.typeMap.print("");

  print("\nFunction Map:");
  c.fnMap.print("");

  print("\nModules:");
  int i = 0;
  while (i < c.modules.len()) {
    Module m = c.modules[i];
    string args = " ( ";
    int j = 0;
    while (j < m.args.len()) {
      args = args + m.args[j] + " ";
      j = j+1;
    }
    print("[" + itos(i+2) + "]: " + m.name + args + ")");
    i = i+1;
  }

  print("\nTypes:");
  int i = 0;
  while (i < c.types.len()) {
    Type t = c.types[i];
    print("[" + itos(i) + "]: Module[" + itos(t.module) + "]." + t.name);
    if (t.constructor < 0) {} else {
      print("  new: " + itos(t.constructor));
    }
    if (t.getters.any()) {
      print("  getters:");
      t.getters.print("    ");
    }
    if (t.setters.any()) {
      print("  setters:");
      t.setters.print("    ");
    }
    if (t.methods.any()) {
      print("  methods:");
      t.methods.print("    ");
    }
    if (t.casts.any()) {
      print("  casts to:");
      t.casts.print("    ");
    }
    i = i+1;
  }

  print("\nFunctions:");
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
      print("[" + itos(i) + "]: <Code>" + args);
    } else {
      print("[" + itos(i) + "]: Module[" + itos(f.module) + "]." + f.name + args);
    }
    i = i+1;
  }

  print("\nType exports:");
  c.tpExports.print("");

  print("\nFunction exports:");
  c.fnExports.print("");
}

void main () {
  string src = readall("test.cu");
  Compiler c = compile(src);

  //printCompiler(c);

  codegen(c);
  writeCompiler(c, "out");
}