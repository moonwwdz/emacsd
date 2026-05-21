;;  __        __             __   ___
;; |__)  /\  /  ` |__/  /\  / _` |__
;; |    /~~\ \__, |  \ /~~\ \__> |___
;;                      __   ___        ___      ___
;; |\/|  /\  |\ |  /\  / _` |__   |\/| |__  |\ |  |
;; |  | /~~\ | \| /~~\ \__> |___  |  | |___ | \|  |
(when (>= emacs-major-version 24)
  (require 'package)
  (package-initialize)
  (setq package-archives '(("gnu"   . "https://mirrors.ustc.edu.cn/elpa/gnu/")
			   ("melpa" . "https://mirrors.ustc.edu.cn/elpa/melpa/"))))

;; cl - Common Lisp Extension
(require 'cl-lib)

;; Add Packages
(defvar my/packages '(
		      ;; --- Auto-completion ---
		      company
                      posframe
		      ;; --- Better Editor ---
		      hungry-delete
		      swiper
		      counsel
		      smartparens
		      expand-region
		      popwin
		      pyvenv
                      osx-dictionary
		      magit
		      iedit
                      pyim
                      pyim-basedict
                      ox-hugo
		      ;; --- Major Mode ---
		      js2-mode
		      web-mode
		      markdown-mode
		      go-mode
                      rust-mode
		      ;; --- Minor Mode ---
		      exec-path-from-shell
                      flycheck
		      ;; --- Themes ---
                      rainbow-delimiters
                      magit-section
                      persist
		      ) "Default packages" )

(setq package-selected-packages my/packages)

(defun my/packages-installed-p ()
  (cl-loop for pkg in my/packages
	when (not (package-installed-p pkg)) do (cl-return nil)
	finally (cl-return t)))

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


