;;shell配置

(defun moonwwdz-shell-mode-setup()
  (when buffer-file-name
    (let ((shell-buffer-name (file-name-nondirectory buffer-file-name)))
      (define-key (current-local-map) "\C-c\C-c" 'compile)
      (setq compile-command (format "/bin/bash ./%s" shell-buffer-name)))))

(add-hook 'sh-mode-hook 'moonwwdz-shell-mode-setup)
(add-hook 'sh-mode-hook
          (lambda () (add-hook 'after-save-hook
                               #'executable-make-buffer-file-executable-if-script-p
                               nil t)))


(provide 'moonwwdz-shell)
