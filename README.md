# toy-forth-in-picolisp

This toy Forth is implemented using the [OOP](http://www.software-lab.de/doc/tut.html#oop) capabilities
of [PicoLisp](http://picolisp.com/). It is mostly intended as a proof-of-concept, and very little
has been done to keep the user from doing stupid errors. In addition, this will probably not teach you
much about how to implement real Forth.

I suggest you run it like this:
```
pil path/to/forth.l +
```

All predefined words (except `pause` and `bye`) are implemented as PicoLisp methods of the `+Forth` class.
When new words are defined, they are also implemented as methods, but on the current `+Forth` object only,
not on the class. This way one may have a few `+Forth` instances, existing at the same time, differing
in the words that are defined.

These are the only (fairly standard) predefined words currently available:

- `drop`
- `dup`
- `over`
- `swap`
- `1+`
- `1-`
- `+`
- `*`
- `<`
- `>`
- `i`
- `.s`

In addition you may use `pause` to temporarily exit out into the PicoLisp REPL, assuming you started
this foth.l as recommended. You may then get back
into the same `+Forth` object again doing `(resume)`. The other special word is `bye`, which exits out
into the shell.

To define a new word, you use a sequence of words or numbers starting with a `:` and ending with a `;`,
where the first word after the `:` is the name of the new word. In this implementation you may also
create recursive words. A recursive definition of the factorial function can be done like this:
```
: fac dup 1 > if dup 1- fac * then ;
```
To use this new `fac` word to compute 5!, and then display the stack, you just do this: `5 fac .s`

There are a few word patterns that involve keywords, and those keywords must be regarded as reserved words.
The patterns are:

- `:` wordname token1 token2 ...  `;`
- `if` token1 ... [`else` token2 ...] `then`
- `do` token1 ... `loop`

Some other Forth implementations doesn't allow if-else-then and do-loop to be used outside word definition
blocks, but with this implementation you can do that.

The three patterns mentioned above are implemented as classes (`+DefineWord`, `+IfElseThen`, `+DoLoop`).
As subclasses of `+WordBlock` they are instantiated and executed in similar ways: When the first
keyword (`:`, `if`, `do`) is received, an object of the corresponding class is constructed.
Subsequent tokens are then fed to this object, until the closing keyword is received. If this object
is not part/child of an enclosing pattern object, then the `execute>` method of the object will be
called.

Example: When we, in the Forth REPL, enter the line defining the `fac` word above,
the `execute>` method of the `+IfElseThen` will not be called when the `then` word arrives, since that
object is part of another pattern, but the `execute>` method of the `+DefineWord` will be called,
meaning that the new word will be defined (but not executed).

At the end of the forth.l file there are a couple of references to `*EMUENV`, and two functions
`emuForthReplHandler` and `activateEmuForthRepl`. Please just ignore them, as this forth.l currently
doesn't work with EmuLisp.

Enjoy!
