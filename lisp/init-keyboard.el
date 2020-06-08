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

;; 英语单词自动补全
(global-set-key (kbd "M-s s") 'toggle-company-english-helper)
;; Enable Cache
(setq url-automatic-caching t)

;; 有道字典翻译 Example Key binding
(global-set-key (kbd "C-c y") 'youdao-dictionary-search-at-point)
;; Mac 自带字典
(global-set-key (kbd "C-c d") 'osx-dictionary-search-word-at-point)

;;  打开/关闭粘贴模式
(global-set-key (kbd "M-s p") 'moonwwdz-toggle-paste-helper)

;;magit
(global-set-key (kbd "C-c g") 'magit-status)

;; key bindings
;; mac 右command作为ctrl键用
(setq mac-right-command-modifier 'control)
(setq mac-option-modifier 'meta)
;;(setq mac-command-modifier 'meta)
(global-set-key [kp-delete] 'delete-char) ;; sets fn-delete to be right-delete

;; 选中光标所在字符串（可扩充到整个buffer）
(global-set-key (kbd "C-=") 'er/expand-region)

;; 多行选中编辑
(global-set-key (kbd "M-s e") 'iedit-mode)

(provide 'init-keyboard)
