
import cobre.core { type any; }

import cobre.system { void print (string); }
import cobre.string { string itos (int); }

import cobre.any (string as xd, int as `0`) {
  any `new` (int) as anyInt;
  int get (any) as getInt;
}

void main () {
  any a = anyInt(42);
  print(itos(getInt(a)));
}