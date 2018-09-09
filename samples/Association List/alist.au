
// https://en.wikipedia.org/wiki/Association_list

import module argument {
  type T;
  type K;
  bool f (T, K);
}

private struct Node { T t; _Node? next; }
private type _Node (Node);

private struct _List { _Node? head; }

private type List (_List);
export List as ``;

T? get (List l, K key) {
  _Node? maybe = (l as _List).head;
  repeat:
    if (maybe.isnull()) return new T?();
    Node nd = maybe.get() as Node;
    T t = nd.t;
    if (f(t, key)) return t as T?;
    maybe = nd.next;
  goto repeat;
}

void add (List _l, T t) {
  _List l = _l as _List;
  _Node? old = l.head;
  Node node = new Node(t, l.head);
  l.head = (node as _Node) as _Node?;
}

List `new` () { return (new _List(new _Node?())) as List; }
