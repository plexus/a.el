;;; a-test.el --- Associative function              -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Arne Brasseur

;; Author: Arne Brasseur <arne@arnebrasseur.net>

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the Mozilla Public License Version 2.0

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.

;; You should have received a copy of the Mozilla Public License along with this
;; program. If not, see <https://www.mozilla.org/media/MPL/2.0/index.txt>.

;;; Commentary:

;; Library for dealing with associative data structures: alists, hash-maps, and
;; vectors (for vectors, the indices are treated as keys)

;;; Code:

(require 'a)
(require 'ert)

(ert-deftest a-get-test ()
  (should (equal (a-get '((:foo . 5)) :foo) 5))
  (should (equal (a-get '((:foo . 5)) :bar) nil))
  (should (equal (a-get '((:foo . 5)) :bar :fallback) :fallback))
  (should (equal (a-get [1 2 3] 1) 2))
  (should (equal (a-get [1 2 3] 5) nil))
  (should (equal (a-get [1 2 3] 5 :fallback) :fallback))

  (let ((hash (make-hash-table :test #'equal)))
    (puthash :foo 123 hash)
    (puthash :bar 456 hash)
    (should (equal (a-get hash :bar) 456))
    (should (equal (a-get hash :baz) nil))
    (should (equal (a-get hash :baz :baq) :baq))))

(ert-deftest a-get-in-test ()
  (should (equal (a-get-in [1 2 [3 4 [5] 6]] [2 2 0]) 5))
  (should (equal (a-get-in [1 ((:a . ((:b . [3 4 5]))))] [1 :a :b 2]) 5))
  (should (equal (a-get-in [] []) []))
  (should (equal (a-get-in [] [2] :foo) :foo)))

(ert-deftest a-has-key?-test ()
  (should (a-has-key? [1 2 3] 2))
  (should (not (a-has-key? [1 2 3] 3)))
  (should (not (a-has-key? [1 2 3] -1)))
  (should (not (a-has-key? [1 2 3] :foo)))

  (should (a-has-key? '((:a . 5)) :a))
  (should (not (a-has-key? '((:a . 5)) :b)))

  (let ((hash (make-hash-table :test #'equal)))
    (puthash :foo 123 hash)
    (should (equal (a-has-key? hash :foo) t))
    (should (equal (a-has-key? hash :bar) nil))))

(ert-deftest a-assoc-test ()
  (should (equal (a-assoc '() :foo :bar) '((:foo . :bar))))
  (should (equal (a-assoc '((:foo . :baz)) :foo :bar) '((:foo . :bar))))
  (should (equal (a-assoc '((:foo . :baz))
                          :foo :bar
                          :baz :baq) '((:baz . :baq) (:foo . :bar))))

  (should (equal (a-assoc [1 2 3] 1 :foo) [1 :foo 3]))
  (should (equal (a-assoc [1 2 3] 5 :foo) [1 2 3 nil nil :foo]))

  (let ((hash (make-hash-table :test #'equal)))
    (puthash :foo 123 hash)
    ;;TODO
    ))

(ert-deftest a-keys-test ()
  (should (equal (a-keys '((:a . 1) (:b . 2))) '(:a :b)))

  (let ((hash (make-hash-table :test #'equal)))
    (puthash :foo 123 hash)
    (puthash :bar 123 hash)

    (should (equal (a-keys hash) '(:bar :foo)))))

(ert-deftest a-vals-test ()
  (should (equal (a-vals '((:a . 1) (:b . 2))) '(1 2)))
  (let ((hash (make-hash-table :test #'equal)))
    (puthash :foo 123 hash)
    (puthash :bar 456 hash)
    (should (equal (a-vals hash) '(456 123)))))

(ert-deftest a-reduce-kv ()
  (should (equal
           (a-reduce-kv
            (lambda (acc k v)
              (cons
               (concat (symbol-name k) "--" (number-to-string v))
               acc))
            nil '((:a . 1) (:b . 2)))
           '(":b--2" ":a--1"))))

(ert-deftest a-reduce-kv-test ()
  (should (equal
           (a-reduce-kv
            (lambda (acc k v)
              (cons
               (concat (symbol-name k) "--" (number-to-string v))
               acc))
            nil '((:a . 1) (:b . 2)))
           '(":b--2" ":a--1"))))

(ert-deftest a-equal-test ()
  (should (a-equal '((:a . 1) (:b . 2)) '((:b . 2) (:a . 1))))
  (should (a-equal '((:a . 1) (:b . 2)) '((:a . 1) (:b . 2))))
  (should (not (a-equal '((:a . 1) (:c . 2)) '((:a . 1) (:b . 2)))))
  (should (not (a-equal '((:a . 1) (:b . 2)) '((:a . 1) (:b . 3)))))
  (should (not (a-equal '((:a . 1) (:b . 2)) '((:a . 1)))))
  (should (not (a-equal '((:a . 1) (:b . 2)) '((:a . 1) (:b . 2) (:c . 3)))))

  (let ((hash (make-hash-table :test #'equal)))
    (puthash :foo 123 hash)
    (puthash :bar 456 hash)
    (should (a-equal hash '((:foo . 123) (:bar . 456)))))

  (should (a-equal '((:a . 1) (:b . 2)) '((:b . 2) (:a . 1)))))

(ert-deftest a-merge-test ()
  (should
   (a-equal
    (a-merge
     '((:a . 1) (:b . 2)))
    '((:b . 2) (:a . 1))))

  (should
   (a-equal
    (a-merge
     nil
     '((:a . 1) (:b . 2)))
    '((:b . 2) (:a . 1))))

  (should
   (a-equal
    (a-merge
     nil
     '((:a . 1) (:b . 2))
     '((:c . 3) (:b . 5)))
    '((:a . 1) (:b . 5) (:c . 3)))))

(ert-deftest a-alist ()
  (should
   (a-equal
    (a-alist :a 1 :b 2)
    '((:b . 2) (:a . 1)))))

(ert-deftest a-assoc-in-test ()
  (should
   (equal
    (a-assoc-in (a-alist :foo (a-alist :bar [1 2 3])) [:foo :bar 2] 5)
    '((:foo
       (:bar . [1 2 5])))))

  (should
   (equal
    (a-assoc-in (a-alist :foo nil) [:foo :bar 2] 5)
    '((:foo . ((:bar . ((2 . 5)))))))))

(ert-deftest a-update-in-test ()
  (should
   (equal
    (a-update-in (a-alist :foo (a-alist :bar [1 2 "x"]))
                 [:foo :bar 2]
                 #'concat "y")
    '((:foo (:bar . [1 2 "xy"]))))))

(provide 'a-test)
;;; a-test.el ends here
