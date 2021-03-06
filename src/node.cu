

import auro.utils.arraylist (NodeShell) {
  type `` as `Node[]` {
    new ();
    NodeShell get (int);
    void push (NodeShell);
    int len ();
  }
}

type NodeShell (Node);

struct Node {
  string tp;
  string val;
  int line;
  Node[] children;

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
    if (this.line >= 0) { pos = "["+itos(this.line)+"] "; }

    println(indent + pos + this.tp + " " + this.val);
    int i = 0;
    while (i < this.len()) {
      this.child(i).print(indent + "  ");
      i = i+1;
    }
  }

  string to_string (Node this) {
    if (this.tp == "item") return this.val;

    string s = this.tp;
    if (!(this.val == "")) {
      s = s + ":" + this.val;
    }
    s = s + "[";
    int i = 0;
    while (i < this.len()) {
      if (i > 0) s = s + ", ";
      s = s + this.child(i).to_string();
      i = i+1;
    }
    s = s + "]";
    return s;
  }

  Node inline (Node this, int line) {
    this.line = line;
    return this;
  }
}

private Node _new (string tp, string val) {
  return new Node(tp, val, 0-1, new Node[]());
}
export _new as `new\x1dNode`;