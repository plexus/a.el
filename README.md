# a.el

Emacs Lisp functions for dealing with associative structures in a uniform and functional way.

Inspired by Clojure, dash, and seq.el.

These functions can take association lists, hash tables, and in some cases vectors (where the index is considered the key).

## Requirements

a.el relies on features that are part of Emacs 25, so you need Emacs 25 or later. There are no other dependencies.

## Installation

a.el is available from Lambda Island ELPA. Add this to your `~/.emacs` or `~/.emacs.d/init.el`

``` emacs-lisp
(require 'package)
(add-to-list 'package-archives
             '("lambdaisland" . "http://lambdaisland.github.io/elpa/") t)
```

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
