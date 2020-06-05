;;在图形界面的配置
(when (display-graphic-p)
  ;; 关闭工具栏，tool-bar-mode 即为一个 Minor Mode
  (tool-bar-mode -1)
  ;; 颜色配置
  (set-background-color "#2E3436")
  (set-foreground-color "white")
  (set-face-foreground 'region "green")
  (set-face-background 'region "blue")

  ;; 关闭文件滑动控件
  (scroll-bar-mode -1))

;; 关闭工具栏，tool-bar-mode 即为一个 Minor Mode
(tool-bar-mode -1)

;; 关闭文件滑动控件
;;(scroll-bar-mode -1)

;; 显示行号
(global-linum-mode 1)
;; 行号样式
(setq linum-format "%2d ")
;; 更改光标的样式（不能生效，解决方案见第二集）
(setq cursor-type 'bar)
;; 括号颜色
(setq show-paren-style 'expression)
;; 关闭启动帮助画面
(setq inhibit-splash-screen 1)

;; 光标样式
(setq-default cursor-type 'bar)

;;高寒当前行
;;(global-hl-line-mode t)

;;theme
(add-to-list 'custom-theme-load-path "~/.emacs.d/theme/")
(setq molokai-theme-kit t)

(require 'rainbow-delimiters)
(add-hook 'prog-mode-hook 'rainbow-delimiters-mode)

(provide 'init-ui)
