import cobre.system { void println (string); }
import cobre.string { string itos(int); }

void foo (string? x) {
  if (x.isnull()) println("isnull");
  else println(x.get());
}

void main () {
  foo("Hola" as string?);
  foo(new string?());
}

//void main () { println("Hola Mundo! " + itos(40 + 2)); }