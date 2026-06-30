;;; init-better-default.el --- 增强默认设置  -*- lexical-binding: t; -*-
(setq system-time-locale "C")
(when (find-font (font-spec :family "LXGW WenKai Mono Screen"))
  (let ((size (if (eq system-type 'darwin) 16 14)))
    (set-frame-font (format "LXGW WenKai Mono Screen %d" size) nil t)
    (set-face-attribute 'default nil :family "LXGW WenKai Mono Screen" :height 120)))
(add-to-list 'default-frame-alist '(fullscreen . maximized))
;; direct 中显示友好的文件消息
(setq dired-listing-switches "-alh")
;; 自动缩进
(define-key global-map (kbd "RET") 'newline-and-indent)
;; 快速删除多个空格
(require 'hungry-delete)
(global-hungry-delete-mode)

;; smartparens与hungry-delete冲突解决
(defun my/sp-delete-pair-before-hungry-delete (n &rest _)
  (save-match-data (sp-delete-pair n)))
(advice-add 'hungry-delete-backward :before #'my/sp-delete-pair-before-hungry-delete)
;;(electric-pair-mode 1)

;; 补全括号、引号
(require 'smartparens-config)
(smartparens-global-mode t)

;; config js2-mode for js files
(setq auto-mode-alist
      (append
       '(("\\.js\\'" . js2-mode)
	 ("\\.html\\'" . web-mode))
          auto-mode-alist))
;; 补全栈：vertico(纵向 UI) + orderless(模糊匹配) + marginalia(注解) + consult(命令)
(require 'vertico)
(vertico-mode 1)
(setq vertico-cycle t)
(require 'marginalia)
(marginalia-mode 1)
(require 'orderless)
(setq completion-styles '(orderless basic)
      completion-category-overrides '((file (styles partial-completion))))
;; vertico 按历史排序需要 savehist
(require 'savehist)
(savehist-mode 1)
;; C-c C-r 重复上次 minibuffer 会话（vertico 已同步加载，直接 require 扩展即可）
(require 'vertico-repeat)
(add-hook 'minibuffer-setup-hook #'vertico-repeat-save)

;; 高亮 TODO/FIXME/HACK 等关键字
(require 'hl-todo)
(global-hl-todo-mode 1)

;; grep buffer 内可编辑，批量修改后一键写回（grep-mode 默认 C-c C-p 进入编辑）。
;; 惰性加载：首次用到 grep 时再载入 wgrep，由其自身挂上 grep-setup-hook。
(with-eval-after-load 'grep (require 'wgrep))

;; 自动启用 tree-sitter：对不依赖 lsp-bridge 的语言提供更准的高亮/缩进。
;; 'prompt 表示首次遇到缺失语法时询问安装（需 git + C 编译器），不会静默卡住。
;; 关键：treesit-auto 会把 python-mode/go-mode/rust-mode 重映射到 *-ts-mode，
;; 而 lsp-bridge 挂在非 ts 版模式上（见 git-package.el），一旦装了对应 grammar
;; 就会使这三门语言的 lsp-bridge 失效。因此从 treesit-auto 中剔除这些语言，
;; 只让它接管 json/yaml/toml/dockerfile 等无 lsp-bridge 的语言。
(when (treesit-available-p)
  (require 'treesit-auto)
  (setq treesit-auto-install 'prompt)
  (setq treesit-auto-langs
        (seq-difference treesit-auto-langs '(python go gomod rust)))
  (global-treesit-auto-mode 1))

;; 屏内快速跳转(avy) / 可视化撤销树(vundo) 的命令已由各自包的 autoloads 提供，
;; 这里无需再显式声明；键绑定见 init-keyboard，按键时按需加载。

;; 打开新窗口后，光标自动切换到新窗口
(require 'popwin)
(popwin-mode t)

;; 打开当前文件的driect
(require 'dired-x)
(setq dired-dwim-target t)

;; 取消自动生成备份文件
(setq make-backup-files nil)



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

;;粘贴到光标位置而不是鼠标位置
(setq mouse-yank-at-point t)
;;系统剪贴板同步
(setq select-enable-clipboard t)
(setq save-interprogram-paste-before-kill t)

;; 快速确认
(fset 'yes-or-no-p 'y-or-n-p)

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
(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)
(setq c-basic-offset 4)


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
