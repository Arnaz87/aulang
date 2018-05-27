
module system = import cobre.system;
import module system { void println (string); }

//import G (f as `f`) { void g (); }

/*import cobre.lexer {
  type Lexer {
    char next ();
    int pos;
    int name:get ();
  }
}*/

void f () {
  println("This is f");
}

void lol (string[] arr) {
  println(arr[0] + ", " + arr[1]);
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
  //g();
  int l = a.arr.len();
}