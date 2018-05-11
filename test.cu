
import cobre.system { void print (string); }

void lol (string[] arr) {
  print(arr[0] + " " + arr[1]);
}

struct A {
  string[] arr;
}

void main () {
  A a = new A(new string[]());
  a.arr.push("foo");
  a.arr.push("bar");
  a.arr[0] = "Foo";
  lol(a.arr);
  int l = a.arr.len();
}