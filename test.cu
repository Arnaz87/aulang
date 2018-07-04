
import cobre.system { void println (string); }

void f (any a) {
  if ((a as string?).isnull()) println(":(");
  else println((a as string?).get());
}

void main () {
  f("hola" as any);
  f(4 as any);
}