
// https://en.wikipedia.org/wiki/Association_list

import module argument {
  type T;
  type K;
  bool f (T, K);
}

import cobre.`null` (_Node) {
  type `` as Maybe {
    bool isnull ();
    _Node get ();
  }
  Maybe `null` () as None;
  Maybe `new` (_Node) as Some;
}

private struct Node { T t; Maybe next; }
private type _Node (Node);

private struct _List { Maybe head; }

private type List (_List);
export List as ``;

import cobre.`null` (T) {
  type `` as MaybeT {
    bool isnull ();
    T get ();
  }
  bool isnull (MaybeT) as isnullT;
  T get (MaybeT) as getT;
  MaybeT `null` () as NoneT;
  MaybeT `new` (T) as SomeT;
}
export MaybeT as R;
export isnullT as testR;
export getT as getR;

MaybeT get (List l, K key) {
  Maybe maybe = (l as _List).head;
  repeat:
    if (maybe.isnull()) return NoneT();
    Node nd = maybe.get() as Node;
    T t = nd.t;
    if (f(t, key)) return SomeT(t);
    maybe = nd.next;
  goto repeat;
}

void add (List _l, T t) {
  _List l = _l as _List;
  Maybe old = l.head;
  Node node = new Node(t, l.head);
  l.head = Some(node as _Node);
}

List `new` () { return (new _List(None())) as List; }
