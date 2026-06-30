;;; init.el --- Emacs 配置入口  -*- lexical-binding: t; -*-


;; init config
;;(package-initialize)

;; 启动加速：启动期临时调大 GC 阈值，startup 完成后恢复为 64MB（默认仅 800KB，频繁 GC 拖慢启动）
(setq gc-cons-threshold most-positive-fixnum
      gc-cons-percentage 0.6)
(setq read-process-output-max (* 1024 1024)) ; 1MB，提升 lsp-bridge 等 IPC 吞吐
(add-hook 'emacs-startup-hook
          (lambda ()
            (garbage-collect)
            (setq gc-cons-threshold (* 64 1024 1024)
                  gc-cons-percentage 0.1)))
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


(setq custom-file (expand-file-name "lisp/custom.el" user-emacs-directory))
(load-file custom-file)

(put 'narrow-to-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)
