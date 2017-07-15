;;; a.el --- Associative data structure functions   -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Arne Brasseur

;; Author: Arne Brasseur <arne@arnebrasseur.net>
;; URL: https://github.com/plexus/a.el
;; Keywords: lisp
;; Version: 0.1.0-alpha2
;; Package-Requires: ((dash "2.12.0") (emacs "25"))

;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the Mozilla Public License Version 2.0

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the Mozilla Public License for more details.

;; You should have received a copy of the Mozilla Public License along with this
;; program. If not, see <https://www.mozilla.org/media/MPL/2.0/index.txt>.

;;; Commentary:

;; Library for dealing with associative data structures: alists, hash-maps, and
;; vectors (for vectors, the indices are treated as keys).
;;
;; This library is largely inspired by Clojure, it has many of the functions
;; found in clojure.core, prefixed with `a-'. All functions treat their
;; arguments as immutable, so e.g. `a-assoc' will clone the hash-table or alist
;; it is given. Keep this in mind when writing performance sensitive code.

;;; Code:

(eval-when-compile (require 'subr-x)) ;; for things like hash-table-keys

(require 'dash)
(require 'cl-lib)

(defun a-get (map key &optional not-found)
  "Return the value MAP mapped to KEY, NOT-FOUND or nil if key not present."
  (cond
   ((listp map)         (alist-get key map not-found))
   ((vectorp map)       (if (a-has-key? map key)
                            (aref map key)
                          not-found))
   ((hash-table-p map)  (gethash key map not-found))
   (t (user-error "Not associative: %S" map))))

(defun a-get-in (m ks &optional not-found)
  "Look up a value in a nested associative structure.

Given a data structure M, and a sequence of keys KS, find the
value found by using each key in turn to do a lookup in the next
\"layer\". Return `nil' if the key is not present, or the NOT-FOUND
value if supplied."
  (let ((result m))
    (cl-block nil
      (seq-doseq (k ks)
        (if (a-has-key? result k)
            (setq result (a-get result k))
          (cl-return not-found)))
      result)))

(defun a-has-key? (coll k)
  "Check if the given associative collection COLL has a certain key K."
  (cond
   ((listp coll)         (not (eq (alist-get k coll :not-found) :not-found)))
   ((vectorp coll)       (and (integerp k) (< -1 k (length coll))))
   ((hash-table-p coll)  (not (eq (gethash k coll :not-found) :not-found)))
   (t (user-error "Not associative: %S" coll))))

(defalias 'a-has-key 'a-has-key?)

(defun a-assoc-1 (coll k v)
  "Like `a-assoc', (in COLL assoc K with V) but only takes a single k-v pair.
Internal helper function."
  (cond
   ((listp coll)
    (if (a-has-key? coll k)
        (mapcar (lambda (entry)
                  (if (equal (car entry) k)
                      (cons k v)
                    entry))
                coll)
      (cons (cons k v) coll)))

   ((vectorp coll)
    (if (and (integerp k) (> k 0))
        (if (< k (length coll))
            (let ((copy (copy-sequence coll)))
              (aset copy k v)
              copy)
          (vconcat coll (-repeat (- k (length coll)) nil) (list v)))))

   ((hash-table-p coll)
    (let ((copy (copy-hash-table coll)))
      (puthash k v copy)
      copy))))

(defun a-assoc (coll &rest kvs)
  "Return an updated collection COLL, associating values with keys KVS."
  (when (not (cl-evenp (a-count kvs)))
    (user-error "a-assoc requires an even number of arguments!"))
  (-reduce-from (lambda (coll kv)
                  (seq-let [k v] kv
                    (a-assoc-1 coll k v)))
                coll (-partition 2 kvs)))

(defun a-keys (coll)
  "Return the keys in the collection COLL."
  (cond
   ((listp coll)
    (mapcar #'car coll))

   ((hash-table-p coll)
    (hash-table-keys coll))))

(defun a-vals (coll)
  "Return the values in the collection COLL."
  (cond
   ((listp coll)
    (mapcar #'cdr coll))

   ((hash-table-p coll)
    (hash-table-values coll))))

(defun a-reduce-kv (fn from coll)
  "Reduce with FN starting from FROM the collection COLL.
Reduce an associative collection COLL, starting with an initial
value of FROM. The reducing function FN receives the intermediate
value, key, and value."
  (-reduce-from (lambda (acc key)
                  (funcall fn acc key (a-get coll key)))
                from (a-keys coll)))

(defun a-count (coll)
  "Count the number of key-value pairs in COLL.
Like length, but can also return the length of hash tables."
  (cond
   ((seqp coll)
    (length coll))

   ((hash-table-p coll)
    (hash-table-count coll))))

;; TODO: add a-eql which also checks type equality
;; TODO: terminate early
(defun a-equal (a b)
  "Compare collections A and B for value equality.
Return true if both collections have the same set of key-value
pairs, or false otherwise. Association lists and hash tables with
the same contents are considered equal."
  (and (eq (a-count a) (a-count b))
       (a-reduce-kv (lambda (bool k v)
                      (and bool (equal v (a-get b k))))
                    t
                    a)))

(defalias 'a-equal? 'a-equal)

(defun a-merge (&rest colls)
  "Merge multiple associative collections.
Return the type of the first collection COLLS."
  (-reduce (lambda (this that)
             (a-reduce-kv (lambda (coll k v)
                            (a-assoc coll k v))
                          this
                          that))
           colls))

;; TODO a-merge-with

(defun a-alist (&rest kvs)
  "Create an association list from the given keys and values KVS.
Arguments are simply provided in sequence, rather than as lists or cons cells.
For example: (a-alist :foo 123 :bar 456)"
  (mapcar (lambda (kv) (cons (car kv) (cadr kv))) (-partition 2 kvs)))

(defalias 'a-list 'a-alist)

(defun a-hash-table (&rest kvs)
  "Create a hash table from the given keys and values KVS.
Arguments are simply provided in sequence, rather than as lists
or cons cells. As \"test\" for the hash table, equal is used. The
hash table is created without extra storage space, so with a size
equal to amount of key-value pairs, since it is assumed to be
treated as immutable.
For example: (a-hash-table :foo 123 :bar 456)"
  (let* ((kv-pairs (seq-partition kvs 2))
         (hash-map (make-hash-table :test 'equal :size (length kv-pairs))))
    (seq-do (lambda (pair)
              (puthash (car pair) (cadr pair) hash-map))
            kv-pairs)
    hash-map))

(defun a-assoc-in (coll keys value)
  "In collection COLL, at location KEYS, associate value VALUE.
Associates a value in a nested associative collection COLL, where
KEYS is a sequence of keys and VALUE is the new value and returns
a new nested structure. If any levels do not exist, association
lists will be created."
  (case (length keys)
    (0 coll)
    (1 (a-assoc-1 coll (elt keys 0) value))
    (t (a-assoc-1 coll
                  (elt keys 0)
                  (a-assoc-in (a-get coll (elt keys 0))
                              (seq-drop keys 1)
                              value)))))

;; TODO a-dissoc-in

(defun a-update (coll key fn &rest args)
  "In collection COLL, at location KEY, apply FN with extra args ARGS.
'Updates' a value in an associative collection COLL, where KEY is
a key and FN is a function that will take the old value and any
supplied args and return the new value, and returns a new
structure. If the key does not exist, nil is passed as the old
value."
  (a-assoc-1 coll
             key
             (apply #'funcall fn (a-get coll key) args)))

(defun a-update-in (coll keys fn &rest args)
  "In collection COLL, at location KEYS, apply FN with extra args ARGS.
'Updates' a value in a nested associative collection COLL, where
KEYS is a sequence of keys and FN is a function that will take
the old value and any supplied ARGS and return the new value, and
returns a new nested structure. If any levels do not exist,
association lists will be created."
  (case (length keys)
    (0 coll)
    (1 (apply #'a-update coll (elt keys 0) fn args))
    (t (a-assoc-1 coll
                  (elt keys 0)
                  (apply #'a-update-in
                         (a-get coll (elt keys 0))
                         (seq-drop keys 1)
                         fn
                         args)))))

(provide 'a)
;;; a.el ends here
