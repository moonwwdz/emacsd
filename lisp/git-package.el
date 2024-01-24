;; 自动补全
;;(if (display-graphic-p)
;;    )
(add-to-list 'load-path "~/.emacs.d/git-package/lsp-bridge")
;; 全局激活自动补全
(require 'yasnippet)
(yas-global-mode 1)

(require 'lsp-bridge)
(global-lsp-bridge-mode)


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


(provide 'git-package)
