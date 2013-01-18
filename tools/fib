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

;; The maximum no of lines in the file.
(define max-no-of-lines 20000)

;; Cross find identical blocks in all files?
(define cross-find #f)

;; Find identical blocks introduced by difference between
;; commit and HEAD(git only)
(define diff-commit #f)

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

(define (block-interval block)
  (make-interval (block-start block)
                 (block-end block)))

(define (block-includes? block1 block2)
  (or
    (and (>= (block-start block1) (block-start block2))
         (<= (block-end block1) (block-end block2))
         (string=? (block-path block1) (block-path block2)))
    (and (<= (block-start block1) (block-start block2))
         (>= (block-end block1) (block-end block2))
         (string=? (block-path block1) (block-path block2)))))

;; A block list is a list of blocks with same content

(define (block-list-includes? lst1 lst2)
  (if (and (null? lst1) (null? lst2))
    #t
    (and (= (length lst1) (length lst2))
         (block-includes? (car lst1) (car lst2))
         (block-list-includes? (cdr lst1) (cdr lst2)))))

;; An interval is a pair
;; (low . high)
(define (make-interval low high) (cons low high))

(define (interval-low interval) (car interval))

(define (interval-high interval) (cdr interval))

(define (interval-overlaps? interval1 interval2)
  (let ((low1 (interval-low interval1))
        (high1 (interval-high interval1))
        (low2 (interval-low interval2))
        (high2 (interval-high interval2)))
    (and (<= low1 high2)
         (<= low2 high1))))

;; be clear what less means for compound data keys
;; keys are distinct, so when low parts of them are the same,
;; order them by the high parts.
(define (interval-less? interval1 interval2)
  (let ((low1 (interval-low interval1))
        (low2 (interval-low interval2))
        (high1 (interval-high interval1))
        (high2 (interval-high interval2)))
    (if (= low1 low2)
      (< high1 high2)
      (< low1 low2))))

;; An node is a list
;; (key priority data value)
(define (make-node key priority data value)
  (list key priority data value))

(define (node-key node) (car node))

(define (node-priority node) (cadr node))

(define (node-data node) (caddr node))

(define (node-value node) (cadddr node))

;; A tree is list
;; (node left right)
(define (make-tree node left right)
  (list node left right))

(define (tree-node tree) (car tree))

(define (tree-left tree) (cadr tree))

(define (tree-right tree) (caddr tree))

(define (priority-less? tree1 tree2)
  (let ((priority1 (node-priority (tree-node tree1)))
        (priority2 (node-priority (tree-node tree2))))
    (< priority1 priority2)))

;; ops on the hash tree

(define (hash-search hash tree)
  (if (null? tree)
    #f
    (let ((node (tree-node tree))
          (left (tree-left tree))
          (right (tree-right tree)))
      (let ((k (node-key node)))
        (cond ((< hash k)
               (hash-search hash left))
              ((= hash k)
               #t)
              (else
                (hash-search hash right)))))))

(define (hash-insert hash tree)
  (treap-insert
    hash
    (time-priority)
    1
    nil
    tree
    <
    hash-update-data))

(define (hash-update-data tree)
  (define (tree-data tree)
    (if (null? tree)
      0
      (node-data (tree-node tree))))
  (treap-update-data
    tree
    (lambda (tree left right)
      (+ (tree-data left)
         (tree-data right)
         1))))

(define (hash-size tree)
  (if (null? tree)
    0
    (node-data (tree-node tree))))

;; ops on the interval tree

(define (node-overlaps-interval? node interval)
  (interval-overlaps? (node-key node) interval))

(define (tree-overlaps-interval? tree interval)
  (if (null? tree)
    #f
    (let ((data (node-data (tree-node tree)))
          (low (interval-low interval)))
      (>= data low))))

(define (interval-update-data tree)
  (define (tree-data tree)
    (if (null? tree)
      -inf.0
      (node-data (tree-node tree))))
  (treap-update-data
    tree
    (lambda (tree left right)
      (max (interval-high (node-key (tree-node tree)))
           (tree-data left)
           (tree-data right)))))

(define (interval-traverse-search interval tree combine init)
  (define (search-to-result tree result)
    (if (null? tree)
      result
      (let ((node (tree-node tree))
            (left (tree-left tree))
            (right (tree-right tree)))
        (let ((value (node-value node)))
          (if (node-overlaps-interval? node interval)
            (if (tree-overlaps-interval? left interval)
              (search-to-result left
                                (combine value
                                         (search-to-result right result)))
              (search-to-result right (combine value result)))
            (if (tree-overlaps-interval? left interval)
              (search-to-result left
                                (search-to-result right result))
              (search-to-result right result)))))))
  (search-to-result tree init))

(define (interval-insert interval value tree)
  (treap-insert
    interval
    (random-priority)
    (interval-high interval)
    value
    tree
    interval-less?
    interval-update-data))

;; random and time priority

(define (random-priority)
  (random:uniform))

(define (time-priority)
  (let ((time (gettimeofday)))
    (let ((second (car time))
          (microsecond (cdr time)))
      (- (+ (* second 1000000) microsecond)))))

;; ops on the treap

(define (treap-insert key priority data value tree key-less? update-data)
  (define (fixup tree)
    (let ((node (tree-node tree))
          (left (tree-left tree))
          (right (tree-right tree)))
      (cond ((and (null? left) (null? right))
             tree)
            ((null? left)
             (if (priority-less? tree right)
               (let ((left-of-right (tree-left right))
                     (right-of-right (tree-right right))
                     (node-of-right (tree-node right)))
                 (update-data
                   (make-tree
                     node-of-right
                     (update-data
                       (make-tree
                         node
                         nil
                         left-of-right))
                     right-of-right)))
               (update-data tree)))
            ((null? right)
             (if (priority-less? tree left)
               (let ((left-of-left (tree-left left))
                     (right-of-left (tree-right left))
                     (node-of-left (tree-node left)))
                 (update-data
                   (make-tree
                     node-of-left
                     left-of-left
                     (update-data
                       (make-tree
                         node
                         right-of-left
                         nil)))))
               (update-data tree)))
            (else
              (let ((left-of-right (tree-left right))
                    (right-of-right (tree-right right))
                    (node-of-right (tree-node right))
                    (left-of-left (tree-left left))
                    (right-of-left (tree-right left))
                    (node-of-left (tree-node left)))
                (cond ((priority-less? tree left)
                       (update-data
                         (make-tree
                           node-of-left
                           left-of-left
                           (update-data
                             (make-tree
                               node
                               right-of-left
                               right)))))
                      ((priority-less? tree right)
                       (update-data
                         (make-tree
                           node-of-right
                           (update-data
                             (make-tree
                               node
                               left
                               left-of-right))
                           right-of-right)))
                      (else
                        (update-data tree))))))))
  (define (insert key value tree)
    (if (null? tree)
      (make-tree
        (make-node key
                   priority
                   data
                   value)
        nil
        nil)
      (let ((node (tree-node tree))
            (left (tree-left tree))
            (right (tree-right tree)))
        (let ((k (node-key node)))
          (cond ((key-less? key k)
                 (fixup
                   (make-tree node
                              (insert key value left)
                              right)))
                ;; swallow duplicate insertions
                ((equal? key k)
                 tree)
                ;; flip a coin to decide to go left or right,
                ;; if only part of k and key equals?
                (else
                  (fixup
                    (make-tree node
                               left
                               (insert key value right)))))))))
  (insert key value tree))

;; data in a treap is something depends on the root, left and right.
;; when any of the three is changed, it should be updated.
(define (treap-update-data tree update-proc)
  (define (update-node-data node data)
    (let ((key (node-key node))
          (priority (node-priority node))
          (value (node-value node)))
      (make-node key priority data value)))
  (if (null? tree)
    tree
    (let ((node (tree-node tree))
          (left (tree-left tree))
          (right (tree-right tree)))
      (make-tree
        (update-node-data node
                          (update-proc tree
                                       left
                                       right))
        left
        right))))

;; The algorithm:
;; Build blocks from the file, insert list of identical blocks
;; in a hash table keyed by the string hash of the content of the block.
;; (Note blocks which contains blank lines are not inserted.)
;;
;; Remove single blocks, which means they have no companies in the file.
;;
;; Remove list of blocks which are included in other list of blocks and
;; have a smaller block size.

(define (enumerate-interval low high)
  (let loop ((i high)
             (interval nil))
    (if (< i low)
      interval
      (loop (- i 1) (cons i interval)))))

(use-modules (ice-9 rdelim))

(define (read-all port)
  (read-delimited "" port))

(define delimiter #\newline)
(define delimiter-string "\n")

(define (split-lines lines)
  (string-split
    (string-trim-right
      lines
      delimiter)
    delimiter))

(define (read-lines file)
  (split-lines
    (call-with-input-file file read-all)))

;; A fold operation, use fold instead?
(define (and-filters filters param)
  (if (null? filters)
    #t
    (and ((car filters) param)
         (and-filters (cdr filters) param))))

;; defaults to accept any block
;; as an example, you can use the following cmd line to search a list
;; block in a yaml file:
;; fib -s "^\\s+[-a-z]+:\\s*[|>]*\\s*$" -e "^\\s+[.a-z].*$" -f file

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
      (let ((repeat-factor (length (cdr x))))
        (if (or (< repeat-factor min-repeat-factor)
                (> repeat-factor max-repeat-factor))
          (hash-remove! hash-table (car x)))))
    (hash-map->list cons hash-table))
  hash-table)

(define block-hash-table (make-hash-table))

(define (hash-block list-of-lines)
  (string-hash
    (string-join
      list-of-lines
      delimiter-string)))

(define (expected-no-of-lines? no-of-lines)
  (and (< max-no-of-lines no-of-lines)
       (< min-block-size no-of-lines)))

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
  (if (expected-no-of-lines? (length list-of-lines))
    hash-table
    (build-hash-table list-of-lines 1)))

(define (hash-empty? hash-table)
  (= (hash-length hash-table) 0))

;; read syntax of a hash table is:
;; #<hash-table 0/31>
(define (hash-length hash-table)
  (string->number
    (cadr
      (string-split
        (car
          (string-split
            (object->string hash-table)
            #\/))
        #\sp))))

(define (remove-sub-blocks hash-table)
  (define (remove-includes k1 v1)
    (for-each
      (lambda (x)
        (let* ((k2 (car x))
               (v2 (cdr x))
               (s2 (block-size v2))
               (s1 (block-size v1)))
          (if (block-list-includes? v1 v2)
            (if (< s2 s1)
              (hash-remove! hash-table k2)))))
      (hash-map->list cons hash-table)))
  ;; prove by contradiction
  ;; since for each block list, block lists included
  ;; in it and have a smaller block size is removed.
  ;;
  ;; if there is such a block that is included in other block,
  ;; two cases:
  ;; the other block have a smaller size, then it should be removed already.
  ;; otherwise, the block itself should already be removed.
  (for-each
    (lambda (x)
      (remove-includes (car x) (cdr x)))
    (hash-map->list cons hash-table))
  hash-table)

(define (eat-blocks hash-table)
  (remove-sub-blocks
    (remove-single-blocks hash-table)))

;; remove blocks which unrelated with blocks in list-of-blocks from
;; hash-table
(define (remove-unrelated-blocks list-of-blocks hash-table)
  (define hash-table-size (hash-length hash-table))
  (define (build-interval-tree-table hash-table)
    (let ((interval-tree-table (make-hash-table)))
      (hash-for-each
        (lambda (hash-of-block block-list)
          (for-each
            (lambda (b)
              (let* ((hash-of-path (string-hash (block-path b)))
                     (interval-tree (hash-ref interval-tree-table
                                              hash-of-path)))
                (if interval-tree
                  (hash-set! interval-tree-table hash-of-path
                             (interval-insert (block-interval b)
                                              hash-of-block
                                              interval-tree))
                  (hash-set! interval-tree-table hash-of-path
                             (interval-insert (block-interval b)
                                              hash-of-block
                                              nil)))))
            block-list))
        hash-table)
      interval-tree-table))
  (define (build-hash-tree list-of-blocks interval-tree-table)
    (let bht ((hash-tree nil)
              (list-of-blocks list-of-blocks))
      (if (null? list-of-blocks)
        hash-tree
        (let* ((b (car list-of-blocks))
               (hash-of-path (string-hash (block-path b)))
               (interval-tree (hash-ref interval-tree-table
                                        hash-of-path))
               (hash-tree-size (hash-size hash-tree)))
          (if (< hash-tree-size hash-table-size)
            (begin
              (if interval-tree
                (set! hash-tree
                  (interval-traverse-search (block-interval b)
                                            interval-tree
                                            hash-insert
                                            hash-tree)))
              (bht hash-tree (cdr list-of-blocks)))
            hash-tree)))))
  (let ((interval-tree-table (build-interval-tree-table hash-table)))
    (let ((hash-tree (build-hash-tree list-of-blocks interval-tree-table)))
      (let ((hash-tree-size (hash-size hash-tree)))
        (if (< hash-tree-size hash-table-size)
          (for-each
            (lambda (x)
              (let ((k (car x)))
                (if (not (hash-search k hash-tree))
                  (hash-remove! hash-table k))))
            (hash-map->list cons hash-table))))))
  hash-table)

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

(define (display-blocks file hash-table)
  (define (show-blocks hash-table)
    (if (not (hash-empty? hash-table))
      (begin
        (set! exit-status 1)
        (pretty-show hash-table))))
  (let ((eated-table (eat-blocks hash-table)))
    (if diff-commit
      (let ((list-of-changed-blocks nil))
        (for-each
          (lambda (file)
            (set! list-of-changed-blocks
              (append list-of-changed-blocks
                      (get-changed-blocks diff-commit file))))
          (get-changed-files diff-commit file))
        (show-blocks
          (remove-unrelated-blocks list-of-changed-blocks
                                   eated-table)))
      (show-blocks eated-table))))

(define (find-identical-blocks file)
  (build-block-hash-table file block-hash-table)
  (if (not cross-find)
    (begin
      (display-blocks file block-hash-table)
      (hash-clear! block-hash-table))))

(use-modules (ice-9 popen))

(define (command-output command)
  (let* ((port (open-input-pipe command))
         (str (read-all port)))
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

(define (fib-in-file file)
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
      #\space)))

;; get changed blocks in a single file
(define (get-changed-blocks diff-commit file)
  (define cmd (string-append "git diff "
                             diff-commit
                             " -U0 "
                             " -- "
                             file))
  (let ((list-of-changed-blocks nil))
    (for-each
      (lambda (line)
        (let ((match-struct
                (string-match
                  "^@@ -[0-9]+(,[0-9]+)? \\+([0-9]+)(,([0-9]+))? @@"
                  line)))
          (if match-struct
            (let* ((bsize (match:substring match-struct 4))
                   (bstart (string->number (match:substring match-struct 2)))
                   (bend (if bsize (+ bstart
                                      (string->number bsize)
                                      -1) bstart)))
              (set! list-of-changed-blocks
                (cons (make-block file bstart bend)
                      list-of-changed-blocks))))))
      (split-lines
        (command-output cmd)))
    list-of-changed-blocks))

(define (get-changed-files diff-commit file)
  (define cmd (string-append "git diff "
                             diff-commit
                             " --name-only "
                             " -- "
                             file))
  (split-lines
    (command-output cmd)))

(define (fib file)
  (if diff-commit
    ;; process changed files only
    (let ((changed-files (get-changed-files diff-commit file)))
      (for-each
        fib-in-file
        changed-files))
    (fib-in-file file))
  (if cross-find
    (display-blocks file block-hash-table)))

(use-modules (ice-9 regex))

(use-modules (ice-9 getopt-long))

(define (main args)
  (define (set-no-from-str no str)
    (if (string? str)
      (let ((str-no (string->number str)))
        (if (and (integer? str-no)
                 (not (eqv? no str-no)))
          (set! no str-no))))
    no)
  (define (set-rex-from-str rex str)
    (if (and (string? str)
             (regexp? (make-regexp str))
             (not (equal? rex str)))
      str
      rex))
  (let* ((option-spec '((help (single-char #\h) (value #f))
                        (file (single-char #\f) (value #t))
                        (start-line-regexp (single-char #\s) (value #t))
                        (end-line-regexp (single-char #\e) (value #t))
                        (cross-find (single-char #\x) (value #f))
                        (diff-commit (single-char #\d) (value #t))
                        (max-lines (value #t))
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
           (option-ref options 'start-line-regexp #f))
         (erex
           (option-ref options 'end-line-regexp #f))
         (xfind
           (option-ref options 'cross-find #f))
         (dcommit
           (option-ref options 'diff-commit #f))
         (max-lines
           (option-ref options 'max-lines #f))
         (min-size
           (option-ref options 'min-size #f))
         (max-size
           (option-ref options 'max-size #f))
         (min-factor
           (option-ref options 'min-factor #f))
         (max-factor
           (option-ref options 'max-factor #f)))
    (if (or help-wanted (not file))
      (begin
        (display "fib [options] -f file\n")
        (display "-h, --help               Display this help\n")
        (display "-f, --file               Find identical blocks in this file\n")
        (display "-s, --start-line-regexp  Regular expression for the first line of the block\n")
        (display "-e, --end-line-regexp    Regular expression for the last line of the block\n")
        (display "-x, --cross-find         Cross find blocks in all files\n")
        (display "-d, --diff-commit        Find identical blocks introduced by difference between commit and HEAD(git only)\n")
        (display "--max-lines              Skip file with too many lines\n")
        (display "--min-size               Minimal size of the block\n")
        (display "--max-size               Maximal size of the block\n")
        (display "--min-factor             Minimal times a block is repeated\n")
        (display "--max-factor             Maximal times a block is repeated\n"))
      (begin
        (set! start-line-regexp
          (set-rex-from-str start-line-regexp srex))
        (set! end-line-regexp
          (set-rex-from-str end-line-regexp erex))
        (if xfind
          (set! cross-find #t))
        (set! diff-commit dcommit)
        (set! max-no-of-lines
          (set-no-from-str max-no-of-lines max-lines))
        (set! min-block-size
          (set-no-from-str min-block-size min-size))
        (set! max-block-size
          (set-no-from-str max-block-size max-size))
        (set! min-repeat-factor
          (set-no-from-str min-repeat-factor min-factor))
        (set! max-repeat-factor
          (set-no-from-str max-repeat-factor max-factor))
        (fib file))))
  (exit exit-status))
