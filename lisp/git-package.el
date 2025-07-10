;; 自动补全

;; 终端显示补全
(unless (display-graphic-p)
  (add-to-list 'load-path "~/.emacs.d/git-package/popon")
  (add-to-list 'load-path "~/.emacs.d/git-package/acm-terminal"))

(add-to-list 'load-path "~/.emacs.d/git-package/lsp-bridge")

;; 全局激活自动补全
(require 'yasnippet)
(yas-global-mode 1)

(require 'lsp-bridge)
(global-lsp-bridge-mode)
;; org 中对yasnippet输入两个字符再补全 
(with-eval-after-load 'org
  (setq acm-backend-yas-candidate-min-length 2))

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
(require 'rime)
(setq rime-user-data-dir "~/.config/ibus/rime")

;;(setq rime-posframe-properties
;;      (list :background-color "#333333"
;;            :foreground-color "#dcdccc"
;;            :font "WenQuanYi Micro Hei Mono-14"
;;            :internal-border-width 10))
(require 'posframe)
(setq default-input-method "rime"
      rime-show-candidate 'posframe)

;; 显示UI美化
(add-to-list 'load-path "~/.emacs.d/git-package/modus-themes")
(load-theme 'modus-vivendi)
;;(load-theme 'modus-operandi)

;; 英文空格
(add-to-list 'load-path "~/.emacs.d/git-package/wraplish")
(require 'wraplish)
(dolist (hook (list 'markdown-mode-hook))
  (add-hook hook #'(lambda () (wraplish-mode 1))))

;; hugo
(add-to-list 'load-path "~/.emacs.d/git-package/ox-hugo")
(require 'ox-hugo)

;; mastodon
(add-to-list 'load-path "~/.emacs.d/git-package/emacs-request")
(add-to-list 'load-path "~/.emacs.d/git-package/tp.el")
(add-to-list 'load-path "~/.emacs.d/git-package/mastodon/lisp")
(require 'mastodon)

(setq mastodon-instance-url "https://social.13140000.xyz"
      mastodon-active-user "wdd")

;; org-roam
;;(add-to-list 'load-path "~/.emacs.d/git-package/org-roam")
;;(require 'org-roam)
;;(setq org-roam-directory "~/Documents/orgRoam")
;;(setq find-file-visit-truename t)
;; 自动构建数据库，数据库不需要同笔记一起同步
;;(org-roam-db-autosync-mode)

;; evil 模式
(add-to-list 'load-path "~/.emacs.d/git-package/evil")
(require 'evil)
(evil-mode 1)

;; nov
;;(add-to-list 'load-path "~/.emacs.d/git-package/nov")
;;(require 'nov)
;;(add-to-list 'auto-mode-alist '("\\.epub\\'" . nov-mode))

;; eaf
;;(add-to-list 'load-path "~/.emacs.d/site-lisp/emacs-application-framework/")
;;(require 'eaf)
;;(require 'eaf-browser)
;;(require 'eaf-org-previewer)
(provide 'git-package)
