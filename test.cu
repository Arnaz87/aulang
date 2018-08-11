
void main () {
  float a = itof(3) / itof(2);
  if (a > itof(1)) println("a > 1");
  if (a < itof(1)) println("a < 1");
  if (a < itof(2)) println("a < 2");
  println(ftos(a));
}