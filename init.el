;;; init.el --- Emacs 配置入口  -*- lexical-binding: t; -*-

;;(package-initialize)

;; 启动期暂时关闭 GC；启动完成后由 gcmh 接管（空闲才回收，活跃期不卡）
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)
(setq read-process-output-max (* 1024 1024)) ; 提升 lsp-bridge IPC 吞吐
(add-hook 'emacs-startup-hook
          (lambda ()
            (garbage-collect)
            (setq gc-cons-percentage 0.1)
            ;; gcmh 不可用时回退有界阈值，避免 gc-cons-threshold 停留在 most-positive-fixnum
            (if (require 'gcmh nil t)
                (progn
                  (setq gcmh-high-cons-threshold (* 128 1024 1024))
                  (gcmh-mode 1))
              (setq gc-cons-threshold (* 64 1024 1024)))))
(add-to-list 'load-path "~/.emacs.d/lisp/")
;; Package Management
;; -----------------------------------------------------------------
(require 'init-packages)
(require 'init-ui)
(require 'init-better-default)
(require 'init-org)
(require 'init-keyboard)
(require 'moonwwdz-helper)
(require 'moonwwdz-golang)
(require 'moonwwdz-rust)
(require 'moonwwdz-python)
(require 'moonwwdz-shell)
(require 'moonwwdz-dict)
(require 'jsonrpc)
(require 'git-package)
(require 'moonwwdz-media)


(setq custom-file (expand-file-name "lisp/custom.el" user-emacs-directory))
(load-file custom-file)

(put 'narrow-to-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)
