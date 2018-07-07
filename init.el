

;; init config
(package-initialize)

(add-to-list 'load-path "~/.emacs.d/lisp/")

;; Package Management
;; -----------------------------------------------------------------
(require 'init-packages)
(require 'init-ui)
(require 'init-better-default)
(require 'init-org)
(require 'init-keyboard)
(require 'company-english-helper)

;; custom auto save configure 
;; -----------------------------------------------------------------

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(company-minimum-prefix-length 1))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )
