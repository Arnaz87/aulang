
import cobre.system { void println (string); }

struct Pair { string k; string v; }

bool eq (Pair p, string k) { return p.k == k; }

import alist (Pair as T, string as K, eq as f) {
  type `` as Map { Pair? get (string); void add (Pair); }
  Map `new` () as newMap;
}

void check (Map map, string key) {
  Pair? r = map[key];
  if (r.isnull()) println(key + " :(");
  else println(r.get().v + " :D");
}

void main () {
  Map map = newMap();
  map.add(new Pair("Jenna", "Marbles"));
  map.add(new Pair("Emma", "Watson"));
  check(map, "Emma");
  check(map, "Hermione");
}