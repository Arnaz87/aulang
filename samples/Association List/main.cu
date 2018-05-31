
import cobre.system { void println (string); }

struct Pair { string k; string v; }

bool eq (Pair p, string k) { return p.k == k; }

import alist (Pair as T, string as K, eq as f) {
  type R; Pair getR (R); bool testR (R);
  type `` as Map { R get (string); void add (Pair); }
  Map `new` () as newMap;
}

void check (Map map, string key) {
  R r = map[key];
  if (testR(r)) println(key + " :(");
  else println(getR(r).v + " :D");
}

void main () {
  Map map = newMap();
  map.add(new Pair("Jenna", "Marbles"));
  map.add(new Pair("Emma", "Watson"));
  check(map, "Emma");
  check(map, "Hermione");
}