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

;; 终端使用lsp_bridge
(unless (display-graphic-p)
  (with-eval-after-load 'acm
    (require 'acm-terminal)))

;; 英语提示
(add-to-list 'load-path "~/.emacs.d/git-package/company-english-helper")

;; 输入法
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
;;(load-theme 'modus-vivendi)
(load-theme 'modus-operandi)

(provide 'git-package)
