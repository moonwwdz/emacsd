;;搜索增强 
(global-set-key "\C-s" 'swiper)
(global-set-key (kbd "C-c C-r") 'ivy-resume)
(global-set-key (kbd "M-x") 'counsel-M-x)
(global-set-key (kbd "C-x C-f") 'counsel-find-file)
(global-set-key (kbd "C-h f") 'counsel-describe-function)
(global-set-key (kbd "C-h v") 'counsel-describe-variable)

;;打开自动备份文件列表
(global-set-key "\C-x\ \C-r" 'recentf-open-files)

;; 设置 org-agenda 打开快捷键
(global-set-key (kbd "C-c a") 'org-agenda)

;; 用ibuffer代替原buffer
(global-set-key (kbd "C-x C-b") 'ibuffer)

;;快速格式化代码
(global-set-key (kbd "C-c t i") 'my-toggle-web-indent)

;; occur 查找增强
(global-set-key (kbd "M-s o") 'occur-dwim)

;;
(global-set-key (kbd "M-s i") 'counsel-imenu)

;; key bindings
(when (eq system-type 'darwin) ;; mac specific settings
  ;; mac 右command作为ctrl键用
  (setq mac-right-command-modifier 'control)
  (setq mac-option-modifier 'meta)
  ;;(setq mac-command-modifier 'meta)
  (global-set-key [kp-delete] 'delete-char) ;; sets fn-delete to be right-delete
    )

(provide 'init-keyboard)
