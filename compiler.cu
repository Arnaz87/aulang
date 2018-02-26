
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
    print("Error: \"" + key + "\" not found in map");
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

struct Function {
  int module; // -1 for defined function
  string name;
  StrArr outs;
  StrArr ins;
  StrArr in_names;
  NodeNull code;

  bool hasCode (Function this) {
    if (this.code.isnull()) return 1<0;
    else return 0<1;
  }
}

Function newFunction () {
  return new Function(0-1, "", emptyStrArr(), emptyStrArr(), emptyStrArr(), nullNode());
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

struct Compiler {
  Node tree;
  Map typeMap;
  Map fnMap;
  ModuleArr modules;
  TypeArr types;
  FunctionArr functions;
  Map tpExports;
  Map fnExports;
}

void makeBasics (Compiler c) {
  c.modules.push(new Module("cobre.core", emptyStrArr()));
  c.modules.push(new Module("cobre.int", emptyStrArr()));
  c.modules.push(new Module("cobre.string", emptyStrArr()));

  c.types.push(newType(2, "bool"));
  c.types.push(newType(3, "int"));
  c.types.push(newType(4, "string"));
  c.types.push(newType(4, "char"));

  c.typeMap["bool"] = 0;
  c.typeMap["int"] = 1;
  c.typeMap["string"] = 2;
  c.typeMap["char"] = 3;
}

Function, string fnFromNode (Node item) {
  string alias = item.val;
  if (alias == "") alias = item.child(2).val;
  Function f = newFunction();
  f.name = item.val;

  Node innd = item.child(0);
  int k = 0;
  while (k < innd.len()) {
    Node argnd = innd.child(k);
    f.ins.push(argnd.child(0).val);
    f.in_names.push(argnd.child(1).val);
    k = k+1;
  }

  Node outnd = item.child(1);
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
      Node argnd = node.child(0);
      int j = 0;
      while (j < argnd.len()) {
        args.push(argnd.child(j).val);
        j = j+1;
      }
      c.modules.push(new Module(node.val, args));


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
            if (member.tp == "function") {
              int fnid = c.functions.len();
              Function f; string fn_alias;
              f, fn_alias = fnFromNode(member);
              f.module = id;
              thisArg(f, tp_alias);
              c.functions.push(f);
              tp.methods[fn_alias] = fnid;
            } else if (member.tp == "decl") {
              string name = member.val;
              string tpnm = member.child(0).val;

              string suffix = "";
              if (item.val == "") {} else { suffix = ":" + item.val; }

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
      StrArr args = emptyStrArr();
      args.push(base);
      c.modules.push(new Module("cobre.typeshell", args));

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

      tp.constructor = fromid;
      tp.casts[base] = fromid + 1;
    }
    if (node.tp == "struct") {
      int moduleid = c.modules.len() + 2;
      StrArr args = emptyStrArr();
      c.modules.push(new Module("cobre.record", args));

      int typeid = c.types.len();
      string alias = node.val;
      Type tp = newType(moduleid, "");
      c.types.push(tp);
      c.typeMap[alias] = typeid;
      c.tpExports[alias] = typeid;

      int fieldid = 0;
      int j = 0;
      while (j < node.len()) {
        Node member = node.child(j);
        if (member.tp == "decl") {
          string name = member.val;
          string ftp = member.child(0).val;

          args.push(ftp);

          int getid = c.functions.len();
          Function getter = newFunction();
          getter.module = moduleid;
          getter.ins.push(alias);
          getter.outs.push(ftp);
          getter.name = "get" + itos(fieldid);

          Function setter = newFunction();
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
          f.code = newNullNode(member.child(3));
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

void makeFunctions (Compiler c) {
  int i = 0;
  while (i < c.tree.len()) {
    Node node = c.tree.child(i);
    if (node.tp == "function") {
      int id = c.functions.len();
      Function f; string name;
      f, name = fnFromNode(node);
      f.code = newNullNode(node.child(3));
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
    newMap()
  );

  makeBasics(c);
  makeImports(c);
  makeTypes(c);
  makeFunctions(c);

  return c;
}

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

// =============================== //
//           File Writing          //
// =============================== //

void writenum (file f, int n) {
  // TODO: correctly format n > 127
  writebyte(f, n);
}

void writestr (file f, string s) {
  writenum(f, strlen(s));
  write(f, s);
}

void writeExports (Compiler c, file f) {
  int exportcount = c.fnExports.arr.len() + c.tpExports.arr.len();
  writebyte(f, 1); // Export module, kind 1 is defined
  writebyte(f, exportcount);
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
      writebyte(f, m.args.len()); // With 0 items
      int j = 0;
      while (j < m.args.len()) {
        string tpname = m.args[j];
        int tpid = c.typeMap[tpname];
        writebyte(f, 1); // Item kind 1 is type
        writenum(f, tpid);
        writestr(f, itos(j));
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
      int tpid = c.typeMap[tpname];
      writenum(f, tpid);
      j = j+1;
    }

    writenum(f, fn.outs.len());
    int j = 0;
    while (j < fn.outs.len()) {
      string tpname = fn.outs[j];
      int tpid = c.typeMap[tpname];
      writenum(f, tpid);
      j = j+1;
    }

    i = i+1;
  }
}

void writeBodies (Compiler c, file f) {
  int i = 0;
  while (i < c.functions.len()) {
    Function fn = c.functions[i];

    if (fn.hasCode()) {
      // TODO: Implement actual bodies
      // For now, all bodies are an empty return...
      writenum(f, 1);
      writenum(f, 0);
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

  writebyte(f, 0); // constants

  writeBodies(c, f);

  writebyte(f, 1); // static function
  writebyte(f, 0); //   (just return)

  writebyte(f, 0); // metadata
}


void main () {
  string src = readall("test.cu");
  Compiler c = compile(src);

  //printCompiler(c);
  writeCompiler(c, "out");
}