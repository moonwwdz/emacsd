;;golang 配置

;;go install golang.org/x/tools/gopls@latest       # 语言服务器
;;go install github.com/go-delve/delve/cmd/dlv@latest  # 调试器
;;go install golang.org/x/tools/cmd/goimports@latest   # 自动导入管理

;; 保存时自动格式化
(add-hook 'go-mode-hook
          (lambda ()
            (setq go-tab-width 4)
            (setq go-indent-with-tabs t)
            (setq compilation-read-command nil)
            (setq gofmt-command "goimports")
            (add-hook 'before-save-hook #'gofmt-before-save nil t)))

;; 一键运行 (C-c C-c)，带前缀 C-u 可输入参数
(add-hook 'go-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c C-c")
                           (lambda (arg)
                             (interactive "P")
                             (let* ((file-name buffer-file-name)
                                    (args (if arg (read-string "Args: ") "")))
                               (compile (concat "go run " file-name
                                                (and (not (string= args "")) (concat " " args))))
                               (switch-to-buffer-other-window "*compilation*"))))))

;; Go 常用命令快捷键
(add-hook 'go-mode-hook
          (lambda ()
            ;; C-c C-b 构建
            (local-set-key (kbd "C-c C-b")
                           (lambda ()
                             (interactive)
                             (compile "go build")
                             (switch-to-buffer-other-window "*compilation*")))
            ;; C-c C-t 测试
            (local-set-key (kbd "C-c C-t")
                           (lambda ()
                             (interactive)
                             (compile "go test ./...")
                             (switch-to-buffer-other-window "*compilation*")))
            ;; C-c C-k 检查代码
            (local-set-key (kbd "C-c C-k")
                           (lambda ()
                             (interactive)
                             (compile "go vet ./...")
                             (switch-to-buffer-other-window "*compilation*")))))

(provide 'moonwwdz-golang)
