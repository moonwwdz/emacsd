;; 全局激活自动补全
(global-company-mode 1)

;; 快速删除多个空格
(require 'hungry-delete)
(global-hungry-delete-mode)

;; 补全括号、引号
(require 'smartparens-config)
(smartparens-global-mode t)

;; config js2-mode for js files
(setq auto-mode-alist
      (append
       '(("\\.js\\'" . js2-mode))
          auto-mode-alist))
;; 搜索增强
(ivy-mode 1)
(setq ivy-use-virtual-buffers t)

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
    (shell-command (format "python3 %s" (file-name-nondirectory buffer-file-name)))
    )

  (add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
  (highlight-indentation-mode t)        ;高亮代码块
  (hs-minor-mode t)                     ;开启 hs-minor-mode 以支持代码折叠
  (auto-fill-mode 0)                    ;关闭 auto-fill-mode，拒绝自动折行
  ;;(whitespace-mode t)                   ;开启 whitespace-mode 对制表符和行为空格高亮
  (pretty-symbols-mode t)               ;开启 pretty-symbols-mode 将 lambda 显示成希腊字符 λ
  (set (make-local-variable 'electric-indent-mode) nil)) ;关闭自动缩进

(add-hook 'python-mode-hook 'my-python-mode-config)

;; run-python 的时候，python shell 里显示一堆乱码
(setenv "IPY_TEST_SIMPLE_PROMPT" "1")













(provide 'init-better-default)
