
import auro.buffer {
  type buffer;
  buffer `new` (int size) as newbuf;
  int size (buffer) as bufsize;
  int get (buffer, int index) as bufget;
  void set (buffer, int index, int value) as bufset;
}

import auro.string {
  int length (string) as strlen;
  buffer tobuffer (string) as strbuf;
}

private int MAX = 64*8;

private type PartShell (Part);
struct Part {
  buffer buf;
  int size;
  PartShell? _next;

  Part? next (Part this) {
    if (this._next.isnull())
      return new Part?();
    return (this._next.get() as Part) as Part?;
  }
}

Part newPart () { return new Part(newbuf(MAX), 0, new PartShell?()); }

import auro.int.bit {
  int shr (int, int);
  int and (int, int);
  int or (int, int);
}

struct Writer {
  Part first;
  Part last;
  int count;

  void byte (Writer this, int n) {
    Part part = this.last;
    if (part.size >= MAX) {
      Part next = newPart();
      part._next = (next as PartShell) as PartShell?;
      this.last = next;
      this.count = this.count + 1;
      part = next;
    }
    bufset(part.buf, part.size, n);
    part.size = part.size + 1;
  }

  void _num (Writer this, int n) {
    if (n > 127) this._num(shr(n, 7));
    this.byte(or(and(n, 127), 128));
  }

  void num (Writer this, int n) {
    if (n > 127) this._num(shr(n, 7));
    this.byte(and(n, 127));
  }

  void rawstr (Writer this, string s) {
    buffer buf = strbuf(s);
    int i = 0;
    while (i < bufsize(buf)) {
      this.byte(bufget(buf, i));
      i = i+1;
    }
  }

  void str (Writer this, string s) {
    this.num(strlen(s));
    this.rawstr(s);
  }

  buffer tobuffer (Writer this) {
    buffer buf = newbuf((this.count * MAX) + this.last.size);
    Part part = this.first;
    int i = 0;
    loop:
      int j = 0;
      while (j < part.size) {
        bufset(buf, i, bufget(part.buf, j));
        j = j+1;
        i = i+1;
      }
      Part? next = part.next();
      if (!next.isnull()) {
        part = next.get();
        goto loop;
      }
    return buf;
  }
}

private Writer _new () {
  Part part = newPart();
  return new Writer(part, part, 0);
}
export _new as `new\x1dWriter`;