;; 自动补全

;; 终端显示补全
(unless (display-graphic-p)
  (add-to-list 'load-path "~/.emacs.d/git-package/popon")
  (add-to-list 'load-path "~/.emacs.d/git-package/acm-terminal"))

(add-to-list 'load-path "~/.emacs.d/git-package/lsp-bridge")

;; 全局激活自动补全
(use-package yasnippet
  :config
  (yas-global-mode 1)
  ;; org 中对yasnippet输入两个字符再补全 
  (with-eval-after-load 'org
    (setq acm-backend-yas-candidate-min-length 2)))

(use-package lsp-bridge
  ;;:ensure t
  :init
  (when (eq system-type 'darwin)
    (setq lsp-bridge-python-command "python3.12"))
  :after evil
  :hook ((go-mode . lsp-bridge-mode)
         (rust-mode . lsp-bridge-mode)
         (python-mode . lsp-bridge-mode)
         (emacs-lisp-mode . lsp-bridge-mode))
  :bind                       ; 绑定快捷键
  (:map lsp-bridge-mode-map
        ("C-c n" . lsp-bridge-diagnostic-jump-next)
        ("C-c p" . lsp-bridge-diagnostic-jump-prev)
        ("M-." . lsp-bridge-find-def)
        ("M-," . lsp-bridge-find-def-return)
        ("C-." . lsp-bridge-show-documentation)
        ("M-?" . lsp-bridge-find-references)            ; 查找引用 (VSCode Shift+F12)
        ("C-c r" . lsp-bridge-rename)                   ; 重命名 (VSCode F2)
        ("C-c q" . lsp-bridge-code-action)              ; 代码操作/Quickfix (VSCode Ctrl+.)
        ("C-c C-p" . lsp-bridge-peek)                   ; Peek 定义 (VSCode Alt+F12)
        ("C-c j" . lsp-bridge-workspace-list-symbols)   ; 全项目符号搜索 (VSCode Ctrl+T)
        ("C-c h" . lsp-bridge-incoming-call-hierarchy)) ; 调用层级
  :config                     ; 包加载后的配置
  ;; 启用悬停诊断
  (setq lsp-bridge-enable-hover-diagnostic t)
  ;; 启用自动补全
  (setq acm-enable-icon t)
  (setq acm-enable-doc t)
  ;; 启用 inlay hint：像 VSCode 一样在变量后面自动显示推断出的类型
  (setq lsp-bridge-enable-inlay-hint t)
  ;; inlay hint 文字样式：用冷调中灰 #8e949a，刻意和 molokai 的 type 青蓝(#66D9EF)拉开色相，
  ;; 靠斜体传达“这是编辑器推断的类型，非真实代码”。不要用饱和鲜艳色，会撞 molokai 的语法高亮。
  (set-face-attribute 'lsp-bridge-inlay-hint-face nil
                      :foreground "#8e949a" :slant 'italic)
  ;; 小文件 / 全屏打开时窗口可视范围不变，post-command 的滚动检测不再触发刷新，
  ;; 而初次请求又落在服务器尚未分析完的空窗期，导致「不编辑就不显示类型」。
  ;; 诊断到达（publishDiagnostics）说明服务器刚完成一次完整分析，此时 inlay hint 必然可用，借机补刷新一次。
  (defun my/lsp-bridge-inlay-hint-after-diagnostic (&rest _)
    "诊断到达时强制刷新一次 inlay hint，修复小文件打开后不显示类型的问题。"
    (when lsp-bridge-enable-inlay-hint
      (lsp-bridge-inlay-hint)))
  (add-hook 'lsp-bridge-diagnostic-update-hook #'my/lsp-bridge-inlay-hint-after-diagnostic)
  ;; 光标停在符号上时，高亮 buffer 内所有同名引用（VSCode 默认效果）
  (setq lsp-bridge-enable-document-highlight t)
  ;; 在 mode-line 显示当前所在的函数/符号名（需配合 which-function-mode 才生效）
  (setq lsp-bridge-symbols-enable-which-func t)
  (which-function-mode 1)
  (defun my/lsp-bridge-doc-setup (&rest _)
    "Jump to doc window and bind q to close."
    (let ((win (get-buffer-window "*lsp-bridge-doc*")))
      (when win
        (select-window win)
        (evil-local-set-key 'normal (kbd "q") 'delete-window))))
  (advice-add 'lsp-bridge-show-documentation--callback :after #'my/lsp-bridge-doc-setup))

;; 终端使用lsp_bridge
(unless (display-graphic-p)
  (with-eval-after-load 'acm
    (require 'acm-terminal)))

;; 输入法
(when (eq system-type 'darwin)
  (setq rime-librime-root "~/.emacs.d/librime/")
  (setq rime-emacs-module-header-root "/Applications/Emacs.app/Contents/Resources/include"))
(add-to-list 'load-path "~/.emacs.d/git-package/emacs-rime")
(use-package rime
  :defer t                       ; 按需加载：激活输入法（C-\）时才载入
  :config
  (setq rime-user-data-dir "~/.config/ibus/rime"))

;;(setq rime-posframe-properties
;;      (list :background-color "#333333"
;;            :foreground-color "#dcdccc"
;;            :font "WenQuanYi Micro Hei Mono-14"
;;            :internal-border-width 10))
(use-package posframe
  :config
  (setq default-input-method "rime"
      rime-show-candidate 'posframe))

;; 显示UI美化
(add-to-list 'load-path "~/.emacs.d/git-package/modus-themes")
(load-theme 'modus-vivendi)
;;(load-theme 'modus-operandi)

;; 英文空格
(use-package wraplish
  :load-path "~/.emacs.d/git-package/wraplish"
  :hook ((markdown-mode org-mode) . wraplish-mode))   ; 打开 markdown/org 时加载并启用，自动在中英文之间补空格

;; 侧边栏
(use-package dired-sidebar
  :load-path "~/.emacs.d/git-package/dired-sidebar"
  :bind (("C-x C-n" . dired-sidebar-toggle-sidebar))
  :init
  (add-hook 'dired-sidebar-mode-hook
            (lambda ()
              (unless (file-remote-p default-directory)
                (auto-revert-mode))))
  :config
  (push 'toggle-window-split dired-sidebar-toggle-hidden-commands)
  (push 'rotate-windows dired-sidebar-toggle-hidden-commands)

  (setq dired-sidebar-subtree-line-prefix "__")
  (setq dired-sidebar-theme 'ascii)
  (setq dired-sidebar-use-term-integration t)
  (setq dired-sidebar-use-custom-font t))

;; hugo
(use-package ox-hugo
  :load-path "~/.emacs.d/git-package/ox-hugo")

;; mastodon
(add-to-list 'load-path "~/.emacs.d/git-package/emacs-request")
(add-to-list 'load-path "~/.emacs.d/git-package/tp.el")
(add-to-list 'load-path "~/.emacs.d/git-package/mastodon/lisp")
(use-package mastodon
  :commands (mastodon)           ; 按需加载：调用 mastodon 时才载入
  :config
  (setq mastodon-instance-url "https://social.13140000.xyz"
      mastodon-active-user "wdd"))

;; org-roam
;;(add-to-list 'load-path "~/.emacs.d/git-package/org-roam")
;;(require 'org-roam)
;;(setq org-roam-directory "~/Documents/orgRoam")
;;(setq find-file-visit-truename t)
;; 自动构建数据库，数据库不需要同笔记一起同步
;;(org-roam-db-autosync-mode)

;; evil 模式
(use-package evil
  :load-path "~/.emacs.d/git-package/evil"
  :init
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1)
  (evil-set-initial-state 'image-mode 'emacs)
  (evil-global-set-key 'normal (kbd "M-.") 'lsp-bridge-find-def)
  (evil-global-set-key 'normal (kbd "M-,") 'lsp-bridge-find-def-return)
  (evil-global-set-key 'normal (kbd "C-.") 'lsp-bridge-show-documentation))

;; nov
(use-package esxml
  :load-path "~/.emacs.d/git-package/esxml")

(use-package nov
  :load-path "~/.emacs.d/git-package/nov"
  :mode ("\\.epub\\'" . nov-mode))

(use-package org-modern
  :load-path "~/.emacs.d/git-package/org-modern"
;;  :ensure t
  :after org
  :hook (after-init . (lambda ()
			(setq org-modern-hide-stars 'leading)
			(global-org-modern-mode t)))
  :config
  ;; 定义各级标题行字符
  (setq org-modern-star ["◉" "○" "✸" "✳" "◈" "◇" "✿" "❀" "✜"])
  (setq-default line-spacing 0.1)
  (setq org-modern-label-border 1)
  (setq org-modern-table-vertical 2)
  (setq org-modern-table-horizontal 0)

  ;; 复选框美化
  (setq org-modern-checkbox
	'((?X . #("▢✓" 0 2 (composition ((2)))))
	  (?- . #("▢–" 0 2 (composition ((2)))))
	  (?\s . #("▢" 0 1 (composition ((1)))))))
  ;; 列表符号美化
  (setq org-modern-list
	'((?- . "•")
	  (?+ . "◦")
	  (?* . "▹")))
  ;; 代码块左边加上一条竖边线
  (setq org-modern-block-fringe t)

  ;; 属性标签使用上述定义的符号，不由 org-modern 定义
  (setq org-modern-block-name nil)
  (setq org-modern-keyword nil))

;; eaf
;;(add-to-list 'load-path "~/.emacs.d/site-lisp/emacs-application-framework/")
;;(require 'eaf)
;;(require 'eaf-browser)
;;(require 'eaf-org-previewer)
(provide 'git-package)
