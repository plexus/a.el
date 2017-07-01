# a.el

Emacs Lisp functions for dealing with associative structures in a uniform and functional way.

Inspired by Clojure, dash, and seq.el.

These functions can take association lists, hash tables, or vectors (where the index is considered the key).

## Functions

``` emacs-lisp
(a-list :foo 5 :bar 6)
;;=> ((:foo . 5) (:bar . 6))

(setq m (a-list :foo 5 :bar 6))
(setq h (make-hash-table))

(puthash :abc 123 h)
(puthash :def 456 h)

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

(a-assoc-in (a-list :name "Arne")
            [:stats :score] 100)
;;=> ((:name . "Arne") (:stats . ((:score . 100))))

(a-merge m h (a-list :and :more))
;;=> ((:and . :more) (:abc . 123) (:def . 456) (:foo . 5) (:bar . 6))

(a-update (a-list :name "Arne") :name 'concat " Brasseur")
;;=> ((:name . "Arne Brasseur"))

(setq player (a-list :name "Arne" :stats (a-list :score 99)))
(a-update-in player  [:stats :score] '+ 1)
;;=> ((:name . "Arne") (:stats (:score . 100)))
```

## LICENSE

&copy; Arne Brasseur 2017

Distributed under the terms of the Mozilla Public License 2.0.
