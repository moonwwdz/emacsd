;;; moonwwdz-golang.el --- Go 开发配置  -*- lexical-binding: t; -*-
;;golang 配置

;;go install golang.org/x/tools/gopls@latest       # 语言服务器
;;go install github.com/go-delve/delve/cmd/dlv@latest  # 调试器
;;go install golang.org/x/tools/cmd/goimports@latest   # 自动导入管理

;; 检测光标所在的测试函数，返回 (KIND . NAME)，否则 nil。
;; KIND 为 test/bench/fuzz；Go 要求测试函数必须是顶层 func 且名字带前缀
;; （TestXxx(*testing.T)/BenchmarkXxx(*testing.B)/FuzzXxx(*testing.F)），
;; 先定位最近的 func 行再验前缀，避免误捞上一个函数。
(defun moonwwdz-golang--test-fn-at-point ()
  (save-excursion
    (when (re-search-backward "^func " nil t)
      (goto-char (match-beginning 0))
      (when (looking-at "^func \\(Test\\|Benchmark\\|Fuzz\\)\\([[:word:]_]*\\)(")
        (let* ((kind (match-string-no-properties 1))
               (name (concat kind (match-string-no-properties 2))))
          (cons (pcase kind
                  ("Test" 'test)
                  ("Benchmark" 'bench)
                  ("Fuzz" 'fuzz))
                name))))))

;; Go 开发配置：保存时格式化 + 常用命令快捷键
(add-hook 'go-mode-hook
          (lambda ()
            ;; 保存时自动格式化
            (setq go-tab-width 4)
            (setq go-indent-with-tabs t)
            (setq compilation-read-command nil)
            (setq gofmt-command "goimports")
            (add-hook 'before-save-hook #'gofmt-before-save nil t)
            ;; C-c C-c 一键运行，带前缀 C-u 可输入参数
            (local-set-key (kbd "C-c C-c")
                           (lambda (arg)
                             (interactive "P")
                             (let* ((file-name buffer-file-name)
                                    (args (if arg (read-string "Args: ") "")))
                               (compile (concat "go run " file-name
                                                (and (not (string= args "")) (concat " " args))))
                               (switch-to-buffer-other-window "*compilation*"))))
            ;; C-c C-b 构建
            (local-set-key (kbd "C-c C-b")
                           (lambda ()
                             (interactive)
                             (compile "go build")
                             (switch-to-buffer-other-window "*compilation*")))
            ;; C-c C-t 测试：光标在 Test/Fuzz 函数内只跑当前包该用例（全仓库 ./...
            ;; 要编译所有包，大仓库等不起）；Benchmark 函数用 -bench 跑（-run '^$'
            ;; 跳过普通测试）；其他位置全量；C-u 前缀手动输入 -run 正则跑全仓库
            (local-set-key (kbd "C-c C-t")
                           (lambda (arg)
                             (interactive "P")
                             (let* ((at-point (moonwwdz-golang--test-fn-at-point))
                                    (cmd (cond
                                          (arg
                                           (let ((filter (read-string "Test filter (-run regexp): "
                                                                      (cdr at-point))))
                                             (concat "go test -run '" filter "' ./...")))
                                          ((memq (car at-point) '(test fuzz))
                                           (concat "go test -run '^" (cdr at-point) "$' ."))
                                          ((eq (car at-point) 'bench)
                                           (concat "go test -bench '^" (cdr at-point) "$' -run '^$' ."))
                                          (t "go test ./..."))))
                               (compile cmd)
                               (switch-to-buffer-other-window "*compilation*"))))
            ;; C-c C-k 检查代码
            (local-set-key (kbd "C-c C-k")
                           (lambda ()
                             (interactive)
                             (compile "go vet ./...")
                             (switch-to-buffer-other-window "*compilation*")))))

(provide 'moonwwdz-golang)
