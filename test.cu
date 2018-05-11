
import cobre.system { void print (string); }

void lol (string[] arr) {
  print(arr[0] + ", " + arr[1]);
}

void main () {
  string[] arr = new string[]();
  arr.push("foo");
  arr.push("bar");
  arr[0] = "foo";
  lol(arr);
}