;;; init-packages.el --- 包管理与安装  -*- lexical-binding: t; -*-
;;  __        __             __   ___
;; |__)  /\  /  ` |__/  /\  / _` |__
;; |    /~~\ \__, |  \ /~~\ \__> |___
;;                      __   ___        ___      ___
;; |\/|  /\  |\ |  /\  / _` |__   |\/| |__  |\ |  |
;; |  | /~~\ | \| /~~\ \__> |___  |  | |___ | \|  |
(when (>= emacs-major-version 24)
  (require 'package)
  (package-initialize)
  (setq package-archives '(("gnu"   . "https://mirrors.ustc.edu.cn/elpa/gnu/")
			   ("melpa" . "https://mirrors.ustc.edu.cn/elpa/melpa/"))))

;; cl - Common Lisp Extension
(require 'cl-lib)

;; Add Packages
(defvar my/packages '(
		      ;; --- Auto-completion ---
                      posframe
		      ;; --- Better Editor ---
		      hungry-delete
		      ;; 补全栈：vertico 纵向 UI + consult 命令 + orderless 模糊匹配 + marginalia 注解
		      vertico
		      consult
		      orderless
		      marginalia
		      smartparens
		      expand-region
		      popwin
		      pyvenv
                      osx-dictionary
		      magit
		      iedit
                      pyim
                      pyim-basedict
                      ox-hugo
		      ;; --- Editing / Navigation 增强 ---
		      vundo          ; 可视化撤销树
		      avy            ; 屏内快速跳转
		      wgrep          ; grep buffer 可编辑批量改
		      hl-todo        ; 高亮 TODO/FIXME/HACK
		      rainbow-mode   ; buffer 内显示颜色码对应色块
		      treesit-auto   ; 自动启用并安装 tree-sitter 语法
		      gcmh           ; 动态 GC：空闲时才回收，活跃期不卡顿
		      ;; --- Major Mode ---
		      js2-mode
		      web-mode
		      markdown-mode
		      go-mode
                      rust-mode
		      ;; --- Minor Mode ---
		      exec-path-from-shell
		      ;; --- Themes ---
                      rainbow-delimiters
                      magit-section
                      persist
		      ) "Default packages" )

(setq package-selected-packages my/packages)

(defun my/packages-installed-p ()
  (cl-loop for pkg in my/packages
	when (not (package-installed-p pkg)) do (cl-return nil)
	finally (cl-return t)))

(unless (my/packages-installed-p)
  (message "%s" "Refreshing package database...")
  (package-refresh-contents)
  (dolist (pkg my/packages)
    (when (not (package-installed-p pkg))
      (package-install pkg))))

;; Find Executable Path（GUI 下继承 shell 的 PATH，mac/ns 与 Linux x/pgtk 均启用，
;; 延迟到 startup 后执行，避免启动时阻塞调用 shell）
(when (memq window-system '(mac ns x pgtk))
  (add-hook 'emacs-startup-hook #'exec-path-from-shell-initialize))

;; GPG pinentry：让 gpg-agent 把密码请求转发到 Emacs minibuffer
;; 配合 ~/.gnupg/gpg-agent.conf 的 allow-emacs-pinentry，GUI Emacs 也能输 GPG 密码
(use-package pinentry
  :ensure t
  :config
  (pinentry-start))

;; 文件末尾
(provide 'init-packages)


