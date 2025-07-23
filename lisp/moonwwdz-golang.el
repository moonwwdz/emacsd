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



(provide 'moonwwdz-golang)
