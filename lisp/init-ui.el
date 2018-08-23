(when (display-graphic-p)
  ;; 关闭工具栏，tool-bar-mode 即为一个 Minor Mode
  (tool-bar-mode -1)

  ;; 关闭文件滑动控件
  (scroll-bar-mode -1))

;; 关闭工具栏，tool-bar-mode 即为一个 Minor Mode
;;(tool-bar-mode -1)

;; 关闭文件滑动控件
;;(scroll-bar-mode -1)

;; 显示行号
(global-linum-mode 1)
;; 行号样式
(setq linum-format "%2d ")
;; 更改光标的样式（不能生效，解决方案见第二集）
(setq cursor-type 'bar)

;; 关闭启动帮助画面
(setq inhibit-splash-screen 1)

;; 光标样式
(setq-default cursor-type 'bar)

;;高寒当前行
;;(global-hl-line-mode t)

;;theme
(add-to-list 'custom-theme-load-path "~/.emacs.d/theme/")
(setq molokai-theme-kit t)


(provide 'init-ui)
