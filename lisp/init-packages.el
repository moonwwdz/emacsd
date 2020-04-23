;;  __        __             __   ___
;; |__)  /\  /  ` |__/  /\  / _` |__
;; |    /~~\ \__, |  \ /~~\ \__> |___
;;                      __   ___        ___      ___
;; |\/|  /\  |\ |  /\  / _` |__   |\/| |__  |\ |  |
;; |  | /~~\ | \| /~~\ \__> |___  |  | |___ | \|  |
(when (>= emacs-major-version 24)
  (require 'package)
  (package-initialize)
  (setq package-archives '(("gnu"   . "http://elpa.emacs-china.org/gnu/")
			   ("melpa" . "http://elpa.emacs-china.org/melpa/"))))

;; cl - Common Lisp Extension
(require 'cl)

;; Add Packages
(defvar my/packages '(
		      ;; --- Auto-completion ---
		      company
		      company-go
		      ;; --- Better Editor ---
		      smooth-scrolling
		      hungry-delete
		      swiper
		      counsel
		      smartparens
		      expand-region
		      popwin
		      pipenv
		      youdao-dictionary
		      jedi
		      magit
		      iedit
		      ;; --- Major Mode ---
		      js2-mode
		      js2-refactor
		      web-mode
		      markdown-mode
		      go-mode
		      ;; --- Minor Mode ---
		      nodejs-repl
		      exec-path-from-shell
		      go-eldoc
		      ;; --- Themes ---
		      ) "Default packages" )

(setq package-selected-packages my/packages)

(defun my/packages-installed-p ()
  (loop for pkg in my/packages
	when (not (package-installed-p pkg)) do (return nil)
	finally (return t)))

(unless (my/packages-installed-p)
  (message "%s" "Refreshing package database...")
  (package-refresh-contents)
  (dolist (pkg my/packages)
    (when (not (package-installed-p pkg))
      (package-install pkg))))

;; Find Executable Path on OS X
(when (memq window-system '(mac ns))
  (exec-path-from-shell-initialize))


;; 文件末尾
(provide 'init-packages)


