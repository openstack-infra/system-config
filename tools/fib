#!/usr/bin/guile \
-e main -s
!#

;; Copyright (c) 2013, Hengqing Hu <hudayou@hotmail.com>
;;
;; Licensed under the Apache License, Version 2.0 (the "License"); you may
;; not use this file except in compliance with the License. You may obtain
;; a copy of the License at
;;
;;      http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
;; WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
;; License for the specific language governing permissions and limitations
;; under the License.

;; Find identical code blocks in a file(directory).

(define nil '())

(define exit-status 0)

;; block-size-range is a range specify the size of the code block:
;; (min-block-size max-block-size)
;; A file with n lines have
;; (max-block-size - min-block-size + 1) * n -
;; (fold + 0 (enumerate min-block-size - 1 max-block-size - 1))
;; blocks.
;; (define block-size-range (list 4 12))
(define min-block-size 5)
(define max-block-size 67)

;; The minimum times of a block is repated in the file.
(define min-repeat-factor 2)

;; The maximum times of a block is repated in the file.
(define max-repeat-factor 64)

;; Cross find identical blocks in all files?
(define cross-find #f)

;; How a code block record looks like?
;; A vector looks like below:
;; #(path-to-file start-line end-line)

(define (make-block path-to-file start-line end-line)
  (vector
    path-to-file
    start-line
    end-line))

(define (block-path block)
  (vector-ref block 0))

(define (block-start block)
  (vector-ref block 1))

(define (block-end block)
  (vector-ref block 2))

(define (block-size block)
  (if (pair? block)
    (block-size (car block))
    (+ 1 (- (block-end block) (block-start block)))))

(define (block-content block)
  (let ((bsize (block-size block))
        (bpath (block-path block))
        (bstart (block-start block)))
    (string-join
      (list-head
        (list-tail (read-lines bpath) (- bstart 1))
        bsize)
      delimiter-string)))

(define (block-overlaps? block1 block2)
  (or
    (and (>= (block-start block1) (block-start block2))
         (<= (block-end block1) (block-end block2))
         (string=? (block-path block1) (block-path block2)))
    (and (<= (block-start block1) (block-start block2))
         (>= (block-end block1) (block-end block2))
         (string=? (block-path block1) (block-path block2)))))

;; A block list is a list of blocks with same content

(define (block-list-overlaps? lst1 lst2)
  (if (and (null? lst1) (null? lst2))
    #t
    (and (= (length lst1) (length lst2))
         (block-overlaps? (car lst1) (car lst2))
         (block-list-overlaps? (cdr lst1) (cdr lst2)))))

;; The algorithm:
;; Build blocks from the file, insert list of identical blocks
;; in a hash table keyed by the string hash of the content of the block.
;; (Note blocks which contains blank lines are not inserted.)
;;
;; Remove single blocks, which means they have no companies in the file.
;;
;; Remove list of blocks which overlaps with other list of blocks and
;; have a smaller block size.

(define (enumerate-interval low high)
  (if (> low high)
    nil
    (cons low (enumerate-interval (+ low 1) high))))

(use-modules (ice-9 rdelim))

(define (read-file port)
  (read-delimited "" port))

(define delimiter #\newline)
(define delimiter-string "\n")

(define (read-lines file)
  (string-split
    (string-trim-right
      (call-with-input-file file read-file)
      delimiter)
    delimiter))

;; A fold operation, use fold instead?
(define (and-filters filters param)
  (if (null? filters)
    #t
    (and ((car filters) param)
         (and-filters (cdr filters) param))))

;; defaults to accept any block
;; as an example, you can use the following cmd line to search a list
;; block in a yaml file:
;; fib -s "^\\s+[-a-z]+:\\s*[|>]*\\s*$" -e "^\\s+[.a-z].*$") -f file

;; accept any start-line
(define start-line-regexp ".*")
;; accept any end-line
(define end-line-regexp ".*")

;; filter start-line and end-line by regular expression
(define (se-filter list-of-lines)
  (let ((start-line (list-ref list-of-lines 0))
        (end-line (list-ref list-of-lines (- (length list-of-lines) 1))))
    (if (and (string-match start-line-regexp start-line)
             (string-match end-line-regexp end-line))
      #t
      #f)))

(define (continous-filter list-of-lines)
  (if (member "" list-of-lines) #f #t))

(define (empty-filter list-of-lines)
  #t)

(define block-filters (list continous-filter se-filter))

(define (remove-single-blocks hash-table)
  (for-each
    (lambda (x)
      (let ((block-length (length (cdr x))))
        (if (or (< block-length min-repeat-factor)
                (> block-length max-repeat-factor))
          (hash-remove! hash-table (car x)))))
    (hash-map->list cons hash-table))
  hash-table)

(define block-hash-table (make-hash-table))

(define (hash-block list-of-lines)
  (string-hash
    (string-join
      list-of-lines
      delimiter-string)))

(define (build-block-hash-table file hash-table)
  (define list-of-lines (read-lines file))
  (define (build-hash-table line-list start-line)
    (if (< (length line-list) min-block-size)
      hash-table
      (begin
        (update-hash-table line-list start-line)
        (build-hash-table (cdr line-list) (+ start-line 1)))))
  (define (update-hash-table line-list start-line)
    (for-each
      (lambda (x)
        (let* ((b-key (car x))
               (b (cdr x))
               (b-value (hash-ref hash-table b-key)))
          (if b-value
            (hash-set! hash-table b-key (cons b b-value))
            (hash-set! hash-table b-key (list b)))))
      (build-blocks line-list start-line)))
  (define (filter-block-content list-of-lines)
    (and-filters block-filters list-of-lines))
  (define (build-blocks line-list start-line)
    (filter pair?
            (map
              (lambda (bsize)
                (let ((list-of-lines (list-head line-list bsize)))
                  (if (filter-block-content list-of-lines)
                    (cons (hash-block list-of-lines)
                          (make-block
                            file
                            start-line
                            (+ start-line bsize -1))))))
              (enumerate-interval min-block-size
                                  (let ((no-of-lines (length line-list)))
                                    (if (< no-of-lines max-block-size)
                                      no-of-lines
                                      max-block-size))))))
  (build-hash-table list-of-lines 1))

(define (hash-empty? hash-table)
  (eq? (hash-map->list cons hash-table) nil))

(define (remove-duplicate-entries hash-table)
  (define (remove-overlaps k1 v1)
    (for-each
      (lambda (x)
        (let* ((k2 (car x))
               (v2 (cdr x))
               (s2 (block-size v2))
               (s1 (block-size v1)))
          (if (block-list-overlaps? v1 v2)
            (if (< s2 s1)
              (hash-remove! hash-table k2)))))
      (hash-map->list cons hash-table)))
  ;; prove by contradiction
  ;; since for each block list, block lists overlaps
  ;; with it and have a smaller block size is removed.
  ;;
  ;; if there is such a block that overlaps with other,
  ;; two cases:
  ;; the other block have a smaller size, then it should be removed already.
  ;; otherwise, the block itself should already be removed.
  (for-each
    (lambda (x)
      (remove-overlaps (car x) (cdr x)))
    (hash-map->list cons hash-table))
  hash-table)

(define (eat-blocks hash-table)
  (remove-duplicate-entries
    (remove-single-blocks hash-table)))

(define (pretty-show hash-table)
  (define (footprint x)
    (display x)
    (newline))
  (hash-for-each
    (lambda (k v)
      (display "Block footprint:")
      (newline)
      (if (> (length v) 2)
        (begin
          (for-each footprint (list-head v 2))
          (display (- (length v) 2))
          (display " more ..")
          (newline))
        (for-each footprint v))
      (display "Block content:")
      (newline)
      (display (block-content (car v)))
      (newline)
      (newline))
    hash-table))

(define (display-blocks hash-table)
  (if (not (hash-empty? hash-table))
    (begin
      (set! exit-status 1)
      (pretty-show
        (eat-blocks hash-table)))))

(define (find-identical-blocks file)
  (build-block-hash-table file block-hash-table)
  (if (not cross-find)
    (begin
      (display-blocks block-hash-table)
      (hash-clear! block-hash-table))))

(use-modules (ice-9 popen))

(define (command-output command)
  (let* ((port (open-input-pipe command))
         (str (read-line port)))
    (close-pipe port)
    str))

(define (wrapper-of-fib file stat flag)
  (define is-text-file (string-append "file -bi " file))
  (if (and (eq? flag `regular)
           ;; skip hidden files
           (not (string-contains file "/."))
           (string-prefix?
             "text/"
             (command-output is-text-file)))
    (find-identical-blocks file))
  #t)

(use-modules (ice-9 ftw))

(define (fib file)
  (for-each
    (lambda (f)
      (ftw f wrapper-of-fib))
    (string-split
      (string-trim-both
        file
        (lambda (c)
          (or (eq? c #\space)
              (eq? c #\tab)
              (eq? c #\return)
              (eq? c #\newline)
              (eq? c #\vt)
              (eq? c #\np))))
      #\space))
  (if cross-find
    (display-blocks block-hash-table)))

(use-modules (ice-9 regex))

(use-modules (ice-9 getopt-long))

(define (main args)
  (let* ((option-spec '((help (single-char #\h) (value #f))
                        (file (single-char #\f) (value #t))
                        (start-line-regexp (single-char #\s) (value #t))
                        (end-line-regexp (single-char #\e) (value #t))
                        (cross-find (single-char #\x) (value #f))
                        (min-size (value #t))
                        (max-size (value #t))
                        (min-factor (value #t))
                        (max-factor (value #t))))
         (options (getopt-long args option-spec))
         (help-wanted
           (option-ref options 'help #f))
         (file
           (option-ref options 'file #f))
         (srex
           (option-ref options 'start-line-regexp start-line-regexp))
         (erex
           (option-ref options 'end-line-regexp end-line-regexp))
         (xfind
           (option-ref options 'cross-find #f))
         (min-size
           (option-ref options 'min-size min-block-size))
         (max-size
           (option-ref options 'max-size max-block-size))
         (min-factor
           (option-ref options 'min-factor min-repeat-factor))
         (max-factor
           (option-ref options 'max-factor max-repeat-factor)))
    (if (or help-wanted (not file))
      (begin
        (display "fib [options] -f file\n")
        (display "-h, --help               Display this help\n")
        (display "-f, --file               Find identical blocks in this file\n")
        (display "-s, --start-line-regexp  Regular expression for the first line of the block\n")
        (display "-e, --end-line-regexp    Regular expression for the last line of the block\n")
        (display "-x, --cross-find         Cross find blocks in all files\n")
        (display "--min-size               Minimal size of the block\n")
        (display "--max-size               Maximal size of the block\n")
        (display "--min-factor             Minimal times a block is repeated\n")
        (display "--max-factor             Maximal times a block is repeated\n"))
      (begin
        (if (not (equal? srex start-line-regexp))
          (set! start-line-regexp srex))
        (if (not (equal? erex end-line-regexp))
          (set! end-line-regexp erex))
        (if xfind
          (set! cross-find #t))
        (if (and (not (equal? min-size min-block-size))
                 (integer? (string->number min-size)))
          (set! min-block-size (string->number min-size)))
        (if (and (not (equal? max-size max-block-size))
                 (integer? (string->number max-size)))
          (set! max-block-size (string->number max-size)))
        (if (and (not (equal? min-factor min-repeat-factor))
                 (integer? (string->number min-factor)))
          (set! min-repeat-factor (string->number min-factor)))
        (if (and (not (equal? max-factor max-repeat-factor))
                 (integer? (string->number max-factor)))
          (set! max-repeat-factor (string->number max-factor)))
        (fib file))))
  (exit exit-status))
