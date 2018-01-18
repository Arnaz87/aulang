
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
  Node get (NodeArr, int) as NodeArrGet;
}

import cobre.record (int) {
  type `` as Id;
  Id new (int) as newId;
  int get0 (Id) as getId;
  void set0 (Id, int) as setId;
}

import cobre.record (string, Id) {
  type `` as Pair;
  Pair new (string, Id) as _newPair;
  string get0 (Pair) as _getKey;
  Id get1 (Pair) as _getValue;
  void set1 (Pair, Id) as _setValue;
}

import cobre.array (Pair) {
  type array as _Map;
  _Map new (Pair, int) as _new_Map;
  Pair get (_Map, int) as _MapGet;
  void set (_Map, int, Pair) as _MapSet;
}

import cobre.record (_Map, int) {
  type `` as Map;
  Map new (_Map, int) as _newMap;
  _Map get0 (Map) as _get_Map;
  int get1 (Map) as size;
  void set1 (Map, int) as setSize;
}

import parser {
  IntArr, NodeArr parse (string);
}




import cobre.array (string) {
  type array as StrArr;
  StrArr new (string, int) as StrArrNew;
  string get (StrArr, int) as StrArrGet;
  void set (StrArr, int, string) as StrArrSet;
  int len (StrArr) as StrArrLen;
}

import cobre.record (string, StrArr) {
  type `` as Import;
  Import new (string, StrArr) as newImport;
  string get0 (Import) as getImportName;
  StrArr get1 (Import) as getImportParams;
  void set1 (Import, StrArr) as setImportParams;
}

import cobre.array (Import) {
  type array as ImportArr;
  ImportArr new (Import, int) as ImportArrNew;
  Import get (ImportArr, int) as ImportArrGet;
  void set (ImportArr, int, Import) as ImportArrSet;
  int len (ImportArr) as ImportArrLen;
}


import cobre.record (int, string) {
  type `` as Type;
  Type new (int, string) as newType;
  int get0 (Type) as getTypeModule;
  string get1 (Type) as getTypeName;
}

import cobre.array (Type) {
  type array as TypeArr;
  TypeArr new (Type, int) as TypeArrNew;
  Type get (TypeArr, int) as TypeArrGet;
  void set (TypeArr, int, Type) as TypeArrSet;
  int len (TypeArr) as TypeArrLen;
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

/*void getImportTypes (Map map, int module, NodeArr nodes, IntArr items) {

}

void getTypes(Map map, NodeArr nodes, IntArr stmts) {
  int len = IntArrLen(stmts);
  int i = 0;
  while (i < len) {
    Node node = NodeArrGet(nodes, IntArrGet(stmts, i));
    string ty = getType(node);
    if (ty == "import") {

    }
  }
}*/

ImportArr makeImports (NodeArr nodes, IntArr stmts) {
  ImportArr buf = ImportArrNew(newImport("", StrArrNew("", 0)), 100);
  ImportArrSet(buf, 0, newImport("cobre.int", StrArrNew("", 0)));
  ImportArrSet(buf, 1, newImport("cobre.string", StrArrNew("", 0)));
  int count = 2;

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
  TypeArrSet(buf, 0, newType(1, "int"));
  TypeArrSet(buf, 1, newType(2, "string"));
  MapSet(map, "int", newId(0));
  MapSet(map, "string", newId(1));
  int count = 2;

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

void main () {
  NodeArr nodes;
  IntArr stmts;

  string src = readall("../culang/lexer.cu");
  //string src = "";
  stmts, nodes = parse(src);

  Map map = newMap();

  ImportArr imports = makeImports(nodes, stmts);
  TypeArr types = makeTypes(map, nodes, stmts);

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

  /*Map map = newMap();
  MapSet(map, "a", newId(1));
  MapSet(map, "b", newId(5));
  MapSet(map, "a", newId(8));
  MapSet(map, "c", newId(7));

  print(itos(getId(MapGet(map, "a"))));

  printMap(map);*/
}

