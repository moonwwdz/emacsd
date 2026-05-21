(setq system-time-locale "C")
(when (eq system-type 'gun/linux)
  (set-frame-font "LXGW WenKai Mono Screen 14" nil t)
  (set-face-attribute 'default nil :family "LXGW WenKai Mono Screen" :height 120))
(when (eq system-type 'darwin)
  (set-frame-font "LXGW WenKai Mono Screen 16" nil t)
  (set-face-attribute 'default nil :family "LXGW WenKai Mono Screen" :height 120))
(set-frame-size nil 160 60)
;; direct 中显示友好的文件消息
(setq dired-listing-switches "-alh")
;; 自动缩进
(define-key global-map (kbd "RET") 'newline-and-indent)
;; 快速删除多个空格
(require 'hungry-delete)
(global-hungry-delete-mode)

;; smartparens与hungry-delete冲突解决
(defadvice hungry-delete-backward (before sp-delete-pair-advice activate) (save-match-data (sp-delete-pair (ad-get-arg 0))))
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
(setq default-tab-width 4)
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
