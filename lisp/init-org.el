
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
;; org-roam
;;(add-to-list 'org-roam-capture-templates
;;             '("d" "Default" plain "%?" :target (file+head "%<%Y%m%d%H>-${slug}.org" "#+title: ${title}\n#+filetags: \n")))
(setq org-roam-capture-templates '(("d" "default" plain "%?" :target (file+head "%<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+title: ${title}\n#+filetags: \n") :unnarrowed t)
                ("b" "Book/Article/Movie" plain "%?" :target (file+head "Collection/collection%<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+title: ${title}\n#+links: \n#+filetags: :bookreading: \n\n** Original Data") :unnarrowed t)
                ("k" "Knowledge" plain "%?" :target (file+head "Knowledge/knowledge%<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+title:${slug}\n#+links: \n#+filetags: :knowledge: \n\n** Original Data ") :unnarrowed t)
                ;;("c" "company" plain "%?" :target (file+head "company/company%<%Y%m%d%H>-${slug}.org" "#+title: ${title}\n#filetags: :compnay: \n\n") :unnarrowed t)
		("c" "Coding" plain "%?" :target (file+head "marketing/marketing%<%Y%m%d%H%M%S>-${slug}.org" "#+STARTUP: content\n#+title: ${title}\n#+filetags: :marketing: \n\n") :unnarrowed t)
		("p" "project" plain "%?" :target (file+head "project/project%<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+title: ${title}\n#+filetags: :project: \n\n - tag ::") :unnarrowed t)
		("r" "reference" plain "%?" :target (file+head "<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+title: {$title}\n%filetags: reference \n\n -tag ::") :unarrowed t)))

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
