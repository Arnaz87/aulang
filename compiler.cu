
import cobre.system {
  void print (string);
  void quit (int);
  string readall (string);
}

import cobre.string {
  string itos(int);
}

import parser {
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
    print("Error: " + key + " not found in map");
    quit(1);
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

  void print (Map this) {
    int i = 0;
    while (i < this.pos) {
      Pair pair = this.arr[i];
      print(pair.key + ": " + itos(pair.id));
      i = i+1;
    }
  }
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

void printNodeArr (NodeArr arr) {
  int i = 0;
  while (i < arr.len()) {
    print("["+itos(i) + "]:");
    arr[i].print("  ");
  }
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
}

struct Type {
  int module;
  string name;
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

struct Compiler {
  Node tree;
  Map typeMap;
  Map funcMap;
  ModuleArr modules;
  TypeArr types;
  NodeArr functions;
}

void makeBasics (Compiler c) {
  c.modules.push(new Module("system", emptyStrArr()));
  c.modules.push(new Module("int", emptyStrArr()));
  c.modules.push(new Module("string", emptyStrArr()));

  c.types.push(new Type(1, "bool"));
  c.types.push(new Type(2, "int"));
  c.types.push(new Type(3, "string"));

  c.typeMap["bool"] = 0;
  c.typeMap["int"] = 1;
  c.typeMap["string"] = 2;
}

void makeImports (Compiler c) {
  int i = 0;
  while (i < c.tree.len()) {
    Node node = c.tree.child(i);
    if (node.tp == "import") {
      StrArr args = emptyStrArr();
      Node argnd = node.child(0);
      int j = 0;
      while (j < argnd.len()) {
        args.push(argnd.child(j).val);
        j = j+1;
      }
      c.modules.push(new Module(node.val, args));

      int id = c.modules.len();

      int j = 1; // Skip first child, it's the argument node
      while (j < node.len()) {
        Node item = node.child(j);
        if (item.tp == "type") {
          int typeid = c.types.len();
          string alias = item.child(0).val;
          c.types.push(new Type(id, item.val));
          c.typeMap[alias] = typeid;
        }
        j = j+1;
      }
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
    emptyNodeArr()
  );

  makeBasics(c);

  makeImports(c);

  return c;
}


void main () {
  Compiler c = compile("import cobre.lol { void print(string); type foo as fox; type bar as bax {int x;} }");

  print("Type Map:");
  c.typeMap.print();

  print("\nFunction Map:");
  c.funcMap.print();

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
    print("[" + itos(i+1) + "]: " + m.name + args + ")");
    i = i+1;
  }

  print("\nTypes:");
  int i = 0;
  while (i < c.types.len()) {
    Type t = c.types[i];
    print("[" + itos(i) + "]: Module[" + itos(t.module) + "]." + t.name);
    i = i+1;
  }

  print("\nFunctions:");
  printNodeArr(c.functions);
}