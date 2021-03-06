
// TODO: Use compiler error message
import auro.system { void error(string); }
import auro.string {
  string itos(int);
  int length (string) as strlen;

  int codeof (char);
  char, int charat(string, int);
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

import aulang.item {
  type Item {
    new (string tp, Node node);
    string tp;
    Node node;
    any value;
    string to_str();
  }
}

struct Register {
  int id;
  string name;
  any tp;
}

Register newReg (string name) { return new Register(0-1, name, false as any); }

import auro.utils.stringmap (Register) {
  type `` as RegMap {
    new ();
    Register? get (string);
    void set (string, Register);
  }
}

struct CallInst {
  any fn;
  Register[] ins;
  Register[] outs;
  Node node;
  int index;

  int ins_len (CallInst this) { return this.ins.len(); }
  int outs_len (CallInst this) { return this.outs.len(); }
  Register in (CallInst this, int i) { return this.ins[i]; }
  Register out (CallInst this, int i) { return this.outs[i]; }
  void ins_push (CallInst this, Register r) { this.ins.push(r); }
  void outs_push (CallInst this, Register r) { this.outs.push(r); }
}

struct RetInst {
  Register[] vals;
  Node node;

  int vals_len (RetInst this) { return this.vals.len(); }
  Register val (RetInst this, int i) { return this.vals[i]; }
}

struct DupInst {
  Register in;
  Register out;
}

struct SetInst {
  Register src;
  Register dst;

  // Necessary because this struct has the same structure as Dup,
  // and aulang doesn't yet support full types
  bool dummy;
}

struct VarInst {
  Register reg;
}

struct DeclInst {
  Register reg;
  Node tp;
}

struct ArgInst {
  Register reg;
  Node tp;
  bool dummy;
}

struct LblInst {
  string name;
}

struct JmpInst {
  string name;
  int index;
  int line;
}

struct JifInst {
  string label;
  Register cond;
  int index;
  bool is_nif;
}

struct ConstInst {
  Register reg;
  any value;
}

struct UnopInst {
  string op;
  Register in;
  Register out;
  Node node;
}

struct BinopInst {
  string op;
  Register left;
  Register right;
  Register out;
  Node node;
}

private CallInst _new_call (any fn, Node node) {
  return new CallInst(fn, new Register[](), new Register[](), node, 0);
}
export _new_call as `new\x1dCallInst`;

RetInst voidRetInst (Node node) {
  return new RetInst(new Register[](), node);
}


string inst_name (any x) {
  if (x is CallInst) return "CallInst";
  if (x is RetInst) return "RetInst";
  if (x is DupInst) return "DupInst";
  if (x is SetInst) return "SetInst";
  if (x is VarInst) return "VarInst";
  if (x is DeclInst) return "DeclInst";
  if (x is ArgInst) return "ArgInst";
  if (x is JmpInst) return "JmpInst";
  if (x is JifInst) return "JifInst";
  if (x is LblInst) return "LblInst";
  if (x is ConstInst) return "ConstInst";
  if (x is UnopInst) return "UnopInst";
  if (x is BinopInst) return "BinopInst";

  bool b = x as bool; // Trigger implementation specific error message
  error("Unknown instruction type");
}

import auro.utils.arraylist (any) {
  type `` as AnyList {
    new ();
    int len();
    any get (int);
    void push (any);
  }
}

struct LoopInfo {
  string name;
  string start;
  string end;
}

LoopInfo newLoopInfo (Scope s, string name) {
  return new LoopInfo(name, s.label(), s.label());
}

struct Scope {
  RegMap vars;
  AnyList code;
  ScopeBox? parent;
  int temp_labels;
  LoopInfo? loop;

  void inst (Scope this, any inst) {
    this.code.push(inst);
  }

  Register get_var (Scope this, string name, Node node) {
    Register? here = this.vars[name];
    if (here.isnull()) {
      if (this.parent.isnull()) {
        error("Variable " + name + " not found");
      }
      return (this.parent.get() as Scope).get_var(name, node);
    }
    return here.get();
  }

  string label (Scope this) {
    if (this.parent.isnull()) {
      this.temp_labels = this.temp_labels + 1;
      return ".label_" + itos(this.temp_labels);
    } else return (this.parent.get() as Scope).label();
  }

  LoopInfo getLoopInfo (Scope this, string name, int line) {
    if (!this.loop.isnull()) {
      LoopInfo loop = this.loop.get();
      if (name == "" || (loop.name == name))
        return loop;
    }
    if (this.parent.isnull()) {
      if (name == "")
        error("Not in loop " + name + ", at line " + itos(line));
      else
        error("Not in a loop, at line " + itos(line));
    }
    return (this.parent.get() as Scope).getLoopInfo(name, line);
  }

}
type ScopeBox (Scope);

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

Register compile_expr (Scope s, Node node) {
  if (node.tp == "var") {
    return s.get_var(node.val, node);
  }
  if (node.tp == "call") {
    Register out = newReg("");
    Register outs = new Register[]();
    outs.push(out);
    compile_call(s, node, outs);
    return out;
  }
  if (node.tp == "num") {
    Register reg = newReg("");
    int value = atoi(node.val);
    s.inst(new ConstInst(reg, value as any) as any);
    return reg;
  }
  if (node.tp == "str") {
    Register reg = newReg("");
    s.inst(new ConstInst(reg, node.val as any) as any);
    return reg;
  }
  if (node.tp == "true") {
    Register reg = newReg("");
    s.inst(new ConstInst(reg, true as any) as any);
    return reg;
  }
  if (node.tp == "false") {
    Register reg = newReg("");
    s.inst(new ConstInst(reg, false as any) as any);
    return reg;
  }
  if (node.tp == "unop") {
    Register reg = newReg("");
    s.inst(new UnopInst(node.val, compile_expr(s, node.child(0)), reg, node) as any);
    return reg;
  }
  if (node.tp == "binop") {
    Register reg = newReg("");
    Register l = compile_expr(s, node.child(0));
    Register r = compile_expr(s, node.child(1));
    s.inst(new BinopInst(node.val, l, r, reg, node) as any);
    return reg;
  }

  if (node.tp == "logic") {
    string end = s.label();

    Register reg = newReg("");
    s.inst(new VarInst(reg) as any);

    Register left = compile_expr(s, node.child(0));
    s.inst(new SetInst(left, reg, false) as any);

    bool is_nif;
    if (node.val == "||") is_nif = false;
    else if (node.val == "&&") is_nif = true;
    else error("logic operator " + node.val + " not supported, at line " + itos(node.line));
    s.inst(new JifInst(end, reg, 0, is_nif) as any);

    Register right = compile_expr(s, node.child(1));
    s.inst(new SetInst(right, reg, false) as any);

    s.inst(new LblInst(end) as any);
    return reg;
  }
  error(node.tp + " expressions not yet supported");
}

Register[] compile_expr_list (Scope s, Node node) {
  Register[] result = new Register[]();
  int i = 0;
  while (i < node.len()) {
    result.push(compile_expr(s, node.child(i)));
    i = i+1;
  }
  return result;
}

void compile_call (Scope s, Node node, Register[] outs) {
  Item fn = new Item("function", node.child(0));
  Register[] ins = compile_expr_list(s, node.child(1));
  s.inst(new CallInst(fn as any, ins, outs, node, 0) as any);
}

void compile_stmt (Scope s, Node node) {

  if (node.tp == "block") {
    Scope inner = new Scope(new RegMap(), s.code, s as ScopeBox as ScopeBox?, 0, new LoopInfo?());

    int i = 0;
    while (i < node.len()) {
      compile_stmt(inner, node.child(i));
      i = i+1;
    }
    return;
  }

  if (node.tp == "decl") {
    int i = 1;
    while (i < node.len()) {
      Node part = node.child(i);
      string name = part.val;
      Register reg = newReg(name);
      if (part.len() > 0) {
        Register in = compile_expr(s, part.child(0));
        s.inst(new DupInst(in, reg) as any);
      } else {
        s.inst(new DeclInst(reg, node.child(0)) as any);
      }
      s.vars[name] = reg;
      i = i+1;
    }
    return;
  }

  if (node.tp == "assignment") {
    Node left = node.child(0);
    Node right = node.child(1);

    if (left.len() > 1) {
      if (!(right.tp == "call")) {
        error("Expression does not have multiple values, at line " + itos(node.line));
      }

      Register[] regs = new Register[]();

      int i = 0;
      while (i < left.len()) {
        Register reg = newReg("");
        regs.push(reg);
        i = i+1;
      }


      compile_call(s, right, regs);
      
      int i = 0;
      while (i < left.len()) {
        Register src = regs[i];
        Register dst = s.get_var(left.child(i).val, left);
        s.inst(new SetInst(src, dst, false) as any);
        i = i+1;
      }
    } else {
      Register src = compile_expr(s, right);
      Register dst = s.get_var(left.child(0).val, left);
      s.inst(new SetInst(src, dst, false) as any);
    }

    return;
  }

  if (node.tp == "break") {
    LoopInfo loop = s.getLoopInfo(node.val, node.line);
    s.inst(new JmpInst(loop.end, 0, node.line) as any);
    return;
  }

  if (node.tp == "while") {
    LoopInfo loop = newLoopInfo(s, node.val);
    if (strlen(node.val) > 0) {
      s.inst(new LblInst(node.val) as any);
    }
    Scope inner = new Scope(new RegMap(), s.code, s as ScopeBox as ScopeBox?, 0, loop as LoopInfo?);

    s.inst(new LblInst(loop.start) as any);
    Register cond = compile_expr(inner, node.child(0));
    s.inst(new JifInst(loop.end, cond, 0, true) as any);
    compile_stmt(inner, node.child(1));
    s.inst(new JmpInst(loop.start, 0, 0) as any);
    s.inst(new LblInst(loop.end) as any);
    return;
  }

  if (node.tp == "if") {
    if (node.child(1).tp == "goto") {
      Register cond = compile_expr(s, node.child(0));
      Node gt = node.child(1);
      // May fail, would need line
      s.inst(new JifInst(gt.val, cond, 0, false) as any);
      return;
    }

    string els = s.label();
    Register cond = compile_expr(s, node.child(0));
    s.inst(new JifInst(els, cond, 0, true) as any);
    compile_stmt(s, node.child(1));
    if (node.len() == 3) {
      string end = s.label();
      s.inst(new JmpInst(end, 0, 0) as any);
      s.inst(new LblInst(els) as any);
      compile_stmt(s, node.child(2));
      s.inst(new LblInst(end) as any);
    } else {
      s.inst(new LblInst(els) as any);
    }
    return;
  }

  if (node.tp == "call") {
    compile_call(s, node, new Register[]());
    return;
  }

  if (node.tp == "return") {
    s.inst(new RetInst(compile_expr_list(s, node.child(0)), node) as any);
    return;
  }

  if (node.tp == "goto") {
    s.inst(new JmpInst(node.val, 0, node.line) as any);
    return;
  }

  if (node.tp == "label") {
    s.inst(new LblInst(node.val) as any);
    return;
  }

  error("Unknown statement: " + node.tp);
}

AnyList compile_function (Node body, Node node) {
  AnyList code = new AnyList();

  Scope scope = new Scope(new RegMap(), code, new ScopeBox?(), 0, new LoopInfo?());

  Node in_node = node.child(0);

  int i = 0;
  while (i < in_node.len()) {
    string name = in_node.child(i).val;
    Node tp = in_node.child(i).child(0);

    Register reg = newReg(name);
    scope.inst(new ArgInst(reg, tp, false) as any);
    scope.vars[name] = reg;
    i = i+1;
  }

  compile_stmt(scope, body);

  return code;
}
