;; 打开/关闭粘贴模式，粘贴模式下没有自动补全和自动缩进
(defun moonwwdz-toggle-paste-helper()
  (interactive)
  (if smartparens-mode
	  (progn
		(smartparens-mode -1)
		(electric-indent-local-mode -1)
		(message "Paste mode enabled"))
	(progn
	  (smartparens-mode 1)
	  (electric-indent-local-mode 1)
	  (message "Paste mode disabled"))))
;;
(defvar moonwwdz-work-journal-file "~/Documents/emacsNotes/org/work-journal.org")

(defun append-work-journal()
  (interactive)
  (set-buffer (find-file-noselect moonwwdz-work-journal-file))
  (goto-char (point-max)))

(defun update-work-journal()
  (interactive)
  (set-buffer (find-file-noselect moonwwdz-work-journal-file))
  (goto-char (point-max))
  (re-search-backward "^\\*" nil t))


(defun moonwwdz-org-insert-custom-headlines ()
(interactive)
  (save-excursion
    (let ((headline-text (nth 4 (org-heading-components)))
          (custom-text '("首次学习" "隔天的复习" "三天的复习" "七天的复习" "半个月的复习" "一个月的复习" "三个月的复习" "六个月的复习"))
          (memory-curve-days '(0 1 4 11 26 56 146 266)))
      (org-metaright)
      (org-end-of-line)
      (dotimes (i 8)
        (org-insert-heading-respect-content)
        (setq timestamp (format-time-string "<%Y-%m-%d %a 21:00>" (time-add (current-time) (* (nth i memory-curve-days) 86400))))
        (insert (format "TODO  %s-%s %s"  (nth i custom-text) headline-text timestamp)))))
  (org-metaleft))

(defun moonwwdz-insert-current-week ()
  (interactive)
  (insert (format-time-string "** 第 %V 周 \n 1. ")))

;; 切换主题
(defun moonwwdz-toggle-theme ()
  "Toggle between modus-operandi and modus-vivendi themes."
  (interactive)
  (if (custom-theme-enabled-p 'modus-operandi)
      (progn
        (disable-theme 'modus-operandi)
        (load-theme 'modus-vivendi t))
    (progn
      (disable-theme 'modus-vivendi)
      (load-theme 'modus-operandi t))))

;; 选择一个文件，将文件的全部内容插入到当前光标位置"
(defun moonwwdz-insert-file-content-at-point ()
  (interactive)
  (let ((file-path (read-file-name "select one note: " "~/Documents/org-roam/")))
    (when (file-exists-p file-path)
      (insert-file-contents file-path))))


;; 对存量文本批量在中文与英文/数字边界补空格
;; （wraplish 只处理实时输入，无法处理打开的旧文件；此命令弥补这个空缺）
(defun moonwwdz-space-cjk-ascii ()
  "在当前 region（未选中则整个 buffer）的中文与英文/数字边界插入空格。
中文与英数相邻、英数与中文相邻各补一个空格；已有空格的不重复处理。"
  (interactive)
  (save-restriction
    (narrow-to-region (if (use-region-p) (region-beginning) (point-min))
                      (if (use-region-p) (region-end) (point-max)))
    (save-excursion
      (goto-char (point-min))
      ;; 中文 + 英数 -> 中文 空格 英数
      (while (re-search-forward "\\([一-龥]+\\)\\([0-9A-Za-z]+\\)" nil t)
        (replace-match "\\1 \\2"))
      (goto-char (point-min))
      ;; 英数 + 中文 -> 英数 空格 中文
      (while (re-search-forward "\\([0-9A-Za-z]+\\)\\([一-龥]+\\)" nil t)
        (replace-match "\\1 \\2")))))

(provide 'moonwwdz-helper)
