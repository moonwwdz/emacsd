;; 必须在org导入之前
(setq org-emphasis-regexp-components
      ;; markup 记号前后允许中文
      (list (concat " \t('\"{"            "[:nonascii:]")
            (concat "- \t.,:!?;'\")}\\["  "[:nonascii:]")
            " \t\r\n,\"'"
            "."
            1))
 
(use-package org
  :ensure t
  :config
  ;; 1. 设置自定义强调样式（org-emphasis-alist）
  (setq org-emphasis-alist
        '(("*" bold)
          ("_" underline)
          ("=" (:background "#f39139"))
          ("/" (:foreground "#007947"))
          ("+" (:foreground "dark gray" :strike-through t))
          ("~" (:box (:line-width 1 :color "grey75" :style released-button)))))
  )
;; <e + tab补全 
(require 'org-tempo)

;; 使用capture
(require 'org-capture)
(use-package org-capture
  :config
  ;;工作日志
  (setq org-capture-templates
        '(("w" "Work Journal" entry (file+datetree "~/Documents/emacsNotes/org/work-journal.org")
           "* %U - %^{heading}\n  %?")
          ("a" "Append Work Journal" plain (function append-work-journal)
           "***** %U - %^{heading}\n %?")
          ("u" "Update Work Journal" plain (function update-work-journal)
           "***** %U - %^{heading}\n %?")
          ;;日记
          ("d" "Daily" entry (file+weektree "~/Documents/emacsNotes/org/daily.org")
           "* %U - %^{heading}\n %?")
          ("g" "Gratefule" entry (file+weektree "~/Documents/emacsNotes/org/grateful.org") "* %U - %^{heading}\n %?")))


  ;; org-roam
  ;;(add-to-list 'org-roam-capture-templates
  ;;             '("d" "Default" plain "%?" :target (file+head "%<%Y%m%d%H>-${slug}.org" "#+title: ${title}\n#+filetags: \n")))
  (setq org-roam-capture-templates
        '(("d" "default" plain "%?" :target (file+head "%<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+title: ${title}\n#+filetags: \n") :unnarrowed t)
          ("b" "Book/Article/Movie" plain "%?" :target (file+head "Collection/collection%<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+HTML_HEAD: <link rel=\"stylesheet\" href=\"https://npm.elemecdn.com/lxgw-wenkai-screen-webfont/style.css\" media=\"print\" onload=\"this.media='all'\">\n#+title: ${title}\n#+links: \n#+filetags: :bookreading: \n\n** Summary\n\n** Original Data") :unnarrowed t)
          ("k" "Knowledge" plain "%?" :target (file+head "Knowledge/knowledge%<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+title:${slug}\n#+links: \n#+filetags: :knowledge: \n\n** Original Data ") :unnarrowed t)
          ;;("c" "company" plain "%?" :target (file+head "company/company%<%Y%m%d%H>-${slug}.org" "#+title: ${title}\n#filetags: :compnay: \n\n") :unnarrowed t)
          ("c" "Coding" plain "%?" :target (file+head "Coding/coding%<%Y%m%d%H%M%S>-${slug}.org" "#+STARTUP: content\n#+title: ${title}\n#+filetags: :marketing: \n\n") :unnarrowed t)
          ("p" "project" plain "%?" :target (file+head "Project/Project%<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+title: ${title}\n#+filetags: :project: \n\n - tag ::") :unnarrowed t)
          ("r" "reference" plain "%?" :target (file+head "<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+title: {$title}\n%filetags: reference \n\n -tag ::") :unarrowed t)))

  ;; 设置默认 Org Agenda 文件目录
  (setq org-agenda-files
        '("~/Documents/emacsNotes/agenda/work.org"
          "~/Documents/emacsNotes/agenda/learn.org"
          "~/Documents/emacsNotes/agenda/life.org"))

  )

;;(add-hook 'org-mode-hook (lambda ()
 ;;                          (setq truncate-lines nil)
  ;;                         (set-face-attribute 'default nil :family "TsangerXuanSan03" :height 120)))

;; 自动计算完成状态
(defun org-summary-todo (n-done n-not-done)
  "Switch entry to DONE when all subentries are done, to TODO otherwise."
    (let (org-log-done org-log-states)   ; turn off logging
      (org-todo (if (= n-not-done 0) "DONE" "TODO"))))

(add-hook 'org-after-todo-statistics-hook 'org-summary-todo)

(provide 'init-org)
