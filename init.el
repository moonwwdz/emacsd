

;; init config
;;(package-initialize)

(add-to-list 'load-path "~/.emacs.d/lisp/")
;; Package Management
;; -----------------------------------------------------------------
(require 'init-packages)
(require 'init-ui)
(require 'init-better-default)
(require 'init-org)
(require 'init-keyboard)
(require 'company-english-helper)
(require 'moonwwdz-helper)
;;(require 'moonwwdz-golang)
(require 'moonwwdz-shell)
(require 'jsonrpc)
(require 'git-package)


(setq custom-file (expand-file-name "lisp/custom.el" user-emacs-directory))
(load-file custom-file)

(put 'narrow-to-region 'disabled nil)
(put 'upcase-region 'disabled nil)
(put 'downcase-region 'disabled nil)
