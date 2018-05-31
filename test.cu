import cobre.system { void println (string); }
import cobre.string { string itos(int); }

type Str (string[]);

void main () {
  string[] arr = new string[]();
  arr.push("hola yo");
  Str s = arr as Str;
  println((s as string[])[0]);
}

//void main () { println("Hola Mundo! " + itos(40 + 2)); }