# nickel-ts-mode

An Emacs major mode for [Nickel][], built on [Tree-sitter][].

It uses Emacs's built-in Tree-sitter support (Emacs 29 or later) and
the [tree-sitter-nickel][] grammar.

## Features

- **Syntax highlighting** from the grammar. Raise or lower the detail
  by setting `treesit-font-lock-level`.
- **Navigation** between let bindings and record fields. `C-M-a` and
  `C-M-e` move to the start and end of the enclosing or previous one.
  `C-M-h` marks it. `M-x imenu` lists them all. On Emacs 31 and later,
  `C-M-f`, `C-M-b`, `C-M-u` and `C-M-d` move over and into records,
  arrays, parenthesized terms and strings.
- **Folding** with `outline-minor-mode` (Emacs 30 and later): let
  blocks and record fields are headings.
- **Formatting** with `nickel format`, bound to `C-c C-f`. On a parse
  error the buffer is left unchanged and the error is shown.

The mode does no indentation of its own: format the buffer instead.

## Installation

Add the following to your `.init.el` file:

```elisp
(use-package nickel-ts-mode
  :vc (:url "https://github.com/mboes/nickel-ts-mode"))
```

Finally, install the grammar once:

```
M-x treesit-install-language-grammar RET nickel RET
```

`.ncl` files open in `nickel-ts-mode`. Formatting needs `nickel` on
your `PATH`, or set `nickel-ts-command`.

## Development

`nix develop` provides a shell with all required dependencies. Install
the grammar once, then compile, lint and test:

```
eldev eval "(treesit-install-language-grammar 'nickel)"
eldev compile --warnings-as-errors
eldev lint
eldev test
```

Highlighting tests live in `test/nickel-ts-mode-resources/`. They
require Emacs 30 or later. Each file is a Nickel expression annotated
with comments: a caret points at a character on the nearest code line
above, followed by the face it should have, as in

```nickel
fun p1 p2 f => p1 f && p2 f
#   ^ font-lock-variable-name-face
```

[melpa]: https://melpa.org
[nickel]: https://nickel-lang.org
[tree-sitter]: https://tree-sitter.github.io/tree-sitter/
[tree-sitter-nickel]: https://github.com/nickel-lang/tree-sitter-nickel
