
import cobre.system {
  void print (string);
  string readall (string);
}

import cobre.string {
  int codeof (char);
  char, int charat(string, int);
  int length (string) as strlen;
  string add (string, char) as addch;
  string itos(int);
}

import cobre.array(token) {
  type `` as TkArr {
    //new (token, int);
    token get (int);
    void set (int, token);
    int len ();
    void push (token);
  }
  TkArr `new` (token, int) as newTkArr;
}

struct token {
  string tp;
  string val;
  int line;

  void print (token this) {
    print(itos(this.line) + ":   " + this.tp + " " + this.val);
  }
}

// TODO: Remove these functions
string getType (token tk) { return tk.tp; }
string getVal (token tk) { return tk.val; }

bool isDigit (char ch) {
  int code = codeof(ch);
  if (code >= 48) { // 0
    if (code <= 57) { // 9
      return 0<1; // true
    }
  }
  return 0<0; // false
}

bool isAlpha (char ch) {
  int code = codeof(ch);

  if (code == 95) // _
    return 0<1;

  if (code >= 65) // A
    if (code <= 90) // Z
      return 0<1;

  if (code >= 97) // a
    if (code <= 122) // z
      return 0<1;

  return 0<0; // false
}

bool isAlphaNum (char ch) {
  if (isAlpha(ch)) return 0<1;
  if (isDigit(ch)) return 0<1;
  return 0<0; // false
}

bool isKw (string s) {
  if (s == "true") return 0<1;
  if (s == "false") return 0<1;
  if (s == "null") return 0<1;
  if (s == "void") return 0<1;

  if (s == "if") return 0<1;
  if (s == "else") return 0<1;
  if (s == "while") return 0<1;
  if (s == "return") return 0<1;
  if (s == "continue") return 0<1;
  if (s == "break") return 0<1;
  if (s == "goto") return 0<1;

  if (s == "as") return 0<1;
  if (s == "new") return 0<1;
  if (s == "type") return 0<1;
  if (s == "struct") return 0<1;
  if (s == "import") return 0<1;
  if (s == "module") return 0<1;
  if (s == "extern") return 0<1;
  if (s == "export") return 0<1;
  if (s == "private") return 0<1;
  
  return 1<0;
}

bool isOp (char ch) {
  int code = codeof(ch);
  if (code == 40) return 0<1; // (
  if (code == 41) return 0<1; // )
  if (code == 42) return 0<1; // *
  if (code == 43) return 0<1; // +
  if (code == 44) return 0<1; // ,
  if (code == 45) return 0<1; // -
  if (code == 46) return 0<1; // .
  if (code == 58) return 0<1; // :
  if (code == 59) return 0<1; // ;
  if (code == 91) return 0<1; // [
  if (code == 93) return 0<1; // ]
  if (code == 123) return 0<1; // {
  if (code == 125) return 0<1; // }
  return 0<0; // false
}

bool maybeEq (char ch) {
  int code = codeof(ch);
  if (code == 33) return 0<1; // !
  if (code == 60) return 0<1; // <
  if (code == 61) return 0<1; // =
  if (code == 62) return 0<1; // >
  return 0<0; // false
}

bool isSpace (char ch) {
  int code = codeof(ch);
  if (code == 9)  { return 0<1; } // \t
  if (code == 10) { return 0<1; } // \n
  if (code == 32) { return 0<1; } // ' '
  return 0<0; // false
}

bool isQuote (char ch) {
  int code = codeof(ch);
  if (code == 34) { return 0<1; } // "
  if (code == 39) { return 0<1; } // '
  if (code == 96) { return 0<1; } // `
  return 0<0; // false
}

TkArr tokens (string input) {

  // Fix nasty bug where the last character is omited
  input = input + " ";

  TkArr arr = newTkArr(new token("", "", 0), 0);

  int len = strlen(input);
  int pos = 0;
  char ch;

  int line = 1;

  ch, pos = charat(input, pos);
  while (pos < len) {
  skipspace:
    while (isSpace(ch)) {
      // Count the line
      if (codeof(ch) == 10) { line = line+1; }
      if (pos >= len) { goto end; }
      ch, pos = charat(input, pos);
    }

    int code = codeof(ch);
    token tk;

    if (codeof(ch) == 47) { // '/'
      if (pos < len)
        ch, pos = charat(input, pos);
      if (codeof(ch) == 47) { // Start line comment
        linecom:
          if (codeof(ch) == 10) // \n
            goto endlinecom;
          if (pos >= len) goto end;
          ch, pos = charat(input, pos);
          goto linecom;
        endlinecom:
        // A line comment can only terminate with a newline, count it
        line = line+1;
        if (pos < len) ch, pos = charat(input, pos); // skip it
        goto skipspace;
      } else if (codeof(ch) == 42) { // '*' start multiline comment
        multicom:
          // Count lines in long comments
          if (codeof(ch) == 10) { line = line+1; }
          if (codeof(ch) == 42) { // '*'
            if (pos >= len) goto end;
            ch, pos = charat(input, pos);
            if (codeof(ch) == 47) // '/'
              goto endmulticom;
          }
          if (pos >= len) goto end;
          ch, pos = charat(input, pos);
          goto multicom;
        endmulticom:
        if (pos < len) ch, pos = charat(input, pos); // skip newline
        goto skipspace;
      } else {
        tk = new token("/", "", line);
      }
    }

    else if (isDigit(ch)) {
      string val = "";
      while (isDigit(ch)) {
        val = addch(val, ch);
        if (pos >= len) { goto enddigit; }
        ch, pos = charat(input, pos);
      }
      enddigit:
      tk = new token("num", val, line);
    }

    else if (isAlpha(ch)) {
      string val = addch("", ch);
      if (pos >= len) { goto endname; }
      ch, pos = charat(input, pos);
      while (isAlphaNum(ch)) {
        val = addch(val, ch);
        if (pos >= len) { goto endname; }
        ch, pos = charat(input, pos);
      }
      endname:
      if (isKw(val)) tk = new token(val, "", line);
      else tk = new token("name", val, line);
    }

    else if (isOp(ch)) {
      tk = new token(addch("", ch), "", line);
      if (pos < len)
        ch, pos = charat(input, pos);
    }

    else if (maybeEq(ch)) {
      string op = addch("", ch);
      if (pos < len) {
        ch, pos = charat(input, pos);
        if (codeof(ch) == 61) {
          op = op + "=";
          if (pos < len)
            ch, pos = charat(input, pos);
        }
      }
      tk = new token(op, "", line);
    }

    else if (isQuote(ch)) {
      int quoteCode = codeof(ch);
      string val = "";
      beginq:
        if (pos >= len) {
          print("Unfinished string");
          goto end;
        }
        ch, pos = charat(input, pos);

        // Closing quote
        if (codeof(ch) == quoteCode) goto endq;

        if (codeof(ch) == 92) { // Escape
          if (pos >= len) {
            print("Unfinished string");
            goto end;
          }
          ch, pos = charat(input, pos);
          val = addch(val+"\\", ch);
          goto beginq;
        }

        val = addch(val, ch); // Anything else
        goto beginq;
      endq:
      if (pos < len) ch, pos = charat(input, pos); // Skip closing quote
      if (quoteCode == 34) tk = new token("str", val, line);   // "
      if (quoteCode == 39) tk = new token("char", val, line);  // '
      if (quoteCode == 96) tk = new token("name", val, line);  // `
    }

    else {
      print(addch("Unexpected character ", ch));
      goto end;
    }

    // Push the token
    arr.push(tk);
  }
  end:

  arr.push(new token("eof", "", line+1));
  return arr;
}

void main () {
  //string src = " 756 3 void _a if ifn {.}() =<=<+ `x` \"\\\"\" }";
  string src = readall("test.cu");
  TkArr tks = tokens(src);
  int len = tks.len();
  print(itos(len) + " tokens:");
  int i = 0;
  while (i < len) {
    tks[i].print();
    i = i+1;
  }
}