;;; git-cat.el --- find and view files in a bare git repository

;; Copyright (C) 2023 Mathias Dahl

;; Maintainer: mathias.dahl@gmail.com
;; Keywords: version control, git

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; I have a number of bare git repositories to which I sync files from
;; and to different computers.  Now and then I need to find and view
;; files when I'm inside a such a repository.  `git-cat' helps with
;; that.

;; To use it, make sure you are in a bare git repository or inside a
;; .git directory, then type `M-x git-cat RET', enter a file name
;; pattern (a regexp) and press RET.  Then select the file to view
;; among the hits.

;; The files will be saved in your temporary directory named with the
;; full path of the file in the repository.  Each slash is replaced by
;; an underscore.  If you want to view the same file again, you will be
;; asked if you want to overwrite the file in the temporary directory.

;;; Todo:

;; - Add support for git grep. Maybe.

;;; Code:

(defun git-cat-ls-tree (pattern)
  "Use git to list files matching PATTERN.
Returns a list of cons cells where the CAR is the file name and
the CDR is the git hash."
  (with-temp-buffer
    (shell-command (format "git ls-tree --full-tree -r HEAD | grep %s" pattern) t)
    (mapcar (lambda (hit)
	      (let ((hit-list (split-string hit "[ \t]")))
		(cons (nth 3 hit-list)
		      (nth 2 hit-list))))
	    (string-lines (buffer-string) t))))

(defun git-cat-prepare-file (file)
  "Prepare the file FILE.  Ask to delete it if it exists."
  (let ((full-name (concat (temporary-file-directory) (replace-regexp-in-string "/" "_" file))))
    (when (file-exists-p full-name)
      (if (y-or-n-p (format "File %s exists, do you want to overwrite it?" full-name))
	  (delete-file full-name)
	(error "Aborted")))
    full-name))

(defun git-cat-in-git-repo ()
  "Check if we are in a bare git repo or .git directory."
  (string-match "^true" (shell-command-to-string "git rev-parse --is-inside-git-dir")))

(defun git-cat (pattern)
  "Open any file in a bare git repository.
Argument PATTERN is a regexp to match the file name on."
  (interactive
   (list
    (if (git-cat-in-git-repo)
	(read-string "File name pattern: ")
      (error "Not in a bare git repository or .git folder"))))
  (let* ((hits (git-cat-ls-tree pattern))
	 (hit (assoc (completing-read "Select file: " hits) hits))
	 (file (git-cat-prepare-file (car hit))))
    (with-temp-buffer
      (shell-command (format "git cat-file -p %s" (cdr hit)) t)
      (write-file file))
    (find-file file)))

(provide 'git-cat)

;;; git-cat.el ends here
