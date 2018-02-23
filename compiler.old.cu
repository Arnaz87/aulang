
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
  type `` as IntArr;
  IntArr `new` (int, int) as IntArrNew;
  int get (IntArr, int) as IntArrGet;
  void set (IntArr, int, int) as IntArrSet;
  int len (IntArr) as IntArrLen;
  void push (IntArr, int) as IntArrPush;
}

import cobre.record (string, string, IntArr) {
  type `` as Node;
  Node `new` (string, string, IntArr) as newNode;
  string get0(Node) as getType;
  string get1(Node) as getVal;
  IntArr get2(Node) as getChildren;
}

import cobre.array (Node) {
  type `` as NodeArr;
  Node get (NodeArr, int) as NodeArrGet;
}

import cobre.record (int) {
  type `` as Id;
  Id `new` (int) as newId;
  int get0 (Id) as getId;
  void set0 (Id, int) as setId;
}

import cobre.record (string, Id) {
  type `` as Pair;
  Pair `new` (string, Id) as _newPair;
  string get0 (Pair) as _getKey;
  Id get1 (Pair) as _getValue;
  void set1 (Pair, Id) as _setValue;
}

import cobre.array (Pair) {
  type `` as _Map;
  _Map `new` (Pair, int) as _new_Map;
  Pair get (_Map, int) as _MapGet;
  void set (_Map, int, Pair) as _MapSet;
}

import cobre.record (_Map, int) {
  type `` as Map;
  Map `new` (_Map, int) as _newMap;
  _Map get0 (Map) as _get_Map;
  int get1 (Map) as size;
  void set1 (Map, int) as setSize;
}

import parser {
  IntArr, NodeArr parse (string);
}




import cobre.array (string) {
  type `` as StrArr;
  StrArr `new` (string, int) as StrArrNew;
  string get (StrArr, int) as StrArrGet;
  void set (StrArr, int, string) as StrArrSet;
  int len (StrArr) as StrArrLen;
}

import cobre.record (string, StrArr) {
  type `` as Import;
  Import `new` (string, StrArr) as newImport;
  string get0 (Import) as getImportName;
  StrArr get1 (Import) as getImportParams;
  void set1 (Import, StrArr) as setImportParams;
}

import cobre.array (Import) {
  type `` as ImportArr;
  ImportArr `new` (Import, int) as ImportArrNew;
  Import get (ImportArr, int) as ImportArrGet;
  void set (ImportArr, int, Import) as ImportArrSet;
  int len (ImportArr) as ImportArrLen;
}


import cobre.record (int, string) {
  type `` as Type;
  Type `new` (int, string) as newType;
  int get0 (Type) as getTypeModule;
  string get1 (Type) as getTypeName;
}

import cobre.array (Type) {
  type `` as TypeArr;
  TypeArr `new` (Type, int) as TypeArrNew;
  Type get (TypeArr, int) as TypeArrGet;
  void set (TypeArr, int, Type) as TypeArrSet;
  int len (TypeArr) as TypeArrLen;
}


import cobre.record (int, string, IntArr, IntArr) {
  type `` as Function;
  Function `new` (int, string, IntArr, IntArr) as newFunction;
  int get0 (Function) as getFunctionModule; // -1 not imported
  string get1 (Function) as getFunctionName;
  IntArr get2 (Function) as getReturns;
  IntArr get3 (Function) as getArguments;
}

import cobre.array (Function) {
  type `` as FuncArr;
  FuncArr `new` (Function, int) as FuncArrNew;
  Function get (FuncArr, int) as FuncArrGet;
  void set (FuncArr, int, Function) as FuncArrSet;
  int len (FuncArr) as FuncArrLen;
  void push (FuncArr, Function) as FuncArrPush;
}


import cobre.record (string, int, int, string, IntArr) {
  type `` as Inst;
  Inst `new` (string, int, int, string, IntArr) as newInst;
  string get0 (Inst) as getInstName; // -1 not imported
  int get1 (Inst) as getA;
  int get2 (Inst) as getB;
  string get3 (Inst) as getLbl;
  IntArr get4 (Inst) as getArgs;
}

import cobre.array (Inst) {
  type `` as InstArr;
  InstArr `new` (Inst, int) as InstArrNew;
  Inst get (InstArr, int) as InstArrGet;
  void set (InstArr, int, Inst) as InstArrSet;
  int len (InstArr) as InstArrLen;
  void push (InstArr, Inst) as InstArrPush;
}

import cobre.array (InstArr) {
  type `` as CodeArr;
  CodeArr `new` (InstArr, int) as CodeArrNew;
  InstArr get (CodeArr, int) as CodeArrGet;
  void set (CodeArr, int, InstArr) as CodeArrSet;
  void push (CodeArr, InstArr) as CodeArrPush;
}


// =============================== //
//               Maps              //
// =============================== //

Map newMap () {
  Pair pair = _newPair("", newId(0));
  _Map _map = _new_Map(pair, 500);
  Map map = _newMap(_map, 0);
  return map;
}

Id MapGet (Map map, string key) {
  _Map _map = _get_Map(map);
  int i = size(map);
  // Look from the last inserted pair to the first
  while (i > 0) {
    i = i-1;
    Pair pair = _MapGet(_map, i);
    string _key = _getKey(pair);
    if (_key == key) return _getValue(pair);
  }
  print(key + " not found in map");
  quit(1);
}

void MapSet (Map map, string key, Id value) {
  _Map _map = _get_Map(map);
  int len = size(map);
  _MapSet(_map, len, _newPair(key, value));
  setSize(map, len+1);
}

void printMap (Map map) {
  _Map _map = _get_Map(map);
  int len = size(map);
  int i = 0;
  while (i < len) {
    Pair pair = _MapGet(_map, i);
    int id = getId(_getValue(pair));
    print(_getKey(pair) + ": " + itos(id));
    i = i+1;
  }
}

Node getChild (NodeArr nodes, Node node, int index) {
  IntArr childrenIds = getChildren(node);
  int childId = IntArrGet(childrenIds, index);
  return NodeArrGet(nodes, childId);
}

int childCount (Node node) {
  IntArr children = getChildren(node);
  return IntArrLen(children);
}



ImportArr makeImports (NodeArr nodes, IntArr stmts) {
  ImportArr buf = ImportArrNew(newImport("", StrArrNew("", 0)), 100);
  ImportArrSet(buf, 0, newImport("cobre.core", StrArrNew("", 0)));
  ImportArrSet(buf, 1, newImport("cobre.int", StrArrNew("", 0)));
  ImportArrSet(buf, 2, newImport("cobre.string", StrArrNew("", 0)));
  int count = 3;

  int len = IntArrLen(stmts);
  int i = 0;
  while (i < len) {
    Node node = NodeArrGet(nodes, IntArrGet(stmts, i));
    string ty = getType(node);
    if (ty == "import") {
      IntArr children = getChildren(node);

      Node namesNode = NodeArrGet(nodes, IntArrGet(children, 0));
      IntArr nameIds = getChildren(namesNode);

      string name = getVal(NodeArrGet(nodes, IntArrGet(nameIds, 0)));
      int j = 1;
      while (j < IntArrLen(nameIds)) {
        Node nameNode = NodeArrGet(nodes, IntArrGet(nameIds, j));
        name = name + "." + getVal(nameNode);
        j = j+1;
      }

      Node paramsNode = NodeArrGet(nodes, IntArrGet(children, 1));
      IntArr paramIds = getChildren(paramsNode);
      int paramslen = IntArrLen(paramIds);
      StrArr params = StrArrNew("", paramslen);
      int j = 0;
      while (j < paramslen) {
        Node paramNode = NodeArrGet(nodes, IntArrGet(paramIds, j));
        StrArrSet(params, j, getVal(paramNode));
        j = j+1;
      }

      ImportArrSet(buf, count, newImport(name, params));
      count = count+1;
    }
    i = i+1;
  }

  ImportArr result = ImportArrNew(newImport("", StrArrNew("", 0)), count);
  int i = 0;
  while (i < count) {
    ImportArrSet(result, i, ImportArrGet(buf, i));
    i = i+1;
  }

  return result;
}

TypeArr makeTypes (Map map, NodeArr nodes, IntArr stmts) {
  TypeArr buf = TypeArrNew(newType(0, ""), 100);
  TypeArrSet(buf, 0, newType(1, "bool"));
  TypeArrSet(buf, 1, newType(2, "int"));
  TypeArrSet(buf, 2, newType(3, "string"));
  TypeArrSet(buf, 3, newType(3, "char"));
  MapSet(map, "bool", newId(0));
  MapSet(map, "int", newId(1));
  MapSet(map, "string", newId(2));
  MapSet(map, "char", newId(3));
  int count = 4;

  // first is the argument and the other two are int and string
  int modindex = 3;

  int len = IntArrLen(stmts);
  int i = 0;
  while (i < len) {
    Node node = NodeArrGet(nodes, IntArrGet(stmts, i));
    string ty = getType(node);
    if (getType(node) == "import") {
      IntArr children = getChildren(node);
      Node itemsNode = NodeArrGet(nodes, IntArrGet(children, 2));
      IntArr itemIds = getChildren(itemsNode);

      int j = 0;
      while (j < IntArrLen(itemIds)) {
        Node itemNode = NodeArrGet(nodes, IntArrGet(itemIds, j));
        if (getType(itemNode) == "type") {
          string name = getVal(itemNode);
          Node aliasNode = NodeArrGet(nodes, IntArrGet(getChildren(itemNode), 0));
          string alias = getVal(aliasNode);

          TypeArrSet(buf, count, newType(modindex, name));
          MapSet(map, alias, newId(count));
          count = count+1;
        }
        j = j+1;
      }
      modindex = modindex+1;
    }
    i = i+1;
  }

  TypeArr result = TypeArrNew(newType(0, ""), count);
  int i = 0;
  while (i < count) {
    TypeArrSet(result, i, TypeArrGet(buf, i));
    i = i+1;
  }

  return result;
}

FuncArr makeFunctions (Map map, NodeArr nodes, IntArr stmts) {
  FuncArr result = FuncArrNew(newFunction(0, "", IntArrNew(0,0), IntArrNew(0,0)), 0);

  // first is the argument and the others are core, int and string
  int modindex = 4;

  int i = 0;
  while (i < IntArrLen(stmts)) {
    Node node = NodeArrGet(nodes, IntArrGet(stmts, i));
    string ty = getType(node);
    if (getType(node) == "import") {
      Node itemsNode = getChild(nodes, node, 2);

      int j = 0;
      while (j < childCount(itemsNode)) {
        Node itemNode = getChild(nodes, itemsNode, j);
        if (getType(itemNode) == "function") {
          string name = getVal(itemNode);
          string alias = getVal(getChild(nodes, itemNode, 2));
          Node typesNode = getChild(nodes, itemNode, 0);
          Node argsNode  = getChild(nodes, itemNode, 1);

          IntArr types = IntArrNew(0, 0);

          int k = 0;
          while (k < childCount(typesNode)) {
            Node nd = getChild(nodes, typesNode, k);
            int id = getId(MapGet(map, getVal(nd)));
            IntArrPush(types, id);
            k = k+1;
          }

          IntArr args = IntArrNew(0, 0);
          int k = 0;
          while (k < childCount(argsNode)) {
            Node argpart = getChild(nodes, argsNode, k);
            // argpart[0] is the type and argpart[1] is the argument name
            Node nd = getChild(nodes, argpart, 0);
            int id = getId(MapGet(map, getVal(nd)));
            IntArrPush(args, id);
            k = k+1;
          }

          MapSet(map, alias, newId(FuncArrLen(result)));

          Function fn = newFunction(modindex, name, types, args);
          FuncArrPush(result, fn);
        }
        j = j+1;
      }
      modindex = modindex+1;
    }

    if (getType(node) == "function") {
          string name = getVal(node);
          Node typesNode = getChild(nodes, node, 0);
          Node argsNode  = getChild(nodes, node, 1);

          IntArr types = IntArrNew(0, 0);

          int k = 0;
          while (k < childCount(typesNode)) {
            Node nd = getChild(nodes, typesNode, k);
            int id = getId(MapGet(map, getVal(nd)));
            IntArrPush(types, id);
            k = k+1;
          }

          IntArr args = IntArrNew(0, 0);
          int k = 0;
          while (k < childCount(argsNode)) {
            Node argpart = getChild(nodes, argsNode, k);
            // argpart[0] is the type and argpart[1] is the argument name
            Node nd = getChild(nodes, argpart, 0);
            int id = getId(MapGet(map, getVal(nd)));
            IntArrPush(args, id);
            k = k+1;
          }

          MapSet(map, name, newId(FuncArrLen(result)));

          Function fn = newFunction(0-1, name, types, args);
          FuncArrPush(result, fn);
    }
    i = i+1;
  }

  return result;
}

CodeArr makeBodies (Map map, NodeArr nodes, IntArr stmts) {
  CodeArr result;
  { // Create empty CodeArr
    IntArr args = IntArrNew(0, 0);
    Inst inst = newInst("", 0, 0, "", args);
    InstArr code = InstArrNew(inst, 0);
    result = CodeArrNew(code, 0);
  }
  return result;
}


void main () {
  NodeArr nodes;
  IntArr stmts;

  string src = readall("../culang/lexer.cu");
  //string src = "";
  stmts, nodes = parse(src);

  Map map = newMap();

  ImportArr imports = makeImports(nodes, stmts);
  TypeArr types = makeTypes(map, nodes, stmts);
  FuncArr funcs = makeFunctions(map, nodes, stmts);
  //CodeArr codes = makeBodies(map, nodes, stmts);

  int i = 0;
  while (i < ImportArrLen(imports)) {
    Import imp = ImportArrGet(imports, i);
    string paramstr = "";
    StrArr params = getImportParams(imp);
    int j = 0;
    while (j < StrArrLen(params)) {
      string param = StrArrGet(params, j);
      string id = getId(MapGet(map, param));
      paramstr = paramstr + " " + param + "["+ itos(id) +"]";
      j = j+1;
    }
    print("import[" + itos(i+1) + "] " + getImportName(imp) + " (" + paramstr + " )");
    i = i+1;
  }

  int i = 0;
  while (i < TypeArrLen(types)) {
    Type tp = TypeArrGet(types, i);
    print("type[" + itos(i) + "] " + getTypeName(tp) + " from " + itos(getTypeModule(tp)));
    i = i+1;
  }


  int i = 0;
  while (i < FuncArrLen(funcs)) {
    Function fn = FuncArrGet(funcs, i);
    string types = "";
    int j = 0;
    while (j < IntArrLen(getReturns(fn))) {
      int id = IntArrGet(getReturns(fn), j);
      types = types + "#" + itos(id) + " ";
      j = j+1;
    }

    string args = "";
    int j = 0;
    while (j < IntArrLen(getArguments(fn))) {
      int id = IntArrGet(getArguments(fn), j);
      args = args + "#" + itos(id) + " ";
      j = j+1;
    }

    string mod;
    int modindex = getFunctionModule(fn);
    if (modindex < 0) {
      mod = "internal";
    } else {
      mod = "from " + itos(modindex);
    }

    string name = getFunctionName(fn);
    print("function[" + itos(i) + "] " + types + name + "( " + args + ") " + mod);
    i = i+1;
  }

  printMap(map);
}

