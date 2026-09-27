;;; custom.el --- Custom 自动保存配置  -*- lexical-binding: t; -*-
;; custom auto save configure
;; -----------------------------------------------------------------

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("c3c0a3702e1d6c0373a0f6a557788dfd49ec9e66e753fb24493579859c8e95ab" default))
 '(safe-local-variable-values '((eval org-content 2))))


;; rainbow-delimiters 高饱和配色只在深色背景（modus-vivendi）下生效；
;; 浅色主题（modus-operandi）下 yellow/chartreuse 等在白底上看不清，交回主题/包默认配色。
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(rainbow-delimiters-depth-1-face ((((background dark)) (:foreground "dark orange"))))
 '(rainbow-delimiters-depth-2-face ((((background dark)) (:foreground "deep pink"))))
 '(rainbow-delimiters-depth-3-face ((((background dark)) (:foreground "chartreuse"))))
 '(rainbow-delimiters-depth-4-face ((((background dark)) (:foreground "deep sky blue"))))
 '(rainbow-delimiters-depth-5-face ((((background dark)) (:foreground "yellow"))))
 '(rainbow-delimiters-depth-6-face ((((background dark)) (:foreground "orchid"))))
 '(rainbow-delimiters-depth-7-face ((((background dark)) (:foreground "spring green"))))
 '(rainbow-delimiters-depth-8-face ((((background dark)) (:foreground "sienna1")))))
