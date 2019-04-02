
import aulang.node {
  type Node as Node {
    string to_string ();
  }
}

struct Item {
  string tp;
  Node node;
  any value;

  string to_str (Item this) {
    return this.tp + " " + this.node.to_string();
  }
}

private Item _new (string tp, Node node) {
  return new Item(tp, node, false as any);
}
export _new as `new\x1dItem`;