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

(provide 'moonwwdz-helper)
