;;shell配置

(defun shell-mode-setup()
  (interactive)
  (let (shell-buffer-name)
    (define-key (current-local-map) "\C-c\C-c" 'compile)
    (save-buffer)
    (setq shell-buffer-name (file-name-nondirectory buffer-file-name))
    (message shell-buffer-name "wangc")
    (shell-command (format "chmod a+x %s" shell-buffer-name))
    (setq compile-command (format "/bin/bash ./%s" shell-buffer-name))))


(add-hook 'sh-mode-hook 'shell-mode-setup)



(provide 'moonwwdz-shell)
