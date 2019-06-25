import auro.system { void error(string); }

import auro.string {
  int length (string) as strlen;
}

import aulang.node {
  type Node as Node {
    string tp;
    string val;
    int line;

    int len ();
    Node child (int);

    string to_string ();
  }
}

import aulang.parser { Node parse (string); }

import auro.buffer { type buffer; }
import aulang.writer {
  type Writer {
    new ();
    void byte (int);
    void num (int);
    void str (string);
    void rawstr (string);
    buffer tobuffer ();
  }
}

import aulang.item {
  type Item {
    new (string tp, Node node);
    string tp;
    Node node;
    any value;
    string to_str();
  }
}

import aulang.codegen {
  string inst_name (any);
  any[] compile_function (Node body, Node fn);

  type Register {
    int id;
    string name;
    any tp;
  }

  type CallInst {
    any fn;
    Node node;
    int ins_len ();
    int outs_len ();
    Register in (int i);
    Register out (int i);
    void ins_push (Register);
    void outs_push (Register);
    new (any fn, Node node);
  }

  type RetInst {
    int vals_len ();
    Register val (int i);
    Node node;
  }

  type DupInst {
    Register in;
    Register out;
  }

  type SetInst {
    Register src;
    Register dst;
  }

  type VarInst {
    Register reg;
  }

  type DeclInst {
    Register reg;
    Node tp;
  }

  type ArgInst {
    Register reg;
    Node tp;
  }

  type LblInst {
    string name;
  }

  type JmpInst {
    string name;
    int index;
    int line;
  }

  type JifInst {
    string label;
    Register cond;
    int index;
    bool is_nif;
  }

  type ConstInst {
    Register reg;
    any value;
  }

  type UnopInst {
    string op;
    Register out;
    Register in;
    Node node;
  }

  type BinopInst {
    string op;
    Register out;
    Register left;
    Register right;
    Node node;
  }

  RetInst voidRetInst (Node);
}

// =============================== //
//               Types             //
// =============================== //

import auro.utils.stringmap (any) {
  type `` as Map {
    new ();
    any? get (string);
    void set (string, any);
  }
}

struct Pair { string k; any v; }
import auro.utils.arraylist (Pair) {
  type `` as `Pair[]` {
    new ();
    int len();
    Pair get (int);
    void push (Pair);
  }
}

struct Imported {
  Module mod;
  string name;
}

struct Module {
  int id;
  string kind;
  string name;
  any base;
  any argument;
  Pair[] items;
  int line;

  void set (Module this, string k, any v) {
    this.items.push(new Pair(k, v));
  }
}

struct Type {
  int id;
  string name;
  any mod;
  string builtin;
}

struct Line {
  int inst;
  int line;
}

struct Function {
  int id;
  string name;
  int line;
  any mod;
  any[] ins;
  any[] outs;
  any[]? code;
  Line[] lines;
}

struct Const {
  int id;
  string kind;
  any value;
}

struct Import {
  any mod;
  Map items;
}

import auro.utils.arraylist (Module) {
  type `` as `Module[]` {
    new ();
    int len();
    Module get (int);
    void set (int, Module);
    void push (Module);
    void remove (int);
  }
}

import auro.utils.arraylist (Type) {
  type `` as `Type[]` {
    new ();
    int len();
    Type get (int);
    void push (Type);
    void remove (int);
  }
}

import auro.utils.arraylist (Function) {
  type `` as `Function[]` {
    new ();
    int len();
    Function get (int);
    void push (Function);
    void remove (int);
  }
}

import auro.utils.arraylist (Const) {
  type `` as `Const[]` {
    new ();
    int len();
    Const get (int);
    void push (Const);
  }
}

import auro.utils.arraylist (any) {
  type `` as `any[]` {
    new ();
    int len();
    any get (int);
    void set (int, any);
    void push (any);
    void remove (int);
  }
}

import auro.utils.arraylist (Item) {
  type `` as `Item[]` {
    new ();
    int len();
    Item get (int);
    void push (Item);
  }
}

// When changing the fields of the Compiler object, change also the only
// constructor, in the function compile, in the section Compiler
struct Compiler {
  string filename;
  Node program;
  Map items;
  Writer writer;

  Module[] modules;
  Type[] types;
  Function[] functions;
  Const[] consts;

  Map builtins;
  Map imports;
  any exported;

  Item[] all_items;

  any? getFromNode (Compiler this, Node node) {
    if (node.tp == "field") {
      Item modItem = new Item("module", node.child(0));
      Module mod = this.getItem(modItem as any) as Module;
      Imported imp = new Imported(mod, node.val);

      return (imp as any) as any?;
    } else if ((node.tp == "item") || (node.tp == "var")) {
      any? a = this.items[node.val];
      if (!a.isnull()) return a;

      if (is_builtin_name(node.val)) {
        return get_builtin(this, node.val) as any?;
      }

      return new any?();
    } else {
      this.error("Unsupported item " + node.tp, node.line);
    }
  }

  any getItem (Compiler this, any a) {
    if (a is Item) {
      Item item = a as Item;

      if (!(item.value is bool)) return item.value;

      any? _a = this.getFromNode(item.node);
      if (_a.isnull()) this.error(item.to_str() + " not found", item.node.line);
      a = _a.get();

      if ((item.node.tp == "item") && (item.node.val == "string")) {
        Type m = a as Type;
      }

      if (a is Imported) {
        Imported imp = a as Imported;
        if (item.tp == "type") a = this.Type(imp.name, imp.mod as any) as any;
        else this.error("Cannot import " + item.to_str(), item.node.line);
      }

      item.value = a;

      string atp = "unknown";
      if (a is Module) atp = "module";
      if (a is Type) atp = "type";
      if (a is Function) atp = "function";
      if ((item.tp == atp) || ((item.tp == "item") && !(atp == "unknown"))) return a;
      this.error(item.node.to_string() + " is a " + atp, item.node.line);
    }
    return a;
  }

  Module Module (Compiler this) {
    Module mod = new Module(this.modules.len() + 1, "", "", false as any, false as any, new Pair[](), 0);
    this.modules.push(mod);
    return mod;
  }

  Type Type (Compiler this, string name, any mod) {
    Type t = new Type(this.types.len(), name, mod, "");
    this.types.push(t);
    return t;
  }

  Function Function (Compiler this) {
    Function f = new Function(this.functions.len(), "", 0, false as any, new any[](), new any[](), new any[]?(), new Line[]());
    this.functions.push(f);
    return f;
  }

  Const Const (Compiler this, string kind, any value) {
    Const c = new Const(this.consts.len(), kind, value);
    this.consts.push(c);
    return c;
  }

  Item Item (Compiler this, string tp, Node node) {
    Item it = new Item(tp, node);
    this.all_items.push(it);
    return it;
  }

  void error (Compiler this, string msg, int line) {
    error(msg + ", at " + this.filename + " at line " + itos(line));
  }
}

// =============================== //
//             Builtins            //
// =============================== //

bool is_builtin_name (string s) {
  return (s == "string") || (s == "int") || (s == "bool") || (s == "float") ||
    (s == "println") || (s == "itos") || (s == "ftos") || (s == "itof") || (s == "ftoi");
}

any builtin_module (Compiler this, string name, string modname) {
  Module mod = this.Module();
  mod.kind = "import";
  mod.name = modname;
  this.builtins[name] = mod as any;
  return mod as any;
}

any builtin_type (Compiler this, string name, string modnm, string typenm) {
  Module mod = get_builtin(this, modnm) as Module;
  Type t = this.Type(typenm, mod as any);
  t.builtin = name;
  this.builtins[name] = t as any;
  return t as any;
}

Function builtin_function (Compiler this, string name, string modnm, string fnm) {
  Module mod = get_builtin(this, modnm) as Module;
  Function f = this.Function();
  f.mod = mod as any;
  f.name = fnm;
  this.builtins[name] = f as any;
  return f;
}

any get_builtin (Compiler this, string name) {
  any? maybe = this.builtins[name];
  if (!maybe.isnull()) return maybe.get();

  if (name == "system_module")
    return builtin_module(this, name, "auro\x1fsystem");
  if (name == "string_module")
    return builtin_module(this, name, "auro\x1fstring");
  if (name == "int_module")
    return builtin_module(this, name, "auro\x1fint");
  if (name == "float_module")
    return builtin_module(this, name, "auro\x1ffloat");
  if (name == "bool_module")
    return builtin_module(this, name, "auro\x1fbool");
  if (name == "buffer_module")
    return builtin_module(this, name, "auro\x1fbuffer");

  if (name == "string")
    return builtin_type(this, name, "string_module", "string");
  if (name == "int")
    return builtin_type(this, name, "int_module", "int");
  if (name == "float")
    return builtin_type(this, name, "float_module", "float");
  if (name == "bool")
    return builtin_type(this, name, "bool_module", "bool");
  if (name == "buffer")
    return builtin_type(this, name, "buffer_module", "buffer");

  if (name == "new_string") {
    Function f = builtin_function(this, name, "string_module", "new");
    f.ins.push(get_builtin(this, "buffer"));
    f.outs.push(get_builtin(this, "string"));
    return f as any;
  }

  if (name == "true") {
    Function f = builtin_function(this, name, "bool_module", "true");
    f.outs.push(get_builtin(this, "bool"));
    return f as any;
  }

  if (name == "false") {
    Function f = builtin_function(this, name, "bool_module", "false");
    f.outs.push(get_builtin(this, "bool"));
    return f as any;
  }

  if (name == "not") {
    Function f = builtin_function(this, name, "bool_module", "not");
    any t = get_builtin(this, "bool");
    f.ins.push(t);
    f.outs.push(t);
    return f as any;
  }

  if (name == "ineg") {
    Function f = builtin_function(this, name, "int_module", "neg");
    any t = get_builtin(this, "int");
    f.ins.push(t);
    f.outs.push(t);
    return f as any;
  }

  if (name == "iadd" || (name == "isub") || (name == "imul") || (name == "idiv")) {
    string fname;
    if (name == "iadd") fname = "add";
    if (name == "isub") fname = "sub";
    if (name == "imul") fname = "mul";
    if (name == "idiv") fname = "div";

    Function f = builtin_function(this, name, "int_module", fname);
    any t = get_builtin(this, "int");
    f.ins.push(t);
    f.ins.push(t);
    f.outs.push(t);
    return f as any;
  }

  if (name == "fadd" || (name == "fsub") || (name == "fmul") || (name == "fdiv")) {
    string fname;
    if (name == "fadd") fname = "add";
    if (name == "fsub") fname = "sub";
    if (name == "fmul") fname = "mul";
    if (name == "fdiv") fname = "div";

    Function f = builtin_function(this, name, "float_module", fname);
    any t = get_builtin(this, "float");
    f.ins.push(t);
    f.ins.push(t);
    f.outs.push(t);
    return f as any;
  }

  if (name == "ieq" || (name == "ine") || (name == "ilt") || (name == "igt") || (name == "ile") || (name == "ige")) {
    string fname;
    if (name == "ieq") fname = "eq";
    if (name == "ine") fname = "ne";
    if (name == "ilt") fname = "lt";
    if (name == "igt") fname = "gt";
    if (name == "ile") fname = "le";
    if (name == "ige") fname = "ge";

    Function f = builtin_function(this, name, "int_module", fname);
    any t = get_builtin(this, "int");
    f.ins.push(t);
    f.ins.push(t);
    f.outs.push(get_builtin(this, "bool"));
    return f as any;
  }

  if (name == "feq" || (name == "fne") || (name == "flt") || (name == "fgt") || (name == "fle") || (name == "fge")) {
    string fname;
    if (name == "feq") fname = "eq";
    if (name == "fne") fname = "ne";
    if (name == "flt") fname = "lt";
    if (name == "fgt") fname = "gt";
    if (name == "fle") fname = "le";
    if (name == "fge") fname = "ge";

    Function f = builtin_function(this, name, "float_module", fname);
    any t = get_builtin(this, "float");
    f.ins.push(t);
    f.ins.push(t);
    f.outs.push(get_builtin(this, "bool"));
    return f as any;
  }

  if (name == "println") {
    Function f = builtin_function(this, name, "system_module", "println");
    f.ins.push(get_builtin(this, "string"));
    return f as any;
  }

  if (name == "itof") {
    Function f = builtin_function(this, name, "float_module", "itof");
    f.ins.push(get_builtin(this, "int"));
    f.outs.push(get_builtin(this, "float"));
    return f as any;
  }

  if (name == "ftoi") {
    Function f = builtin_function(this, name, "float_module", "ftoi");
    f.ins.push(get_builtin(this, "float"));
    f.outs.push(get_builtin(this, "int"));
    return f as any;
  }

  if (name == "itos") {
    Function f = builtin_function(this, name, "string_module", "itos");
    f.ins.push(get_builtin(this, "int"));
    f.outs.push(get_builtin(this, "string"));
    return f as any;
  }

  if (name == "ftos") {
    Function f = builtin_function(this, name, "string_module", "ftos");
    f.ins.push(get_builtin(this, "float"));
    f.outs.push(get_builtin(this, "string"));
    return f as any;
  }

  if (name == "concat") {
    Function f = builtin_function(this, name, "string_module", "concat");
    any t = get_builtin(this, "string");
    f.ins.push(t);
    f.ins.push(t);
    f.outs.push(t);
    return f as any;
  }

  if (name == "streq") {
    Function f = builtin_function(this, name, "string_module", "eq");
    any t = get_builtin(this, "string");
    f.ins.push(t);
    f.ins.push(t);
    f.outs.push(get_builtin(this, "bool"));
    return f as any;
  }

  error(name + " is not a builtin item");
}


// =============================== //
//             Compiler            //
// =============================== //

void transform_instructions (Compiler this, Function f) {
  any[] code = f.code.get();
  int reg_count = 0;

  Map label_map = new Map();

  if (f.outs.len() == 0 && (code.len() == 0 || !(code[code.len() - 1] is RetInst))) {
    code.push(voidRetInst(this.program) as any);
  }

  int i = 0;
  while (i < code.len()) {
    any inst = code[i];

    if (inst is CallInst) {
      CallInst call = inst as CallInst;

      Item it = call.fn as Item;
      Function fn = this.getItem(it as any) as Function;

      call.fn = fn as any;
      
      if (!(call.ins_len() == fn.ins.len())) {
        this.error(
          it.to_str() + " expects " +
          itos(fn.ins.len()) + " arguments, but " +
          itos(call.ins_len()) + " were given",
          call.node.line
        );
      }

      if (call.outs_len() > fn.outs.len()) {
        this.error(
          it.to_str() + " returns " +
          itos(fn.outs.len()) + " arguments, but " +
          itos(call.outs_len()) + " were expected",
          call.node.line
        );
      }

      // TODO: Arguments typecheck (what to error?)
      /*int k = 0;
      while (k < call.ins_len()) {
        call.in(k).tp = this.getItem(fn.ins[k]);
        k = k+1;
      }*/

      int k = 0;
      while (k < call.outs_len()) {
        call.out(k).id = reg_count + k;
        call.out(k).tp = this.getItem(fn.outs[k]);
        k = k+1;
      }
      reg_count = reg_count + fn.outs.len();

      f.lines.push(new Line(i, call.node.line));
    }

    if (inst is RetInst) {
      RetInst ret = inst as RetInst;
      if (!(f.outs.len() == ret.vals_len())) {
        this.error("Function returns " + itos(f.outs.len()) + " values", ret.node.line);
      }

      // TODO: Return typecheck (what to error?)
      /*int k = 0;
      while (k < call.outs_len()) {
        call.out(k).id = reg_count + k;
        call.out(k).tp = this.getItem(fn.outs[k]);
        k = k+1;
      }*/
    }

    if (inst is DeclInst) {
      DeclInst decl = inst as DeclInst;
      decl.reg.id = reg_count;
      decl.reg.tp = this.getItem(new Item("type", decl.tp) as any);
      reg_count = reg_count + 1;
    }

    if (inst is ArgInst) {
      ArgInst arg = inst as ArgInst;
      arg.reg.id = reg_count;
      arg.reg.tp = this.getItem(new Item("type", arg.tp) as any);
      reg_count = reg_count + 1;

      code.remove(i);
      i = i-1;
    }

    if (inst is VarInst) {
      (inst as VarInst).reg.id = reg_count;
      reg_count = reg_count + 1;
    }

    if (inst is DupInst) {
      DupInst dup = inst as DupInst;
      dup.out.id = reg_count;
      dup.out.tp = dup.in.tp;
      reg_count = reg_count + 1;
    }

    if (inst is SetInst) {
      SetInst set = inst as SetInst;
      if (set.dst.tp is bool) {
        set.dst.tp = set.src.tp;
      } else {
        // Typecheck
      }
    }

    if (inst is ConstInst) {
      ConstInst _inst = inst as ConstInst;
      any tp;
      if (_inst.value is int) {
        Const const = this.Const("int", _inst.value);
        _inst.value = const as any;
        tp = get_builtin(this, "int");
      } else if (_inst.value is string) {
        Const bin = this.Const("bin", _inst.value);

        any[] call = new any[]();
        call.push(get_builtin(this, "new_string"));
        call.push(bin as any);

        Const const = this.Const("call", call as any);
        _inst.value = const as any;
        tp = get_builtin(this, "string");
      } else if (_inst.value is bool) {
        Function f;
        if (_inst.value as bool) 
          f = get_builtin(this, "true") as Function;
        else
          f = get_builtin(this, "false") as Function;

        CallInst call = new CallInst(f as any, this.program);
        call.outs_push(_inst.reg);
        code[i] = call as any;
        tp = get_builtin(this, "bool");
      } else {
        this.error("Unknown constant value type", 0-1);
      }

      _inst.reg.id = reg_count;
      _inst.reg.tp = tp;
      reg_count = reg_count + 1;
    }

    if (inst is UnopInst) {
      UnopInst unop = inst as UnopInst;
      string fname;
      if (unop.op == "-") fname = "ineg";
      else if (unop.op == "!") fname = "not";
      else // TODO: Better error message
        this.error("Unsupported unary operator " + unop.op, 0-1);

      Function fn = get_builtin(this, fname) as Function;
      CallInst call = new CallInst(fn as any, unop.node);
      call.ins_push(unop.in);
      call.outs_push(unop.out);

      unop.out.id = reg_count;
      unop.out.tp = fn.outs[0];
      
      code[i] = call as any;
      reg_count = reg_count + 1;
    }

    if (inst is BinopInst) {
      BinopInst binop = inst as BinopInst;
      Type lt = this.getItem(binop.left.tp) as Type;
      Type rt = this.getItem(binop.right.tp) as Type;

      int line = binop.node.line;
      string fname;
      if (lt.builtin == "string" && (rt.builtin == "string")) {
        if (binop.op == "+") fname = "concat";
        else if (binop.op == "==") fname = "streq";
        else // TODO: Better error message
          this.error("Unsupported string operator " + binop.op, line);
      } else if (lt.builtin == "int" && (rt.builtin == "int")) {
        if (binop.op == "+") fname = "iadd";
        else if (binop.op == "-") fname = "isub";
        else if (binop.op == "*") fname = "imul";
        else if (binop.op == "/") fname = "idiv";

        else if (binop.op == "<") fname = "ilt";
        else if (binop.op == ">") fname = "igt";
        else if (binop.op == "<=") fname = "ile";
        else if (binop.op == ">=") fname = "ige";
        else if (binop.op == "==") fname = "ieq";
        else if (binop.op == "!=") fname = "ine";

        else // TODO: Better error message
          this.error("Unsupported int operator " + binop.op, line);

      } else if (lt.builtin == "float" && (rt.builtin == "float")) {
        if (binop.op == "+") fname = "fadd";
        else if (binop.op == "-") fname = "fsub";
        else if (binop.op == "*") fname = "fmul";
        else if (binop.op == "/") fname = "fdiv";

        else if (binop.op == "<") fname = "flt";
        else if (binop.op == ">") fname = "fgt";
        else if (binop.op == "<=") fname = "fle";
        else if (binop.op == ">=") fname = "fge";
        else if (binop.op == "==") fname = "feq";
        else if (binop.op == "!=") fname = "fne";

        else // TODO: Better error message
          this.error("Unsupported float operator " + binop.op, line);
      } else {
        // TODO: Awful error message
        this.error("Cannot operate these types", line);
      }
      Function fn = get_builtin(this, fname) as Function;

      CallInst call = new CallInst(fn as any, binop.node);
      call.ins_push(binop.left);
      call.ins_push(binop.right);
      call.outs_push(binop.out);

      binop.out.id = reg_count;
      binop.out.tp = fn.outs[0];
      
      code[i] = call as any;
      reg_count = reg_count + 1;
    }

    if (inst is LblInst) {
      label_map[(inst as LblInst).name] = i as any;
      code.remove(i);
      i = i-1;
    }

    i = i+1;
  }

  int i = 0;
  while (i < code.len()) {
    any inst = code[i];
    
    if (inst is JmpInst) {
      JmpInst _inst = inst as JmpInst;
      string name = _inst.name;
      any? a = label_map[name];
      if (a.isnull()) this.error("Unknown label " + name, _inst.line);
      _inst.index = a.get() as int;
    }

    if (inst is JifInst) {
      JifInst _inst = inst as JifInst;
      _inst.index = label_map[_inst.label].get() as int;
    }

    i = i+1;
  }
}

any compile_module_expr (Compiler this, Node node) {
  if (node.tp == "item") {
    return this.Item("module", node) as any;
  }

  Module mod = this.Module();
  mod.line = node.line;

  if (node.tp == "import") {
    mod.kind = "import";
    mod.name = node.val;
    //c.imports[mod.name] = new Import(mod as any, new Map());
  } else if (node.tp == "functor") {
    mod.kind = "build";
    mod.base = compile_module_expr(this, node.child(0));
    mod.argument = compile_module_expr(this, node.child(1));
  } else if (node.tp == "field") {
    mod.kind = "use";
    mod.base = compile_module_expr(this, node.child(0));
    mod.name = node.val;
  } else if (node.tp == "module-def") {
    mod.kind = "define";
    int j = 0;
    while (j < node.len()) {
      Node inode = node.child(j);
      string alias = inode.val;

      any item = this.Item("item", inode.child(0)) as any;
      mod[alias] = item;
      j = j+1;
    }
  } else this.error(node.tp + " module expression", node.line);

  return mod as any;
}

buffer compile (Node program, string filename) {
  Compiler c = new Compiler (
    filename, program,
    new Map(), new Writer(),
    new Module[](), new Type[](), new Function[](), new Const[](),
    new Map(), new Map(), false as any, new Item[]()
  );
  Module exported = c.Module(); // First module is the exported module
  exported.kind = "define";

  int i = 0;
  while (i < c.program.len()) {
    Node node = c.program.child(i);
    i = i+1;

    bool public = true;
    if (node.tp == "private") {
      public = false;
      node = node.child(0);
    }

    if (node.tp == "module-assign") {
      c.items[node.val] = compile_module_expr(c, node.child(0));
    }

    else if (node.tp == "type-assign") {
      Node def = node.child(0);

      if (!(def.tp == "field"))
        c.error("Invalid type definition: " + def.to_string(), node.line);

      Type t = c.Type(def.val, c.Item("module", def.child(0)) as any);
      c.items[node.val] = t as any;
    }

    else if (node.tp == "function") {
      Function f = c.Function();

      Node in_node = node.child(0);
      int i = 0;
      while (i < in_node.len()) {
        Node t_node = in_node.child(i).child(0);

        any t_any = c.Item("type", t_node) as any;

        f.ins.push(t_any);
        i = i+1;
      }

      Node out_node = node.child(1);
      int i = 0;
      while (i < out_node.len()) {
        Node t_node = out_node.child(i);

        any t_any = c.Item("type", t_node) as any;

        f.outs.push(t_any);
        i = i+1;
      }

      Node body = node.child(2);

      if (body.tp == "field") {
        f.name = body.val;
        f.mod = c.Item("module", body.child(0)) as any;
      } else if (body.tp == "block") {
        f.name = node.val;
        f.code = compile_function(body, node) as any[]?;
      } else {
        c.error("Currently only imported functions are supported", node.line);
      }

      c.items[node.val] = f as any;
      if (public) {
        exported[node.val] = f as any;
      }
    }

    else if (node.tp == "export") {
      node child = node.child(0);
      if (!(c.exported is bool))
        c.error("Export overrides previous export", node.line);

      c.exported = c.Item("module", child) as any;
    }
  }

  // Define export
  if (!(c.exported is bool)) {
    Module mod = c.getItem(c.exported) as Module;
    c.modules[0] = mod;
    int i = mod.id - 1;
    c.modules.remove(i);
    mod.id = 0;
    while (i < c.modules.len()) {
      c.modules[i].id = i+1;
      i = i+1;
    }
  }

  // Transform function instructions
  int i = 0;
  while (i < c.functions.len()) {
    Function f = c.functions[i];
    if (!f.code.isnull())
      transform_instructions(c, f);
    i = i+1;
  }

  // Force all items resolutions
  int i = 0;
  while (i < c.all_items.len()) {
    c.getItem(c.all_items[i] as any);
    i = i+1;
  }

  return getBuffer(c);
}

// =============================== //
//              Writer             //
// =============================== //

void writeModules (Compiler c) {
  Writer w = c.writer;
  Module[] mods = c.modules;

  w.num(mods.len());

  int i = 0;
  while (i < mods.len()) {
    Module mod = mods[i];
    i = i+1;
    if (mod.kind == "import") {
      w.byte(1);
      w.str(mod.name);
    } else if (mod.kind == "define") {
      w.byte(2);
      w.num(mod.items.len());
      int j = 0;
      while (j < mod.items.len()) {
        Pair p = mod.items[j];
        any item = c.getItem(p.v);
        int k, id;
        if (item is Module) {
          k = 0; id = (item as Module).id;
        } else if (item is Type) {
          k = 1; id = (item as Type).id;
        } else if (item is Function) {
          k = 2; id = (item as Function).id;
        } else error("???");
        w.byte(k);
        w.num(id);
        w.str(p.k);
        j = j+1;
      }
    } else if (mod.kind == "use") {
      w.byte(3);
      Module base = c.getItem(mod.base) as Module;
      w.num(base.id);
      w.str(mod.name);
    } else if (mod.kind == "build") {
      w.byte(4);
      Module base = c.getItem(mod.base) as Module;
      Module arg = c.getItem(mod.argument) as Module;
      w.num(base.id);
      w.num(arg.id);
    }
    else error("What am i doing?" + mod.kind);
  }
}

void writeTypes (Compiler c) {
  Writer w = c.writer;

  w.num(c.types.len());

  int i = 0;
  while (i < c.types.len()) {
    Type t = c.types[i];
    i = i+1;
    Module mod = c.getItem(t.mod) as Module;
    w.num(mod.id + 1);
    w.str(t.name);
  }
}

void writeFunctions (Compiler c) {
  Writer w = c.writer;

  w.num(c.functions.len());

  int codes = 0;

  Function[] code_functions = new Function[]();

  int i = 0;
  while (i < c.functions.len()) {
    Function f = c.functions[i];
    i = i+1;
    if (f.code.isnull()) {
      Module mod = c.getItem(f.mod) as Module;
      w.num(mod.id + 2);
    } else {
      w.byte(1);
    }

    int j = 0;
    int inc = f.ins.len();
    w.num(inc);
    while (j < inc) {
      w.num((c.getItem(f.ins[j]) as Type).id);
      j = j+1;
    }

    int j = 0;
    int outc = f.outs.len();
    w.num(outc);
    while (j < outc) {
      w.num((c.getItem(f.outs[j]) as Type).id);
      j = j+1;
    }

    if (f.code.isnull()) {
      w.str(f.name);
    } else {
      code_functions.push(f);
    }
  }
}

void writeConstants (Compiler c) {
  Writer w = c.writer;

  w.num(c.consts.len());

  int i = 0;
  while (i < c.consts.len()) {
    Const cns = c.consts[i];
    i = i+1;
    
    if (cns.kind == "int") {
      w.byte(1);
      w.num(cns.value as int);
    } else if (cns.kind == "bin") {
      string str = cns.value as string;
      w.byte(2);
      // TODO: manually write utf8, rather than assume it
      w.num(strlen(str));
      w.rawstr(str);
    } else if (cns.kind == "call") {
      any[] xs = cns.value as any[];
      Function f = c.getItem(xs[0]) as Function;
      w.byte(f.id + 16);


      if (!(xs.len()-1 == f.ins.len()))
        error("Argument mismatch");
        
      int j = 1;
      while (j < xs.len()) {
        // Functions can also exist. Use items instead
        w.num((xs[j] as Const).id + c.functions.len());
        j = j+1;
      }
    } else {
      c.error("Unknown Constant kind " + cns.kind, 0-1);
    }
  }
}

void writeCode (Compiler c) {
  Writer w = c.writer;
  
  int i = 0;
  while (i < c.functions.len()) {
    Function f = c.functions[i];
    if (f.code.isnull()) goto skip;

    any[] code = f.code.get();

    w.num(code.len());

    int j = 0;
    while (j < code.len()) {
      any inst = code[j];

      if (inst is CallInst) {

        CallInst call = inst as CallInst;
        Function fn = call.fn as Function;

        w.num(fn.id + 16);

        int k = 0;
        while (k < call.ins_len()) {
          w.num(call.in(k).id);
          k = k+1;
        }

      } else if (inst is ConstInst) {

        Const cns = (inst as ConstInst).value as Const;
        w.num(cns.id + c.functions.len() + 16);

      } else if (inst is RetInst) {
        RetInst ret = inst as RetInst;

        w.byte(0);
        int k = 0;
        while (k < ret.vals_len()) {
          w.num(ret.val(k).id);
          k = k+1;
        }
      } else if (inst is VarInst || (inst is DeclInst)) {
        w.byte(2);
      } else if (inst is DupInst) {
        w.byte(3);
        w.num((inst as DupInst).in.id);
      } else if (inst is SetInst) {
        SetInst set = inst as SetInst;
        w.byte(4);
        w.num(set.dst.id);
        w.num(set.src.id);
      } else if (inst is JmpInst) {
        w.byte(5);
        w.num((inst as JmpInst).index);
      } else if (inst is JifInst) {
        JifInst jif = inst as JifInst;
        if (jif.is_nif) w.byte(7);
        else w.byte(6);
        w.num(jif.index);
        w.num(jif.cond.id);
      } else error("Unsupported instruction: " + inst_name(inst));

      j = j+1;
    }

    skip:
    i = i+1;
  }
}

void writeMetadata (Compiler c) {
  Writer w = c.writer;

  // Third item, function list
  int fcount = 0;
  int i = 0;
  while (i < c.functions.len()) {
    Function f = c.functions[i];
    if (!f.code.isnull())
      fcount = fcount+1;
    i = i+1;
  }

  int itemcount = fcount + 2; // "source map" + file + functions

  w.num(4); // 1 items (1<<2)
    w.num(itemcount*4); // items
      w.num(42); // 10 chars (10<<2 | 2)
      w.rawstr("source map");

      w.num(8); // 2 items (2<<2)
        w.num(18); // 10 chars (4<<2 | 2)
        w.rawstr("file");
        w.num(strlen(c.filename)*4 + 2);
        w.rawstr(c.filename);

  int i = 0;
  while (i < c.functions.len()) {
    Function f = c.functions[i];
    if (!f.code.isnull()) {
      w.num(5*4); // 5 items

      w.num(34); // 8 characters
      w.rawstr("function");

      w.num((i*2)+1);

      w.num(8); // 2 items
        w.num(18); // 4 chars
        w.rawstr("name");

        w.num((strlen(f.name)*4)+2);
        w.rawstr(f.name);

      w.num(8); // 2 items
        w.num(18); // 4 chars
        w.rawstr("line");

        w.num((f.line*2)+1);

      int lcount = f.lines.len();
      w.num((lcount+1)*4);
        w.num(18); // 4 chars
        w.rawstr("code");

        int j = 0;
        while (j < lcount) {
          Line ln = f.lines[j];
          w.num(8); // 2 items
          w.num((ln.inst*2)+1);
          w.num((ln.line*2)+1);
          j = j+1;
        }
    }
    i = i+1;
  }
}

buffer getBuffer (Compiler c) {
  Writer w = c.writer;

  w.rawstr("Auro 0.6");
  w.byte(0);

  writeModules(c);
  writeTypes(c);
  writeFunctions(c);
  writeConstants(c);
  writeCode(c);
  writeMetadata(c);

  return w.tobuffer();
}

// =============================== //
//             Interface           //
// =============================== //

buffer compile_src (string src, string filename) {
  return compile(parse(src), filename);
}

import auro.io {
  type file;
  type mode as filemode;
  filemode w ();
  file open (string, filemode);
  void write (file, buffer);
}

import aulang.util { string readall (string); }

void main () {
  buffer buf = compile_src(readall("test.au"), "test.au");
  file f = open("out", w());
  write(f, buf);
}