
import cobre.system {
  void print (string);
}

import cobre.string {
  string itos(int);
}

void main () {
  int bottles = 5;

  while (bottles > 0) {
    string plural = " bottles";
    if (bottles == 1) { plural = " bottle"; }

    string bottle_s = itos(bottles);

    print(bottle_s + plural + " of beer on the wall");
    print(bottle_s + plural + " of beer");
    print("Take one down, pass it around");
    bottles = bottles - 1;
    
    if (bottles == 1) { plural = " bottle"; }
    else { plural = " bottles"; }
    
    print(itos(bottles) + plural + " of beer on the wall");
    print("");
  }
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