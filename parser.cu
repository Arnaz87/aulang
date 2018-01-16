
// =============================== //
//              Imports            //
// =============================== //

import cobre.system {
  void print (string);
  void quit (int);
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
//              Parsers            //
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
  assert(TkType(next(parser)) == "(", "Expected opening paren for function args");

  tk = next(parser);

  int argsId;
  if (TkType(tk) == ")") {
    Node namesNode = newNode("arglist", "", IntArrNew(0, 0));
    argsId = putNode(parser, namesNode);
  } else if (TkType(tk) == "name") {
    string msg = "Expected function argument";
    argsId = parseNameList(parser, TkVal(tk), ",", "arglist", msg);
    tk = next(parser);
  }

  assert(TkType(tk) == ")", "Expected closing paren for function args");

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
    print("No arguments: " + TkType(tk) + " " + TkVal(tk));
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

int parseStmt (Parser parser) {
  print("Statement expected");
  quit(1);
  return 0;
}

int parseStmtList (Parser parser) {
  assert(TkType(next(parser)) == "{", "Expected { for function body");

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
  IntArr children = IntArrNew(0,0);

  Node node = newNode("stmtlist", "", children);
  return putNode(parser, node);
}

int parseProgram (Parser parser) {
  Token tk = next(parser);

  if (TkType(tk) == "import") { return parseImport(parser); }
  else {
    int typesId, argsId;
    string name, alias;

    typesId, name, argsId = parseFuncSig(parser, tk, "Invalid toplevel statement");

    int bodyId = parseStmtList(parser);

    IntArr children = IntArrNew(0, 3);
    IntArrSet(children, 0, typesId);
    IntArrSet(children, 1, argsId);
    IntArrSet(children, 2, bodyId);

    Node node = newNode("function", name, children);
    return putNode(parser, node);
  }
}

void printNode (Parser parser, int pos, string indent) {
  Node node = getNode(parser, pos);
  print(indent + getType(node) + " " + getVal(node));
  IntArr children = getChildren(node);
  int len = IntArrLen(children);
  int i = 0;
  while (i < len) {
    int id = IntArrGet(children, i);
    printNode(parser, id, indent + "  ");
    i = i+1;
  }
}

void main () {
  TkArr tks = tokens("void main () {}");

  Parser parser = ParserNew(tks);

  int nodeid = parseProgram(parser);
  printNode(parser, nodeid, "");
}