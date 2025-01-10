;;  __        __             __   ___
;; |__)  /\  /  ` |__/  /\  / _` |__
;; |    /~~\ \__, |  \ /~~\ \__> |___
;;                      __   ___        ___      ___
;; |\/|  /\  |\ |  /\  / _` |__   |\/| |__  |\ |  |
;; |  | /~~\ | \| /~~\ \__> |___  |  | |___ | \|  |
(when (>= emacs-major-version 24)
  (require 'package)
  (package-initialize)
  (setq package-archives '(("gnu"   . "http://mirrors.tuna.tsinghua.edu.cn/elpa/gnu/")
			   ("melpa" . "http://mirrors.tuna.tsinghua.edu.cn/elpa/melpa/"))))

;; cl - Common Lisp Extension
(require 'cl)

;; Add Packages
(defvar my/packages '(
		      ;; --- Auto-completion ---
		      company
		      ;;company-go
                      posframe
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
                      osx-dictionary
		      ;;jedi
		      magit
		      iedit
                      pyim
                      pyim-basedict
                      ox-hugo
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
                      golint
		      ;; --- Themes ---
                      rainbow-delimiters
                      ;; --- org-roam
                      ;;emacsql
                      ;;emacsql-sqlite
                      magit-section
		      ) "Default packages" )

(setq package-selected-packages my/packages)

(defun my/packages-installed-p ()
  (cl-loop for pkg in my/packages
	when (not (package-installed-p pkg)) do (cl-return nil)
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


