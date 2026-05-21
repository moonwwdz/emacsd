;; Rust 配置

;; rustup component add rust-src rust-analyzer  # 安装 Rust 源码和 rust-analyzer
;; cargo install rustfmt                      # 安装格式化工具
;; cargo install clippy                        # 安装代码检查工具
;; rustup component add rustfmt                 # 通常已包含在 Rust 工具链中

;; 设置 Rust 临时目录环境变量，解决权限问题
(let ((temp-dir "/tmp"))
  (setenv "TMPDIR" temp-dir)
  (setenv "TMP" temp-dir)
  (setenv "TEMP" temp-dir)
  ;; Rust 特定的环境变量
  (setenv "RUST_TMPDIR" temp-dir))

;; 保存时自动格式化
(add-hook 'rust-mode-hook
          (lambda ()
            (setq rust-indent-offset 4)
            (setq compilation-read-command nil)
            (add-hook 'before-save-hook #'rust-format-buffer nil t)))

;; 禁用 flycheck 的 Rust checker，避免与 lsp-bridge 冲突
(add-hook 'rust-mode-hook
          (lambda ()
            (when (featurep 'lsp-bridge)
              (setq-local flycheck-disabled-checkers '(rust rust-clippy rust-cargo rust-cargo-clippy)))))

;; 一键运行 (C-c C-c)，带前缀 C-u 可输入参数
(add-hook 'rust-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c C-c")
                           (lambda (arg)
                             (interactive "P")
                             (let* ((file-name buffer-file-name)
                                    (args (if arg (read-string "Args: ") ""))
                                    (cargo-dir (locate-dominating-file default-directory "Cargo.toml"))
                                    (cmd (if cargo-dir
                                             (concat "cargo run --" (unless (string= args "") (concat " " args)))
                                           (concat "rustc " file-name " && ./" (file-name-base file-name)
                                                   (unless (string= args "") (concat " " args))))))
                               (compile cmd)
                               (switch-to-buffer-other-window "*compilation*"))))))

;; Cargo 常用命令快捷键
(add-hook 'rust-mode-hook
          (lambda ()
            ;; C-c C-b 构建
            (local-set-key (kbd "C-c C-b")
                           (lambda ()
                             (interactive)
                             (compile "cargo build")
                             (switch-to-buffer-other-window "*compilation*")))
            ;; C-c C-t 测试
            (local-set-key (kbd "C-c C-t")
                           (lambda ()
                             (interactive)
                             (compile "cargo test")
                             (switch-to-buffer-other-window "*compilation*")))
            ;; C-c C-k 检查代码
            (local-set-key (kbd "C-c C-k")
                           (lambda ()
                             (interactive)
                             (compile "cargo check")
                             (switch-to-buffer-other-window "*compilation*")))))

;; 启用 electric-pair-mode 自动补全括号
(add-hook 'rust-mode-hook
          (lambda ()
            (electric-pair-local-mode 1)))

(provide 'moonwwdz-rust)