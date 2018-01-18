
// =============================== //
//              Imports            //
// =============================== //

import cobre.system {
  void print (string);
  void quit (int);
  string readall (string);
}

import cobre.string {
  string itos (int);
}

import cobre.array (int) {
  type array as IntArr;
  IntArr new (int, int) as IntArrNew;
  int get (IntArr, int) as IntArrGet;
  void set (IntArr, int, int) as IntArrSet;
  int len (IntArr) as IntArrLen;
}

import cobre.record (string, string, IntArr) {
  type `` as Node;
  Node new (string, string, IntArr) as newNode;
  string get0(Node) as getType;
  string get1(Node) as getVal;
  IntArr get2(Node) as getChildren;
}

import cobre.array (Node) {
  type array as NodeArr;
  NodeArr new (Node, int) as NodeArrNew;
  Node get (NodeArr, int) as NodeArrGet;
  void set (NodeArr, int, Node) as NodeArrSet;
}

import cobre.record(string, string) {
  type `` as Token;
  string get0(Token) as TkType;
  string get1(Token) as TkVal;
}

import cobre.array(Token) {
  type array as TkArr;
  Token get (TkArr, int) as TkArrGet;
  int len (TkArr) as TkArrLen;
}

import cobre.record (NodeArr, int, TkArr, int) {
  type `` as Parser;
  Parser new (NodeArr, int, TkArr, int) as _ParserNew;

  NodeArr get0 (Parser) as _ndArr;
  int get1 (Parser) as _size;

  TkArr get2 (Parser) as _tkArr;
  int get3 (Parser) as _tkPos;

  void set1 (Parser, int) as _setSize;
  void set3 (Parser, int) as _setTkPos;
}

import lexer {
  TkArr tokens (string);
}

import cobre.array(string) {
  type array as StrArr;
  StrArr new (string, int) as StrArrNew;
  string get (StrArr, int) as StrArrGet;
  void set (StrArr, int, string) as StrArrSet;
}




// =============================== //
//              Methods            //
// =============================== //

Parser ParserNew (TkArr tkarr) {
  IntArr iarr = IntArrNew(0, 0);
  NodeArr ndarr = NodeArrNew(newNode("", "", iarr), 5000);
  return _ParserNew(ndarr, 0, tkarr, 0);
}

Node getNode (Parser parser, int pos) {
  NodeArr arr = _ndArr(parser);
  Node node = NodeArrGet(arr, pos);
  return node;
}

int putNode (Parser parser, Node node) {
  NodeArr arr = _ndArr(parser);
  int pos = _size(parser);
  NodeArrSet(arr, pos, node);
  _setSize(parser, pos+1);
  return pos;
}

Token peek (Parser parser) {
  int pos = _tkPos(parser);
  TkArr arr = _tkArr(parser);
  return TkArrGet(arr, pos);
}

Token next (Parser parser) {
  int pos = _tkPos(parser);
  int tk = peek(parser);
  _setTkPos(parser, pos+1);
  return tk;
}

void assert (bool arg, string msg) {
  if (arg) {} else {
    print("Asert failed: " + msg);
    quit(1);
  }
}




// =============================== //
//            Expressions          //
// =============================== //

Node parseCall (Parser parser, int base) {
  next(parser); // Skip (
  int explist = parseMaybeExprList(parser, ")");
  assert(TkType(next(parser)) == ")", "Expected ) for function call");
  IntArr children = IntArrNew(0, 2);
  IntArrSet(children, 0, base);
  IntArrSet(children, 1, explist);
  return newNode("call", "", children);
}

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
  if (ty == "=") return 0<1;
  if (ty == ">") return 0<1;
  if (ty == "<=") return 0<1;
  if (ty == "==") return 0<1;
  if (ty == ">=") return 0<1;
  if (ty == "!=") return 0<1;
  return 0<0;
}

int parseBaseExpr (Parser parser) {
  Token tk = next(parser);
  string ty = TkType(tk);
  IntArr iarr = IntArrNew(0, 0);
  Node node;
  if (ty == "(") {
    int nodeId = parseExpr(parser);
    assert(TkType(next(parser)) == ")", "closing ) expected for expression");
    return nodeId;
  } else if (isUnop(ty)) {
    string op = ty;
    int base = parseBaseExpr(parser);
    IntArr children = IntArrNew(base, 1);
    node = newNode("unop", op, children);
  } else if (ty == "num") {
    node = newNode("num", TkVal(tk), iarr);
  } else if (ty == "str") {
    node = newNode("str", TkVal(tk), iarr);
  } else if (ty == "true") {
    node = newNode("true", "", iarr);
  } else if (ty == "false") {
    node = newNode("true", "", iarr);
  } else if (ty == "name") {
    node = newNode("name", TkVal(tk), iarr);
    if (TkType(peek(parser)) == "(") {
      node = parseCall(parser, putNode(parser, node));
    }
  } else {
    print("Invalid expression");
    quit(1);
  }
  return putNode(parser, node);
}

int parseExpr (Parser parser) {
  int left = parseBaseExpr(parser);
  while (isBinop(TkType(peek(parser)))) {
    string op = TkType(next(parser));
    int right = parseBaseExpr(parser);
    IntArr children = IntArrNew(0, 2);
    IntArrSet(children, 0, left);
    IntArrSet(children, 1, right);
    Node node = newNode("binop", op, children);
    left = putNode(parser, node);
  }
  return left;
}

int parseExprList (Parser parser) {
  IntArr explist = IntArrNew(0, 30);
  IntArrSet(explist, 0, parseExpr(parser));
  int count = 1;

  while (TkType(peek(parser)) == ",") {
    next(parser); // Skip ,
    IntArrSet(explist, count, parseExpr(parser));
    count = count+1;
  }

  IntArr children = IntArrNew(0, count);
  int i = 0;
  while (i < count) {
    IntArrSet(children, i, IntArrGet(explist, i));
    i = i+1;
  }

  Node node = newNode("exprlist", "", children);
  return putNode(parser, node);
}

int parseMaybeExprList (Parser parser, string end) {
  if (TkType(peek(parser)) == end) {
    Node node = newNode("exprlist", "", IntArrNew(0,0));
    return putNode(parser, node);
  } else return parseExprList(parser);
}




// =============================== //
//            Statements           //
// =============================== //

int parseNameList (Parser parser, string first, string sep, string nodename, string msg) {
  StrArr names = StrArrNew("", 10);
  StrArrSet(names, 0, first);
  int namelen = 1;

  Token tk = peek(parser);
  while (TkType(tk) == sep) {
    next(parser); // Skip sep
    tk = next(parser); // Actual name token
    assert(TkType(tk) == "name", msg);
    StrArrSet(names, namelen, TkVal(tk));
    namelen = namelen+1;
  }

  IntArr nameIds = IntArrNew(0, namelen);
  int i = 0;
  while (i < namelen) {
    Node nameNode = newNode("name", StrArrGet(names, i), IntArrNew(0,0));
    int id = putNode(parser, nameNode);
    IntArrSet(nameIds, i, id);
    i = i+1;
  }

  Node namesNode = newNode(nodename, "", nameIds);
  return putNode(parser, namesNode);
}

int, string, int parseFuncSig (Parser parser, Token first, string errmsg) {
  Token tk = first;

  // ----------------- Return types
  int typesId;
  if (TkType(tk) == "void") {
    Node namesNode = newNode("typelist", "", IntArrNew(0, 0));
    typesId = putNode(parser, namesNode);
  } else if (TkType(tk) == "name") {
    string msg = "Expected function return type";
    typesId = parseNameList(parser, TkVal(tk), ",", "typelist", msg);
  } else {
    print(errmsg);
    quit(1);
  }

  // ----------------- Function Name
  tk = next(parser);
  assert(TkType(tk) == "name", "Expected function name");
  string name = TkVal(tk);

  // ----------------- Arguments
  assert(TkType(next(parser)) == "(", "( expected in function args");

  tk = peek(parser);

  int argsId;
  if (TkType(tk) == ")") {
    next(parser); // Skip )
    Node namesNode = newNode("arglist", "", IntArrNew(0, 0));
    argsId = putNode(parser, namesNode);
  } else if (TkType(tk) == "name") {

    IntArr buf = IntArrNew(0, 30);
    int count = 0;

    repeat:
      tk = next(parser);
      assert(TkType(tk) == "name", "Expected function argument type");
      string ty = TkVal(tk);
      tk = next(parser);
      string name = "";
      if (TkType(tk) == "name") {
        name = TkVal(tk);
        tk = next(parser);
      }

      Node tynode = newNode("type", ty, IntArrNew(0,0));
      Node namenode = newNode("name", name, IntArrNew(0,0));

      IntArr children = IntArrNew(0, 2);
      IntArrSet(children, 0, putNode(parser, tynode));
      IntArrSet(children, 1, putNode(parser, namenode));

      Node node = newNode("argpart", "", children);
      IntArrSet(buf, count, putNode(parser, node));
      count = count+1;

      if (TkType(tk) == ",") goto repeat;
    end:
    assert(TkType(tk) == ")", ") expected in function args");

    IntArr children = IntArrNew(0, count);
    int i = 0;
    while (i < count) {
      IntArrSet(children, i, IntArrGet(buf, i));
      i = i+1;
    }

    Node node = newNode("arglist", "", children);
    argsId = putNode(parser, node);
  }

  return typesId, name, argsId;
}

int parseImportItems (Parser parser) {
  assert(TkType(next(parser)) == "{", "Expected opening bracket for import items");
  IntArr items = IntArrNew(0, 50);
  int itemlen = 0;

  Node node;
  Token tk = next(parser);

  repeat:
    if (TkType(tk) == "}") {
      goto end;
    }
    // ------------ Type Item
    else if (TkType(tk) == "type") {
      tk = next(parser);
      assert(TkType(tk) == "name", "Expected type name");
      string name = TkVal(tk);
      string alias = name;
      tk = next(parser);
      if (TkType(tk) == "as") {
        tk = next(parser);
        assert(TkType(tk) == "name", "Expected type alias");
        alias = TkVal(tk);
        tk = next(parser);
      }
      assert(TkType(tk) == ";", "Expected ; after imported type");

      Node aliasNode = newNode("alias", alias, IntArrNew(0,0));
      int aliasId = putNode(parser, aliasNode);

      IntArr children = IntArrNew(0, 1);
      IntArrSet(children, 0, aliasId);

      node = newNode("type", name, children);

    // --------------- Function Item
    } else {
      int typesId, argsId;
      string name, alias;

      typesId, name, argsId = parseFuncSig(parser, tk, "Invalid import item");

      // ----------------- Alias
      tk = next(parser);
      if (TkType(tk) == "as") {
        tk = next(parser);
        assert(TkType(tk) == "name", "Expected type alias");
        alias = TkVal(tk);
        tk = next(parser);
      } else {
        alias = name;
      }
      assert(TkType(tk) == ";", "Expected ; after imported function");

      Node aliasNode = newNode("alias", alias, IntArrNew(0,0));
      int aliasId = putNode(parser, aliasNode);

      IntArr children = IntArrNew(0, 3);
      IntArrSet(children, 0, typesId);
      IntArrSet(children, 1, argsId);
      IntArrSet(children, 2, aliasId);

      node = newNode("function", name, children);
    }

    int nodeId = putNode(parser, node);
    IntArrSet(items, itemlen, nodeId);
    itemlen = itemlen + 1;
    tk = next(parser);
    goto repeat;
  end:

  IntArr children = IntArrNew(0, itemlen);
  int i = 0;
  while (i < itemlen) {
    IntArrSet(children, i, IntArrGet(items, i));
    i = i+1;
  }

  node = newNode("items", "", children);
  return putNode(parser, node);
}

int parseImport (Parser parser) {
  // import keyword already consumed
  Token tk;

  // ----------- Names
  int namesNodeId;
  {
    StrArr names = StrArrNew("", 10);
    tk = next(parser);
    assert(TkType(tk) == "name", "Expected first import name");
    StrArrSet(names, 0, TkVal(tk));
    int namelen = 1;

    tk = peek(parser);
    while (TkType(tk) == ".") {
      next(parser); // Skip point
      tk = next(parser); // Actual name
      assert(TkType(tk) == "name", "Expected an import name part");
      StrArrSet(names, namelen, TkVal(tk));
      namelen = namelen+1;
    }

    IntArr nameIds = IntArrNew(0, namelen);
    int i = 0;
    while (i < namelen) {
      Node nameNode = newNode("name", StrArrGet(names, i), IntArrNew(0,0));
      int id = putNode(parser, nameNode);
      IntArrSet(nameIds, i, id);
      i = i+1;
    }

    Node namesNode = newNode("namelist", "", nameIds);
    namesNodeId = putNode(parser, namesNode);
  }

  // ------------ Arguments

  int argsNodeId;
  tk = peek(parser);
  if (TkType(tk) == "(") {
    next(parser); // Skip paren
    StrArr names = StrArrNew("", 10);
    tk = next(parser);
    assert(TkType(tk) == "name", "At least one module argument required inside parens");
    StrArrSet(names, 0, TkVal(tk));
    int namelen = 1;

    tk = next(parser);
    while (TkType(tk) == ",") {
      tk = next(parser);
      assert(TkType(tk) == "name", "Not a valid import argument");
      StrArrSet(names, namelen, TkVal(tk));
      namelen = namelen+1;
      tk = next(parser);
    }

    assert(TkType(tk) == ")", "Expected closing paren after import args");

    IntArr nameIds = IntArrNew(0, namelen);
    int i = 0;
    while (i < namelen) {
      Node nameNode = newNode("name", StrArrGet(names, i), IntArrNew(0,0));
      int id = putNode(parser, nameNode);
      IntArrSet(nameIds, i, id);
      i = i+1;
    }

    Node argsNode = newNode("arglist", "", nameIds);
    argsNodeId = putNode(parser, argsNode);
  } else {
    Node argsNode = newNode("arglist", "", IntArrNew(0,0));
    argsNodeId = putNode(parser, argsNode);
  }

  int items = parseImportItems(parser);

  IntArr children = IntArrNew(0, 3);
  IntArrSet(children, 0, namesNodeId);
  IntArrSet(children, 1, argsNodeId);
  IntArrSet(children, 2, items);

  Node node = newNode("import", "", children);
  int id = putNode(parser, node);
  return id;
}

Node parseAssignment (Parser parser, string first) {
  int nameList = parseNameList(parser, first, ",", "namelist", "Expected variable name");
  assert(TkType(next(parser)) == "=", "= expected");
  int expr = parseExpr(parser);

  IntArr children = IntArrNew(0, 2);
  IntArrSet(children, 0, nameList);
  IntArrSet(children, 1, expr);

  return newNode("assignment", "", children);
}

int parseDecl (Parser parser, string typename) {
  IntArr buf = IntArrNew(0, 30);
  int count = 0;

  repeat:
    Token tk = next(parser);
    assert(TkType(tk) == "name", "variable name expected");
    string name = TkVal(tk);
    tk = next(parser);
    int exp;
    if (TkType(tk) == "=") {
      exp = parseExpr(parser);
      tk = next(parser);
    } else {
      exp = putNode(parser, newNode("none", "", IntArrNew(0,0)));
    }
    IntArr children = IntArrNew(exp, 1);
    Node node = newNode("declpart", name, children);

    IntArrSet(buf, count, putNode(parser, node));
    count = count+1;

    if (TkType(tk) == ",") goto repeat;
  end:
  assert(TkType(tk) == ";", "; expected");

  IntArr children = IntArrNew(0, count);
  int i = 0;
  while (i < count) {
    IntArrSet(children, i, IntArrGet(buf, i));
    i = i+1;
  }

  Node node = newNode("decl", typename, children);
  return putNode(parser, node);
}

int parseBlock (Parser parser) {
  IntArr buf = IntArrNew(0, 500);
  int count = 0;

  repeat:
    if (TkType(peek(parser)) == "}") goto end;
    int stmt = parseStmt(parser);
    IntArrSet(buf, count, stmt);
    count = count+1;
    goto repeat;
  end:
  next(parser); // Skip }

  IntArr children = IntArrNew(0, count);
  int i = 0;
  while (i < count) {
    IntArrSet(children, i, IntArrGet(buf, i));
    i = i+1;
  }

  Node node = newNode("block", "", children);
  return putNode(parser, node);
}

int parseIf (Parser parser) {
  assert(TkType(next(parser)) == "(", "( expected in if condition");
  int cond = parseExpr(parser);
  assert(TkType(next(parser)) == ")", ") expected in if condition");
  int stmt = parseStmt(parser);

  int els;
  if (TkType(peek(parser)) == "else") {
    next(parser);
    els = parseStmt(parser);
  } else {
    els = putNode(parser, newNode("block", "", IntArrNew(0,0)));
  }

  IntArr children = IntArrNew(0, 3);
  IntArrSet(children, 0, cond);
  IntArrSet(children, 1, stmt);
  IntArrSet(children, 2, els);

  Node node = newNode("if", "", children);
  return putNode(parser, node);
}

int parseWhile (Parser parser) {
  assert(TkType(next(parser)) == "(", "( expected in while condition");
  int cond = parseExpr(parser);
  assert(TkType(next(parser)) == ")", ") expected in while condition");
  int stmt = parseStmt(parser);

  IntArr children = IntArrNew(0, 2);
  IntArrSet(children, 0, cond);
  IntArrSet(children, 1, stmt);

  Node node = newNode("while", "", children);
  return putNode(parser, node);
}

int parseStmt (Parser parser) {
  Token tk = next(parser);
  string ty = TkType(tk);

  Node result;

  if (ty == "{") {
    return parseBlock(parser);
  } else if (ty == "goto") {
    tk = next(parser);
    assert(TkType(tk) == "name", "Expected label name");
    result = newNode("goto", TkVal(tk), IntArrNew(0, 0));
  } else if (ty == "return") {
    int exprlist = parseMaybeExprList(parser, ";");
    IntArr children = IntArrNew(exprlist, 1);
    result = newNode("return", "", children);
  } else if (ty == "if") {
    return parseIf(parser);
  } else if (ty == "while") {
    return parseWhile(parser);
  } else if (ty == "name") {
    string first = TkVal(tk);
    ty = TkType(peek(parser));
    if (ty == ":") {
      next(parser); // skip :
      Node node = newNode("label", first, IntArrNew(0, 0));
      return putNode(parser, node);
    }
    else if (ty == "=") result = parseAssignment(parser, first);
    else if (ty == ",") result = parseAssignment(parser, first);
    else if (ty == "name") return parseDecl(parser, first);
    else if (ty == "(") {
      result = newNode("name", first,IntArrNew(0,0));
      result = parseCall(parser, putNode(parser, result));
    }
    else {
      print("Statement Expected");
      quit(1);
    }
  } else {
    print("Statement Expected");
    quit(1);
  }

  assert(TkType(next(parser)) == ";", "; expected");
  return putNode(parser, result);
}

int parseBlock (Parser parser) {

  IntArr idList = IntArrNew(0, 500);
  int stmtCount = 0;

  repeat:
    if (TkType(peek(parser)) == "}") goto end;

    int statId = parseStmt(parser);
    IntArrSet(idList, stmtCount, statId);
    stmtCount = stmtCount+1;

    goto repeat;
  end:
  next(parser); // Skip }

  IntArr children = IntArrNew(0, stmtCount);
  int i = 0;
  while (i < stmtCount) {
    IntArrSet(children, i, IntArrGet(idList, i));
    i = i+1;
  }

  Node node = newNode("block", "", children);
  return putNode(parser, node);
}

int parseTopLevel (Parser parser) {
  Token tk = next(parser);

  if (TkType(tk) == "import") { return parseImport(parser); }
  else {
    int typesId, argsId;
    string name, alias;

    typesId, name, argsId = parseFuncSig(parser, tk, "Invalid toplevel statement");

    assert(TkType(next(parser)) == "{", "Expected { for function body");

    int bodyId = parseBlock(parser);

    IntArr children = IntArrNew(0, 3);
    IntArrSet(children, 0, typesId);
    IntArrSet(children, 1, argsId);
    IntArrSet(children, 2, bodyId);

    Node node = newNode("function", name, children);
    return putNode(parser, node);
  }
}




// =============================== //
//             Interface           //
// =============================== //

IntArr, NodeArr parse (string src) {

  Parser parser = ParserNew(tokens(src));

  IntArr buf = IntArrNew(0, 300);
  int count = 0;

  repeat:
    if (TkType(peek(parser)) == "eof") goto end;
    int nodeid = parseTopLevel(parser);
    IntArrSet(buf, count, nodeid);
    count = count+1;
    goto repeat;
  end:

  IntArr stmtIds = IntArrNew(0, count);
  int i = 0;
  while (i < count) {
    IntArrSet(stmtIds, i, IntArrGet(buf, i));
    i = i+1;
  }

  int size = _size(parser);
  NodeArr nodes = NodeArrNew(newNode("", "", IntArrNew(0,0)), size);
  int i = 0;
  while (i < size) {
    NodeArrSet(nodes, i, getNode(parser, i));
    i = i+1;
  }

  return stmtIds, nodes;
}

void printNode (NodeArr nodes, int pos, string indent) {
  Node node = NodeArrGet(nodes, pos);
  print(indent + getType(node) + " " + getVal(node));
  IntArr children = getChildren(node);
  int len = IntArrLen(children);
  int i = 0;
  while (i < len) {
    int id = IntArrGet(children, i);
    printNode(nodes, id, indent + "  ");
    i = i+1;
  }
}

void main () {
  NodeArr nodes;
  IntArr stmts;

  string src = readall("../culang/lexer.cu");
  stmts, nodes = parse(src);

  int len = IntArrLen(stmts);
  print(itos(len) + " statements");
  int i = 0;
  while (i < len) {
    int id = IntArrGet(stmts, i);
    printNode(nodes, id, "");
    print("");
    i = i+1;
  }
}