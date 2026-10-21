;;; init-org.el --- Org-mode 配置  -*- lexical-binding: t; -*-
;; org 全部延迟加载：启动时不再 require org/org-capture/org-tempo（org+ox+ox-hugo
;; 占 init 近一半耗时）。以下变量都是 defcustom/defvar，先 setq 后加载不会被覆盖；
;; org-capture / org-agenda 命令本身是 autoload，按 C-c c / C-c a 时才载入 org。

;; 必须在org导入之前
(setq org-emphasis-regexp-components
      ;; markup 记号前后允许中文
      (list (concat " \t('\"{"            "[:nonascii:]")
            (concat "- \t.,:!?;'\")}\\["  "[:nonascii:]")
            " \t\r\n,\"'"
            "."
            1))

(use-package org
  :defer t
  :config
  ;; 1. 设置自定义强调样式（org-emphasis-alist）
  (setq org-emphasis-alist
        '(("*" bold)
          ("_" underline)
          ("=" (:background "#f39139"))
          ("/" (:foreground "#007947"))
          ("+" (:foreground "dark gray" :strike-through t))
          ("~" (:box (:line-width 1 :color "grey75" :style released-button)))))
  ;; <e + tab补全
  (require 'org-tempo))

;; 使用capture
;;工作日志（org-capture-templates 是 defcustom，先 setq 后加载不会被覆盖；
;;file+datetree 目标支持符号，org-capture 用时取其变量值；
;;l/L 供 C-c l 一行快速追加（moonwwdz-work-log-quick），:immediate-finish 免进 capture buffer）
(setq org-capture-templates
      '(("l" "Quick Work Log" entry (file+datetree moonwwdz-work-journal-file)
         "* %U - %^{heading}" :immediate-finish t)
        ("L" "Quick Work Log (TODO)" entry (file+datetree moonwwdz-work-journal-file)
         "* TODO %U - %^{heading}" :immediate-finish t)
        ;; w/T：%a 链接放正文首行（拼在标题上会与标题文字无分隔混排）
        ("w" "Work Journal" entry (file+datetree moonwwdz-work-journal-file)
         "* %U - %^{heading}\n  %a%i%?")
        ;; T 计时模板：:clock-keep 让 C-c C-c 完成捕获后时钟继续走，
        ;; 否则 org-capture-finalize 无条件 clock-out，工时只记到写条目的几十秒
        ("T" "Timed Work (clock-in)" entry (file+datetree moonwwdz-work-journal-file)
         "* TODO %U - %^{heading}\n  %a%i%?"
         :clock-in t :clock-resume t :clock-keep t)
        ;;日记
        ("d" "Daily" entry (file+olp+datetree "~/Documents/emacsNotes/org/daily.org" :tree-type week)
         "* %U - %^{heading}\n %?")
        ("g" "Grateful" entry (file+olp+datetree "~/Documents/emacsNotes/org/grateful.org" :tree-type week) "* %U - %^{heading}\n %?")))


;; org-roam（已停用但 submodule 保留；恢复：解开 git-package.el 里 org-roam 块的注释即可，模板留存备查）
;;(add-to-list 'org-roam-capture-templates
;;             '("d" "Default" plain "%?" :target (file+head "%<%Y%m%d%H>-${slug}.org" "#+title: ${title}\n#+filetags: \n")))
;;(setq org-roam-capture-templates
;;      '(("d" "default" plain "%?" :target (file+head "%<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+title: ${title}\n#+filetags: \n") :unnarrowed t)
;;        ("b" "Book/Article/Movie" plain "%?" :target (file+head "Collection/collection%<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+HTML_HEAD: <link rel=\"stylesheet\" href=\"https://npm.elemecdn.com/lxgw-wenkai-screen-webfont/style.css\" media=\"print\" onload=\"this.media='all'\">\n#+title: ${title}\n#+links: \n#+filetags: :bookreading: \n\n** Summary\n\n** Original Data") :unnarrowed t)
;;        ("k" "Knowledge" plain "%?" :target (file+head "Knowledge/knowledge%<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+title:${slug}\n#+links: \n#+filetags: :knowledge: \n\n** Original Data ") :unnarrowed t)
;;        ;;("c" "company" plain "%?" :target (file+head "company/company%<%Y%m%d%H>-${slug}.org" "#+title: ${title}\n#filetags: :compnay: \n\n") :unnarrowed t)
;;        ("c" "Coding" plain "%?" :target (file+head "Coding/coding%<%Y%m%d%H%M%S>-${slug}.org" "#+STARTUP: content\n#+title: ${title}\n#+filetags: :marketing: \n\n") :unnarrowed t)
;;        ("p" "project" plain "%?" :target (file+head "Project/Project%<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+title: ${title}\n#+filetags: :project: \n\n - tag ::") :unnarrowed t)
;;        ("r" "reference" plain "%?" :target (file+head "<%Y%m%d%H>-${slug}.org" "#+STARTUP: content\n#+title: ${title}\n#+filetags: :reference: \n\n -tag ::") :unnarrowed t)))

;; 设置默认 Org Agenda 文件目录
(setq org-agenda-files
      '("~/Documents/emacsNotes/agenda/work.org"
        "~/Documents/emacsNotes/agenda/learn.org"
        "~/Documents/emacsNotes/agenda/life.org"))

;; 工作日志工时视图（基于 work-journal.org 的 clock 记录）
;; 用法：C-c a 后选 w c = 今日工时；w w = 本周工时（clock report 自动汇总）
;; settings 由 org-agenda 运行期求值，文件用符号活引用（不冻结 defvar 值）
(setq org-agenda-custom-commands
      '(("w" . "工作日志")
        ("wc" "今日工时" agenda ""
         ((org-agenda-span 'day)
          (org-agenda-files (list moonwwdz-work-journal-file))
          (org-agenda-start-with-clockreport-mode t)
          (org-agenda-overriding-header "今日工作工时 (clock report)")))
        ("ww" "本周工时" agenda ""
         ((org-agenda-span 'week)
          (org-agenda-files (list moonwwdz-work-journal-file))
          (org-agenda-start-with-clockreport-mode t)
          (org-agenda-overriding-header "本周工作工时 (clock report)")))))

;;(add-hook 'org-mode-hook (lambda ()
 ;;                          (setq truncate-lines nil)
  ;;                         (set-face-attribute 'default nil :family "TsangerXuanSan03" :height 120)))

;; 自动计算完成状态
(defun org-summary-todo (_n-done n-not-done)
  "Switch entry to DONE when all subentries are done, to TODO otherwise."
    (let (org-log-done)   ; turn off logging（org-log-states 早已不存在，去掉）
      (org-todo (if (= n-not-done 0) "DONE" "TODO"))))

(add-hook 'org-after-todo-statistics-hook 'org-summary-todo)

(provide 'init-org)
