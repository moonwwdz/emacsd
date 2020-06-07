
(require 'org)
(setq org-src-fontify-natively t)

;; 设置默认 Org Agenda 文件目录
(setq org-agenda-files '("~/org"))

(add-hook 'org-mode-hook (lambda () (setq truncate-lines nil)))

(provide 'init-org)
