;;; init-keyboard.el --- 快捷键定义  -*- lexical-binding: t; -*-
;;搜索增强（vertico/consult 栈）
(global-set-key "\C-s" 'consult-line)
(global-set-key (kbd "C-c C-r") 'vertico-repeat)
;; M-x / C-x C-f / C-h f / C-h v 使用原生命令，由 vertico + marginalia 美化与注解
(global-set-key (kbd "C-x b") 'consult-buffer)
(global-set-key (kbd "M-s g") 'consult-ripgrep)

;;打开自动备份文件列表
(global-set-key "\C-x\ \C-r" 'recentf-open-files)

;; 设置 org-agenda 打开快捷键
(global-set-key (kbd "C-c a") 'org-agenda)
(global-set-key (kbd "C-c c") 'org-capture)

;; 用ibuffer代替原buffer
(global-set-key (kbd "C-x C-b") 'ibuffer)

;;快速格式化代码
(global-set-key (kbd "C-c t i") 'my-toggle-web-indent)

;; occur 查找增强
(global-set-key (kbd "M-s o") 'occur-dwim)

;;
(global-set-key (kbd "M-s i") 'consult-imenu)

;; 英语单词自动补全
(global-set-key (kbd "M-s s") 'lsp-bridge-toggle-sdcv-helper)

;;
(global-set-key (kbd "M-s w") 'moonwwdz-insert-current-week)
(global-set-key (kbd "M-s t") 'moonwwdz-toggle-theme)
(global-set-key (kbd "M-s f") 'moonwwdz-insert-file-content-at-point)

;; 对存量文本批量补中英文空格（选中 region 处理区域，否则整个 buffer）
(global-set-key (kbd "M-s c") 'moonwwdz-space-cjk-ascii)

;; Enable Cache
(setq url-automatic-caching t)

;; 字典查词
(global-set-key (kbd "C-c y") 'moonwwdz-dict-lookup-at-point)
;; Mac 自带字典（仅 macOS）
(when (eq system-type 'darwin)
  (require 'osx-dictionary)
  (global-set-key (kbd "C-c d") 'osx-dictionary-search-word-at-point))

;;  打开/关闭粘贴模式
(global-set-key (kbd "M-s p") 'moonwwdz-toggle-paste-helper)

;;magit
(global-set-key (kbd "C-c g") 'magit-status)

;; 电影库（NFO）管理：扫描、展示海报/元数据、编辑 nfo、外调播放器
(global-set-key (kbd "C-c m") 'moonwwdz-media)

;; key bindings
;; mac 右command作为ctrl键用
(setq mac-option-modifier 'meta)
(setq mac-command-modifier 'meta)
(setq mac-right-command-modifier 'meta)
(global-set-key [kp-delete] 'delete-char) ;; sets fn-delete to be right-delete

;; 选中光标所在字符串（可扩充到整个buffer）
(global-set-key (kbd "C-=") 'er/expand-region)

;; 多行选中编辑
(global-set-key (kbd "M-s e") 'iedit-mode)

;; avy 屏内快速跳转
(global-set-key (kbd "C-'") 'avy-goto-char-timer)
(global-set-key (kbd "M-s j") 'avy-goto-line)

;; vundo 可视化撤销树（替换默认 C-x u 的简易 undo 入口）
(global-set-key (kbd "C-x u") 'vundo)

;; 切换输入法
(global-set-key (kbd "C-\\") 'toggle-input-method)

;;
(global-unset-key (kbd "C-SPC"))
(provide 'init-keyboard)
