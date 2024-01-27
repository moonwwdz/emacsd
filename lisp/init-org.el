
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

;; Make verbatim with highlight text background.
(add-to-list 'org-emphasis-alist
             '("=" (:background "#f39139")))

(add-to-list 'org-emphasis-alist
             '("/" (:foreground "#007947")))

;; Make deletion(obsolote) text foreground with dark gray.
(add-to-list 'org-emphasis-alist
           '("+" (:foreground "dark gray"
                  :strike-through t)))
;; Make code style around with box.
(add-to-list 'org-emphasis-alist
           '("~" (:box (:line-width 1
                        :color "grey75"
                        :style released-button))))

(provide 'init-org)
