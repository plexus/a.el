[![MELPA](https://melpa.org/packages/a-badge.svg)](https://melpa.org/#/a)
[![MELPA Stable](https://stable.melpa.org/packages/a-badge.svg)](https://stable.melpa.org/#/a)

# a.el

Emacs Lisp functions for dealing with associative structures in a uniform and functional way.

Inspired by Clojure, dash, and seq.el.

## Project status

This library is stable and is not expected to change. We will still consider
submitted patches for critical bugs, or to stay compatible with newer versions
of GNU Emacs, if necessary, to the extent possible without breaking
compatibility with Emacs 25-28.

If your code works with `a.el` then we'll try to make sure it continues to work!

## Should you use it for new code?

tl;dr

- your package can't be included in GNU ELPA if you use a.el
- a's value semantics can be costly
- your code will become easier to work on by people coming from Clojure, but harder for experienced elisp devs
- it's an extra dependency you may not need

`a.el` is not in accordance with [GNU ELPA](https://elpa.gnu.org/)'s naming
guidelines, meaning it will never be part of GNU ELPA, and can not be used in
packages that ever wish to be included in GNU ELPA. This is the reason `a.el`
usage was removed from CIDER and parseclj/parseedn. It *is* available from
[MELPA](https://github.com/melpa/melpa).

The unique selling point for `a.el` is that it lets you reuse your Clojure
experience in Emacs, so Clojure programmers can be productive quickly. If you
are not experienced in Clojure, or you want to do things "the Emacs way", then
there are other alternatives. Most functions in `a.el` can be straightforwardly
replaced with Emacs built-ins, and as such the `a.el` code can be a great cheat
sheet of how to do things instead. 

That said not every `clojure.core` has a straightforward equivalent, and so if
you rely on those then `a.el` may still provide you with value. In particular
`a.el` implements equality semantics similar to Clojure's, with value semantics
across associative and sequential data structures. This is something that is not
trivial to replicate with Emacs built-ins. That said this doesn't come for free,
Emacs Lisp's data structures don't retain a cached hashCode the way Clojure's
persistent data structures do, and so we have to always recursively walk them.
That may be a high cost if you don't need it.

The main alternative to `a.el` is the
[map.el](https://github.com/emacs-mirror/emacs/blob/master/lisp/emacs-lisp/map.el)
library that nowadays comes bundled with Emacs. You can also use Common Lisp
style functions (i.e. `cl-*`) through requiring `cl-lib`. This is now even
allowed in code that comes bundled with Emacs, which was not the case in the
past.

Emacs also comes bundled with [asoc.el](https://github.com/troyp/asoc.el) but it
seems this library is marked as obsolete already, and you will get a warning
about that.

Other useful third-party libraries include:

- [ht.el](https://github.com/Wilfred/ht.el) Hash table library
- [kv.el](https://github.com/nicferrier/emacs-kv) A collection of tools for dealing with key/value data structures such as plists, alists and hash-tables.

## Usage

All functions can take association lists, hash tables, and in some cases vectors (where the index is considered the key).

This library copies the names and semantics of the Clojure standard library. If you know Clojure then just add `a-` to the function name. The only exceptions are:

- `a-alist` is an association list contructor, it has no Clojure counterpart.
- `a-has-key?` is the equivalent of Clojure's `contains?`. This historical naming mistake won't be fixed in Clojure, but we can fix it here.
- predicates have both a `?` and a `-p` version, e.g. `a-has-key-p`. Use the latter if you want greater consistency with existing Elisp code.

All functions in this library are pure, they do not mutate their arguments.

## Requirements

a.el relies on features that are part of Emacs 25, so you need Emacs 25 or later. There are no other dependencies.

## Installation

a.el is available from [MELPA](https://github.com/melpa/melpa).

## Functions

``` emacs-lisp
(a-list :foo 5 :bar 6)
;;=> ((:foo . 5) (:bar . 6))

(setq m (a-list :foo 5 :bar 6))
(setq h (a-hash-table :abc 123 :def 456))

(a-associative? m)
;;=> t
(a-associative? h)
;;=> t

(a-get m :foo)
;;=> 5
(a-get h :abc)
;;=> 123

(a-assoc m :foo 7 :baq 20)
;;=> ((:baq . 20) (:foo . 7) (:bar . 6))
(a-assoc h :foo 7)
;;=> #s(hash-table ... (:abc 123 :def 456 :foo 7 ...))

(a-keys m)
;;=> (:foo :bar)
(a-keys h)
;;=> (:def :abc)

(a-vals m)
;;=> (5 6)
(a-vals h)
;;=> (456 123)

(a-equal m (a-list :bar 6 :foo 5))
;;=> t

(a-has-key? m :bar)
;;=> t

(a-count h)
;;=> 2

(a-dissoc m :foo)
;;=> ((:bar . 6))

(a-assoc-in (a-list :name "Arne")
            [:stats :score] 100)
;;=> ((:name . "Arne") (:stats . ((:score . 100))))

(a-merge m h (a-list :and :more))
;;=> ((:and . :more) (:abc . 123) (:def . 456) (:foo . 5) (:bar . 6))

(a-merge-with '+ m (a-list :foo 10))
;;=> ((:foo . 15) (:bar . 6))

(a-update (a-list :name "Arne") :name 'concat " Brasseur")
;;=> ((:name . "Arne Brasseur"))

(setq player (a-list :name "Arne" :stats (a-list :score 99)))
(a-update-in player  [:stats :score] '+ 1)
;;=> ((:name . "Arne") (:stats (:score . 100)))
```

## LICENSE

&copy; Arne Brasseur 2017

Distributed under the terms of the GNU General Public License, version 3.0 or later. See LICENSE.
