
;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.
;;(package-initialize)

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages (quote (magit company))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
;; auto-complete自动补全
;;(add-to-list 'load-path "~/.emacs.d/lisp")
;;(require 'auto-complete-config)
;;(add-to-list 'ac-dictionary-directories  "~/.emacs.d/ac-dict")
;;(ac-config-default)			

;; package.el 相關設定
(require 'package)
(package-initialize)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("melpa-stable" . "http://stable.melpa.org/packages/") t)

;;
(when (not (require 'company nil :noerror))
  (message "install company now...")
  (setq url-http-attempt-keepalives nil)
  (package-refresh-contents)
    (package-install 'company))

(add-hook 'after-init-hook 'global-company-mode)
'(company-show-numbers t)
;;org-code
(setq org-src-fontify-natively t)

;; all backups goto ~/.backups instead in the current directory
(setq backup-directory-alist (quote (("." . "~/.emacs-backups"))))

;; replace inset buffer as ibuffer
(require 'ibuffer)
(global-set-key (kbd "C-x C-b") 'ibuffer)

;; category buffer
(setq ibuffer-saved-filter-groups
      (quote (("default"
	       ("Dired" (mode . dired-mode))
	       ("Markdown" (or
			    (name . "^diary$")
			    (mode . markdown-mode)))
	       ("ReStructText" (mode . rst-mode))
	       ("Python" (or (mode . python-mode)
			     (mode . ipython-mode)
			     (mode . inferior-python-mode)))
	       ("Ruby" (or
			(mode . ruby-mode)
			(mode . enh-ruby-mode)
			(mode . inf-ruby-mode)))))))
;; Python配置
(defun my-python-mode-config ()
  (setq python-indent-offset 4
	python-indent 4
	indent-tabs-mode nil
	default-tab-width 4

	;; 设置 run-python 的参数
	python-shell-interpreter "ipython"
	python-shell-interpreter-args "-i"
	python-shell-prompt-regexp "In \\[[0-9]+\\]: "
	python-shell-prompt-output-regexp "Out\\[[0-9]+\\]: "
	python-shell-completion-setup-code "from IPython.core.completerlib import module_completion"
	python-shell-completion-module-string-code "';'.join(module_completion('''%s'''))\n"
	python-shell-completion-string-code "';'.join(get_ipython().Completer.all_completions('''%s'''))\n")

  ;; 一键执行python
  (define-key python-mode-map (kbd "<f5>") 'run-buffer-with-python3-interpreter)
  (defun run-buffer-with-python3-interpreter ()
	(interactive)
	(save-buffer)
	(shell-command (format "python3 %s" (file-name-nondirectory buffer-file-name)))
	)

  (add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
  (highlight-indentation-mode t)        ;高亮代码块
  (hs-minor-mode t)                     ;开启 hs-minor-mode 以支持代码折叠
  (auto-fill-mode 0)                    ;关闭 auto-fill-mode，拒绝自动折行
;;(whitespace-mode t)                   ;开启 whitespace-mode 对制表符和行为空格高亮
;;(hl-line-mode t)                      ;开启 hl-line-mode 对当前行进行高亮
  (pretty-symbols-mode t)               ;开启 pretty-symbols-mode 将 lambda 显示成希腊字符 λ
  (set (make-local-variable 'electric-indent-mode) nil)) ;关闭自动缩进

(add-hook 'python-mode-hook 'my-python-mode-config)
;; run-python 的时候，python shell 里显示一堆乱码
(setenv "IPY_TEST_SIMPLE_PROMPT" "1")

;; 设置行号
(global-linum-mode 1) ; always show line numbers
(setq linum-format "%d ")  ;set format

;; 设置加载路径
(push "~/.emacs.d/packages" load-path)

;; 代码块区分
;; https://github.com/antonj/Highlight-Indentation-for-Emacs
(require 'highlight-indentation)

(set-face-background 'highlight-indentation-face "#e3e3d3")
(set-face-background 'highlight-indentation-current-column-face "#c3b3b3")

