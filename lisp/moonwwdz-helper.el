;; 打开/关闭粘贴模式，粘贴模式下没有自动补全和自动缩进
(defun moonwwdz-toggle-paste-helper()
  (interactive)
  (if smartparens-mode
	  (progn
		(setq smartparens-mode nil)
		(setq electric-indent-mode nil)
		(message "Paste mode has enable"))
	(progn
	  (setq smartparens-mode t)
	  (setq electric-indent-mode t)
	  (message "Paste mode has disable"))))
;;
(defun append-work-journal()
  (interactive)
  (let* ((the-buffer (find-file-noselect "~/Documents/emacsNotes/org/work-journal.org")))
    (set-buffer the-buffer)
    (goto-char (point-max))))

(defun update-work-journal()
  (interactive)
  (set-buffer (current-buffer)))


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


(provide 'moonwwdz-helper)
