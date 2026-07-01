;;; init-ui.el --- 界面与主题设置  -*- lexical-binding: t; -*-
;; 工具栏/菜单栏/滚动条/最大化由 early-init.el 的 default-frame-alist 处理，勿在此重复关闭。

(global-display-line-numbers-mode 1)
(setq show-paren-style 'expression)
(setq inhibit-splash-screen 1)
(setq-default cursor-type 'bar)
;;(global-hl-line-mode t)

(setq display-time-format "[%A %m-%d %H:%M]")
(display-time-mode 1)

(setq frame-title-format
      '((:eval (if (buffer-file-name)
                   (abbreviate-file-name (buffer-file-name))
                 "%b"))))

(require 'rainbow-delimiters)
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

;; 仅在颜色相关模式启用 rainbow-mode，避免把普通标识符（如 white/red）也染色
(dolist (hook '(emacs-lisp-mode-hook lisp-interaction-mode-hook
                css-mode-hook web-mode-hook conf-mode-hook))
  (add-hook hook #'rainbow-mode))

;; tab-bar：每个 tab 是独立的窗口布局，C-x t 前缀管理
(setq tab-bar-show 1                    ; ≥2 个 tab 时才显示栏
      tab-bar-close-button-show nil
      tab-bar-new-tab-choice "*scratch*"
      tab-bar-tab-hints t)              ; tab 前显序号
(global-set-key (kbd "C-<tab>") #'tab-bar-switch-to-next-tab)
;; X/GTK 把 Ctrl+Shift+Tab 发为 iso-lefttab 或 backtab，在输入层统一归一化
(define-key key-translation-map (kbd "<C-S-iso-lefttab>") (kbd "C-S-<tab>"))
(define-key key-translation-map (kbd "<C-backtab>")       (kbd "C-S-<tab>"))
(global-set-key (kbd "C-S-<tab>") #'tab-bar-switch-to-prev-tab)

(provide 'init-ui)
