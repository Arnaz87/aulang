
import cobre.system { void print (string); }

import cobre.array (string) {
  type `` as `string[]` {
    string get (int);
    void set (int, string);
    int len ();
    void push (string);
    new (string, int);
  }
  //`string[]` `new` (string, int) as `new string[]`;
}

void main () {
  `string[]` arr = new `string[]`("foo", 2);
  arr[1] = "bar";
  print(arr[0] + arr[1]);
}