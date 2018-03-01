
// =============================== //
//         Imports & Types         //
// =============================== //

import cobre.system {
  void print (string);
  void quit (int);
  string readall (string);
}

import cobre.string {
  string itos (int);
}

import cobre.array (NodeShell) {
  type `` as NodeArr {
    NodeShell get (int);
    void push (NodeShell);
    int len ();
  }
  NodeArr empty () as EmptyNodeArr;
}

type NodeShell (Node);

struct Node {
  string tp;
  string val;
  int line;
  NodeArr children;

  int len (Node this) {
    return this.children.len();
  }

  Node child (Node this, int index) {
    return this.children[index] as Node;
  }

  void push (Node this, Node child) {
    this.children.push(child as NodeShell);
  }

  void print (Node this, string indent) {
    string pos = "";
    if (this.line < 0) {}
    else { pos = "["+itos(this.line)+"] "; }

    print(indent + pos + this.tp + " " + this.val);
    int i = 0;
    while (i < this.len()) {
      this.child(i).print(indent + "  ");
      i = i+1;
    }
  }

  Node inline (Node this, int line) {
    this.line = line;
    return this;
  }
}

Node newNode (string tp, string val) {
  return new Node(tp, val, 0-1, EmptyNodeArr());
}

import lexer {
  TkArr tokens (string);

  type token {
    string tp;
    string val;
    int line;
  }
}

import cobre.array(token) {
  type `` as TkArr {
    token get (int);
    int len ();
  }
}

struct Parser {
  TkArr tokens;
  int pos;

  token peek (Parser this) {
    return this.tokens[this.pos];
  }

  token peekat(Parser this, int p) {
    return this.tokens[this.pos + p];
  }

  token next (Parser this) {
    token tk = this.peek();
    this.pos = this.pos + 1;
    return tk;
  }

  string getname (Parser this) {
    token tk = this.next();
    check(tk, "name");
    return tk.val;
  }

  bool maybe (Parser this, string tp) {
    if (this.peek().tp == tp) {
      this.next();
      return 0<1;
    }
    return 1<0;
  }

  int line (Parser this) {
    return this.peek().line;
  }
}

void error (string msg, token tk) {
  string pos = "line " + itos(tk.line);
  if (tk.tp == "eof") pos = "end of file";
  print("Parse error: " + msg + ", at " + pos);
  quit(1);
}

void check (token tk, string tp) {
  if (tk.tp == tp) {}
  else {
    error("expected " + tp + " but got " + tk.tp, tk);
  }
}




// =============================== //
//            Expressions          //
// =============================== //

bool isUnop (string ty) {
  if (ty == "-") return 0<1;
  if (ty == "!") return 0<1;
  return 0<0;
}

bool isBinop (string ty) {
  if (ty == "+") return 0<1;
  if (ty == "-") return 0<1;
  if (ty == "*") return 0<1;
  if (ty == "/") return 0<1;
  if (ty == "<") return 0<1;
  if (ty == ">") return 0<1;
  if (ty == "<=") return 0<1;
  if (ty == "==") return 0<1;
  if (ty == ">=") return 0<1;
  if (ty == "!=") return 0<1;
  return 0<0;
}

Node parseBaseExpr (Parser p) {
  int line = p.line();
  Node node;
  token tk = p.next();
  string ty = tk.tp;
  if (ty == "(") {
    Node node = parseExpr(p);
    check(p.next(), ")");
    return node;
  } else if (isUnop(ty)) {
    string op = ty;
    Node base = parseBaseExpr(p);
    node = newNode("unop", op);
    node.push(base);
  } else if (ty == "num") {
    node = newNode("num", tk.val);
  } else if (ty == "str") {
    node = newNode("str", tk.val);
  } else if (ty == "true") {
    node = newNode("true", "");
  } else if (ty == "false") {
    node = newNode("false", "");
  } else if (ty == "name") {
    node = newNode("var", tk.val);
  } else if (ty == "new") {
    node = newNode("new", p.getname());
    check(p.next(), "(");
    node.push(parseExprList(p, ")"));
  } else { error("invalid expression", tk); }
  return node.inline(line);
}

Node parseSuffix (Parser p) {
  Node base = parseBaseExpr(p);
  suffix:
    int line = p.line();
    if (p.maybe("(")) {
      Node nxt = newNode("call", "");
      nxt.push(base);
      nxt.push(parseExprList(p, ")"));
      base = nxt.inline(line);
      goto suffix;
    } else if (p.maybe(".")) {
      Node nxt = newNode("field", p.getname());
      nxt.push(base);
      base = nxt.inline(line);
      goto suffix;
    } else if (p.maybe("[")) {
      Node nxt = newNode("index", "");
      nxt.push(base);
      nxt.push(parseExpr(p));
      check(p.next(), "]");
      base = nxt.inline(line);
      goto suffix;
    }
  int line = p.line();
  if (p.maybe("as")) {
    Node nxt = newNode("cast", p.getname());
    nxt.push(base);
    base = nxt.inline(line);
  }
  return base;
}

Node parseExpr (Parser p) {
  Node left = parseSuffix(p);
  while (isBinop(p.peek().tp)) {
    string op = p.next().tp;
    Node right = parseSuffix(p);
    Node node = newNode("binop", op);
    node.push(left);
    node.push(right);
    left = node;
  }
  return left;
}

Node parseExprList (Parser p, string end) {
  Node node = newNode("exprlist", "");
  if (p.peek().tp == end) goto end;
  nextexpr:
    node.push(parseExpr(p));
    if (p.maybe(",")) goto nextexpr;
  end:
  check(p.next(), end);
  return node;
}




// =============================== //
//            Statements           //
// =============================== //

string parseLongName (Parser p) {
  string name = "";
  nextname:
    name = name + p.getname();
    if (p.peek().tp == ".") goto sep;
    if (p.peek().tp == ":") goto sep;
    return name;
  sep:
    name = name + p.peek().tp;
    p.next();
    goto nextname;
}

Node parseNameList (Parser p, string tp, string sep) {
  Node node = newNode(tp, "");
  repeat:
    node.push(newNode("name", p.getname()));
    if (p.peek().tp == sep) {
      p.next();
      goto repeat;
    }
  return node;
}

Node parseFuncDecl (Parser p) {
  token _tk = p.peek();
  int line = p.line();
  Node outs = newNode("outs", "");
  if (p.maybe("void")) {}
  else {
    nextout:
    outs.push(newNode("type", p.getname()));
    if (p.maybe(",")) goto nextout;
  }

  string name = parseLongName(p);

  if (p.maybe("(")) {
    Node ins = newNode("ins", "");
    if (p.peek().tp == ")") goto endin;
    nextin:
      Node inNode = newNode("arg", "");
      inNode.push(newNode("type", p.getname()));
      string argname = "";
      if (p.peek().tp == "name")
        argname = p.getname();
      inNode.push(newNode("name", argname));
      ins.push(inNode);
      if (p.peek().tp == ",") {
        p.next();
        goto nextin;
      }
    endin:
    check(p.next(), ")");

    string alias = "";
    if (p.maybe("as")) alias = p.getname();

    Node node = newNode("function", name).inline(line);
    node.push(ins);
    node.push(outs);
    node.push(newNode("alias", alias));
    return node;
  } else if (outs.len() == 1) {
    if (p.maybe(";")) {
      Node tpnode = newNode("type", outs.child(0).val);
      Node declnode = newNode("decl", name);
      declnode.line = line;
      declnode.push(tpnode);
      return declnode;
    }
  }
  check(p.peek(), "("); // If it gets here, always fail
}


Node parseImport (Parser p) {
  // import keyword already consumed

  string name = parseLongName(p);
  Node result = newNode("import", name);

  Node arglist = newNode("arglist", "");
  if (p.peek().tp == "(") {
    p.next();
    arglist = parseNameList(p, "arglist", ",");
    check(p.next(), ")");
  }
  result.push(arglist);

  check(p.next(), "{");

  nextitem:
    int line = p.line();
    if (p.maybe("}")) goto end;
    else if (p.maybe("type")) {
      Node typenode = newNode("type", parseLongName(p));

      string alias = "";
      if (p.maybe("as")) alias = p.getname();
      typenode.push(newNode("alias", alias));

      if (p.maybe("{")) {
        nextmember:
        Node item = parseFuncDecl(p);
        if (item.tp == "function")
          check(p.next(), ";");
        typenode.push(item);
        if (p.maybe("}")) {}
        else goto nextmember;
      } else check(p.next(), ";");

      result.push(typenode.inline(line));
    } else {
      Node item = parseFuncDecl(p);
      if (item.tp == "function")
        check(p.next(), ";");
      result.push(item);
    }
    goto nextitem;
  end:

  return result;
}

Node parseAssignment (Parser p, Node first) {
  Node left = newNode("exprlist", "");
  left.push(first);

  nextleft:
    if (p.maybe(",")) {} else goto endleft;
    left.push(parseExpr(p));
    goto nextleft;
  endleft:
  check(p.next(), "=");

  Node expr = parseExpr(p);
  check(p.next(), ";");

  Node node = newNode("assignment", "");
  node.push(left);
  node.push(expr);
  return node;
}

Node parseDecl (Parser p) {
  Node node = newNode("decl", p.getname());

  nextpart:
    Node partnode = newNode("declpart", p.getname());
    if (p.maybe("=")) partnode.push(parseExpr(p));
    node.push(partnode);
    if (p.maybe(",")) goto nextpart;
  check(p.next(), ";");

  return node;
}

Node parseStmt (Parser p) {
  int line = p.line();
  token _tk = p.peek();
  if (p.peek().tp == "{") return parseBlock(p);
  if (p.maybe("goto")) {
    Node node = newNode("goto", p.getname());
    check(p.next(), ";");
    return node.inline(line);
  }
  if (p.maybe("return")) {
    Node node = newNode("return", "");
    node.push(parseExprList(p, ";"));
    return node.inline(line);
  }
  if (p.maybe("if")) {
    Node node = newNode("if", "");
    check(p.next(), "(");
    node.push(parseExpr(p));
    check(p.next(), ")");
    node.push(parseStmt(p));
    if (p.maybe("else"))
      node.push(parseStmt(p));
    return node.inline(line);
  }
  if (p.maybe("while")) {
    Node node = newNode("while", "");
    check(p.next(), "(");
    node.push(parseExpr(p));
    check(p.next(), ")");
    node.push(parseStmt(p));
    return node.inline(line);
  }
  if (p.peek().tp == "name") {
    string ty = p.peekat(1).tp;
    if (ty == ":") {
      string name = p.getname(); p.next();
      return newNode("label", name).inline(line);
    }
    if (ty == "name") return parseDecl(p).inline(line);
  }
  Node expr = parseExpr(p);
  if (p.peek().tp == "=") return parseAssignment(p, expr).inline(line);
  if (p.peek().tp == ",") return parseAssignment(p, expr).inline(line);
  if (expr.tp == "call") {
    check(p.next(), ";");
    return expr;
  }
  error("invalid statement", _tk);
}

Node parseBlock (Parser p) {
  Node result = newNode("block", "");
  check(p.next(), "{");
  repeat:
  if (p.maybe("}")) return result;
  int line = p.line();
  Node stmt = parseStmt(p).inline(line);
  result.push(stmt);
  goto repeat;
}

Node parseTopLevel (Parser p) {
  token _tk = p.peek();
  if (p.maybe("import"))
    return parseImport(p).inline(_tk.line);
  if (p.maybe("struct")) {
    Node typenode = newNode("struct", parseLongName(p));
    check(p.next(), "{");
    nextmember:
      Node item = parseFuncDecl(p);
      if (item.tp == "function")
        item.push(parseBlock(p));
      typenode.push(item);
      if (p.maybe("}")) {}
      else goto nextmember;
    return typenode.inline(_tk.line);
  }
  if (p.maybe("type")) {
    Node typenode = newNode("type", parseLongName(p));
    check(p.next(), "(");
    Node base = newNode("base", p.getname());
    typenode.push(base);
    check(p.next(), ")");
    check(p.next(), ";");
    return  typenode.inline(_tk.line);
  }
  Node item = parseFuncDecl(p);
  if (item.tp == "function") {
    item.push(parseBlock(p));
    return item;
  }

  error("invalid top level statement", _tk);
}




// =============================== //
//             Interface           //
// =============================== //

Node parse (string src) {
  Node result = newNode("program", "");

  Parser parser = new Parser(tokens(src), 0);

  repeat:
    if (parser.peek().tp == "eof") goto end;
    Node node = parseTopLevel(parser);
    result.push(node);
    goto repeat;
  end:

  return result;
}

void main () {
  string src = readall("test.cu");
  Node program = parse(src);
  program.print("");
}