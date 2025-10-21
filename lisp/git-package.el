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
  :after evil
  :hook ((go-mode . lsp-bridge-mode)
         (emacs-lisp-mode . lsp-bridge-mode))
  :config                     ; 包加载后的配置
  ;; 如果你确实想全局激活lsp-bridge，可以保留下面这行，但和上面的:hook是互斥的，通常二选一
  ;; (global-lsp-bridge-mode)
  ;(setq lsp-bridge-enable-hover-diagnostic t) ; 启用悬停诊断
  ;; 注意：lsp-bridge-default-mode-hooks 通常用于内部控制，如果你通过:hook指定了，就不太需要直接设置它
  :bind                       ; 绑定快捷键
  (:map lsp-bridge-mode-map
        ;;("M-n" . lsp-bridge-diagnostic-jump-next)
        ;;("M-p" . lsp-bridge-diagnostic-jump-prev)
        ("M-." . lsp-bridge-find-def)
        ("M-," . lsp-bridge-find-def-return)
        ("C-." . lsp-bridge-show-documentation)))


;; 终端使用lsp_bridge
(unless (display-graphic-p)
  (with-eval-after-load 'acm
    (require 'acm-terminal)))

;; 英语提示
(add-to-list 'load-path "~/.emacs.d/git-package/company-english-helper")

;; 输入法
(when (eq system-type 'darwin)
  (setq rime-librime-root "~/.emacs.d/librime/")
  (setq rime-emacs-module-header-root "/Applications/Emacs.app/Contents/Resources/include"))
(add-to-list 'load-path "~/.emacs.d/git-package/emacs-rime")
(use-package rime
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
  :config
  (dolist (hook (list 'markdown-mode-hook))
    (add-hook hook #'(lambda () (wraplish-mode 1)))))

;; 侧边栏
(use-package dired-sidebar
  :load-path "~/.emacs.d/git-package/dired-sidebar"
  :bind (("C-x C-n" . dired-sidebar-toggle-sidebar))
  :ensure t
  :commands (dired-sidebar-toggle-sidebar)
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
  (evil-global-set-key 'normal (kbd "M-,") 'lsp-bridge-find-def-return))

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
  (setq org-modern-table-vectical 2)
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
