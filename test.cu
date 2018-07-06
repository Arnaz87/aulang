
import cobre.system { void println (string); }

void f (any a) {
  if (a is string) println(a as string);
  else println(":C");
}

void main () {
  f("hola" as any);
  f(4 as any);
}