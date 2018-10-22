;;shell配置

(defun shell-mode-setup()
  (interactive)
  (save-buffer)
  (setq shell-buffer-name (file-name-nondirectory buffer-file-name))
  (shell-command (format "chmod a+x %s" shell-buffer-name))
  (setq compile-command (format "/bin/bash ./%s" shell-buffer-name))
  (define-key (current-local-map) "\C-c\C-p" 'compile))

(add-hook 'shell-mode-hook 'shell-mode-setup)


(provide 'moonwwdz-shell)
