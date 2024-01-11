;;
(setq default-tab-width 4)

;; 快速删除多个空格
(require 'hungry-delete)
(global-hungry-delete-mode)

;; smartparens与hungry-delete冲突解决
(defadvice hungry-delete-backward (before sp-delete-pair-advice activate) (save-match-data (sp-delete-pair (ad-get-arg 0))))
(electric-pair-mode 1)

;; 补全括号、引号
(require 'smartparens-config)
(smartparens-global-mode t)

;; config js2-mode for js files
(setq auto-mode-alist
      (append
       '(("\\.js\\'" . js2-mode)
	 ("\\.html\\'" . web-mode))
          auto-mode-alist))
;; 搜索增强
(ivy-mode 1)
(setq ivy-use-virtual-buffers t)

;; 打开新窗口后，光标自动切换到新窗口
(require 'popwin)
(popwin-mode t)

;; 打开当前文件的driect
(require 'dired-x)
(setq dired-dwim-target t)

;; 取消自动生成备份文件
(setq make-backup-files nil)

(require 'org)
(setq org-src-fontify-natively t)

;; 打开最近文件列表
(require 'recentf)
(recentf-mode 1)
(setq recentf-max-menu-items 25)

;; 显示对应的括号、引号
(show-paren-mode t)

;; 自动加载文件在其它地方修改的内容
(global-auto-revert-mode 1)

;;取消提示音
(setq ring-bell-function 'ignore)
(setq visible-bell t)

;;粘贴到光标位置而不是鼠标位置
(setq mouse-yank-at-point t)

;; 快速确认
(fset 'yes-or-no-p 'y-or-n-p)

;; 快捷补全
(abbrev-mode t)
(define-abbrev-table 'global-abbrev-table '(
                                            ;; moonwwdz
                                            ("5mo" "moonwwdz")
                                            ;; other
                                            ;;
                                            ))

;; buffer 增强
(require 'ibuffer)
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
;;设置缩进
(setq default-tab-width 4)
(setq-default indent-tabs-mode nil)
(setq c-basic-offset 4)

;; python配置 f5 执行当前脚本
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
    (shell-command (format "python3 %s" (file-name-nondirectory buffer-file-name))))

  (add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
  (highlight-indentation-mode t)        ;高亮代码块
  (hs-minor-mode t)                     ;开启 hs-minor-mode 以支持代码折叠
  (auto-fill-mode 0)                    ;关闭 auto-fill-mode，拒绝自动折行
  ;;(whitespace-mode t)                   ;开启 whitespace-mode 对制表符和行为空格高亮
  (pretty-symbols-mode t)               ;开启 pretty-symbols-mode 将 lambda 显示成希腊字符 λ
  (set (make-local-variable 'electric-indent-mode) nil)) ;关闭自动缩进

;; 打开python文件时自动执行
(add-hook 'python-mode-hook 'pipenv-mode)            
(add-hook 'python-mode-hook 'my-python-mode-config)
;;(add-hook 'python-mode-hook 'jedi:install-server)   ;;自动补全
;;(add-hook 'python-mode-hook 'jedi:setup)

;;(setq jedi:complete-on-dot t)

;; run-python 的时候，python shell 里显示一堆乱码
(setenv "IPY_TEST_SIMPLE_PROMPT" "1")

;;去除打开windows文件时显示的`^M`
(defun remove-dos-eol ()
  "Replace DOS eolns CR LF with Unix eolns CR"
  (interactive)
  (goto-char (point-min))
  (while (search-forward "\r" nil t) (replace-match "")))

;;增强web
(defun my-web-mode-indent-setup ()
  (setq web-mode-markup-indent-offset 2) ; web-mode, html tag in html file
  (setq web-mode-css-indent-offset 2)    ; web-mode, css in html file
  (setq web-mode-code-indent-offset 2)   ; web-mode, js code in html file
  )

(add-hook 'web-mode-hook 'my-web-mode-indent-setup)

(defun my-toggle-web-indent ()
  (interactive)
  ;; web development
  (if (or (eq major-mode 'js-mode) (eq major-mode 'js2-mode))
      (progn
	(setq js-indent-level (if (= js-indent-level 2) 4 2))
	(setq js2-basic-offset (if (= js2-basic-offset 2) 4 2))))

  (if (eq major-mode 'web-mode)
      (progn (setq web-mode-markup-indent-offset (if (= web-mode-markup-indent-offset 2) 4 2))
	     (setq web-mode-css-indent-offset (if (= web-mode-css-indent-offset 2) 4 2))
	     (setq web-mode-code-indent-offset (if (= web-mode-code-indent-offset 2) 4 2))))
  (if (eq major-mode 'css-mode)
      (setq css-indent-offset (if (= css-indent-offset 2) 4 2)))

  (setq indent-tabs-mode nil))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;增强查找后统一编辑(跳转后查找内容不关闭)功能
;; 抓取光标所在位置的单词
(defun occur-dwim ()
  "Call `occur' with a sane default."
  (interactive)
  (push (if (region-active-p)
	    (buffer-substring-no-properties
	     (region-beginning)
	     (region-end))
	  (let ((sym (thing-at-point 'symbol)))
	    (when (stringp sym)
	      (regexp-quote sym))))
	regexp-history)
  (call-interactively 'occur))

(defun js2-imenu-make-index ()
      (interactive)
      (save-excursion
        ;; (setq imenu-generic-expression '((nil "describe\\(\"\\(.+\\)\"" 1)))
        (imenu--generic-function '(("describe" "\\s-*describe\\s-*(\\s-*[\"']\\(.+\\)[\"']\\s-*,.*" 1)
                                   ("it" "\\s-*it\\s-*(\\s-*[\"']\\(.+\\)[\"']\\s-*,.*" 1)
                                   ("test" "\\s-*test\\s-*(\\s-*[\"']\\(.+\\)[\"']\\s-*,.*" 1)
                                   ("before" "\\s-*before\\s-*(\\s-*[\"']\\(.+\\)[\"']\\s-*,.*" 1)
                                   ("after" "\\s-*after\\s-*(\\s-*[\"']\\(.+\\)[\"']\\s-*,.*" 1)
                                   ("Function" "function[ \t]+\\([a-zA-Z0-9_$.]+\\)[ \t]*(" 1)
                                   ("Function" "^[ \t]*\\([a-zA-Z0-9_$.]+\\)[ \t]*=[ \t]*function[ \t]*(" 1)
                                   ("Function" "^var[ \t]*\\([a-zA-Z0-9_$.]+\\)[ \t]*=[ \t]*function[ \t]*(" 1)
                                   ("Function" "^[ \t]*\\([a-zA-Z0-9_$.]+\\)[ \t]*()[ \t]*{" 1)
                                   ("Function" "^[ \t]*\\([a-zA-Z0-9_$.]+\\)[ \t]*:[ \t]*function[ \t]*(" 1)
                                   ("Task" "[. \t]task([ \t]*['\"]\\([^'\"]+\\)" 1)))))
(add-hook 'js2-mode-hook
              (lambda ()
                (setq imenu-create-index-function 'js2-imenu-make-index)))










(provide 'init-better-default)
