
(require 'org)
(setq org-src-fontify-natively t)

;; <e + tab补全 
(require 'org-tempo)

;; 使用capture
(require 'org-capture)

;;工作日志
(add-to-list 'org-capture-templates
             '("w" "Work Journal" entry (file+datetree "~/Documents/emacsNotes/org/work-journal.org")
               "* %U - %^{heading}\n  %?"))
;;日记
(add-to-list 'org-capture-templates
             '("d" "Daily" entry (file+weektree "~/Documents/emacsNotes/org/daily.org")
               "* %U - %^{heading}\n %?"))

;; 设置默认 Org Agenda 文件目录
(setq org-agenda-files '("~/Documents/emacsNotes/agenda"))

(add-hook 'org-mode-hook (lambda () (setq truncate-lines nil)))

(provide 'init-org)
