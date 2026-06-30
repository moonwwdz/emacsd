;;; init-ui.el --- 界面与主题设置  -*- lexical-binding: t; -*-
;;在图形界面的配置
(when (display-graphic-p)
  ;; 关闭工具栏，tool-bar-mode 即为一个 Minor Mode
  (tool-bar-mode -1)
  ;; 颜色配置
  ;;(set-background-color "#2E3436")
  ;;(set-foreground-color "white")
  ;;(set-face-foreground 'region "green")
  ;;(set-face-background 'region "blue")

  ;; 关闭滚动条
  (set-scroll-bar-mode nil)
  ;; 关闭文件滑动控件
  (scroll-bar-mode -1))

;;关闭菜单栏
(menu-bar-mode -1)

;; 关闭文件滑动控件
;;(scroll-bar-mode -1)

;; 显示行号
(global-display-line-numbers-mode 1)

;; 更改光标的样式（不能生效，解决方案见第二集）
;; 括号颜色
(setq show-paren-style 'expression)
;; 关闭启动帮助画面
(setq inhibit-splash-screen 1)

;; 光标样式
(setq-default cursor-type 'bar)

;;高亮当前行
;;(global-hl-line-mode t)

;;显示时间
(setq display-time-format "[%A %m-%d %H:%M]")
(display-time-mode 1)

;;标题栏显示文件路径
(setq frame-title-format
      '((:eval (if (buffer-file-name)
                   (abbreviate-file-name (buffer-file-name))
                 "%b"))))
;;全屏显示(不生效)
;;(add-to-list 'default-frame-alist '(fullscreen . maximizd))


(require 'rainbow-delimiters)
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

;; 在 buffer 内把 #RRGGBB / 颜色名显示成对应色块（写主题/配置时直观）。
;; 只在与颜色强相关的模式启用，避免在普通源码里把名为 white/red 的标识符也染色。
(dolist (hook '(emacs-lisp-mode-hook lisp-interaction-mode-hook
                css-mode-hook web-mode-hook conf-mode-hook))
  (add-hook hook #'rainbow-mode))

(provide 'init-ui)
