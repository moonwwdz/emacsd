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
            ;; 设置 Rust 环境变量
            (setq rust-indent-offset 4)
            (setq compilation-read-command nil)
            (setq process-environment (cons (concat "TMPDIR=" (or (getenv "TMPDIR") "/tmp")) process-environment))
            (add-hook 'before-save-hook #'rust-format-buffer nil t)))

;; lsp-bridge 配置已在 git-package.el 中全局设置
;; 这里可以添加 Rust 特定的 lsp-bridge 配置
(add-hook 'rust-mode-hook
          (lambda ()
            ;; 设置 lsp-bridge Rust 特定选项
            (when (featurep 'lsp-bridge)
              ;; lsp-bridge 会自动检测 rust-analyzer，这里可以添加 Rust 特定配置
              (message "lsp-bridge for Rust mode enabled"))))

;; 启用 flycheck 语法检查，使用 clippy 避免临时目录问题
(add-hook 'rust-mode-hook
          (lambda ()
    ;; 重新设置环境变量，确保在子进程中生效
    (let ((temp-dir "/tmp"))
      (setenv "TMPDIR" temp-dir)
      (setenv "TMP" temp-dir)
      (setenv "TEMP" temp-dir)
      (setenv "RUST_TMPDIR" temp-dir))
    ;; 禁用 rustc 检查器，使用 cargo-clippy 代替
    (setq-local flycheck-disabled-checkers '(rust rust-clippy))
    (setq-local flycheck-checkers '(rust-cargo-clippy rust-cargo))
    (setq flycheck-checker-error-threshold 100)
    (flycheck-mode 1)))

;; 一键运行 (C-c C-c)
(add-hook 'rust-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c C-c")
                           (lambda ()
                             (interactive)
                             (let ((file-name buffer-file-name))
                               (if (string-suffix-p ".rs" file-name)
                                   ;; 如果是单个 .rs 文件，使用 rustc 编译运行
                                   (progn
                                     (compile (concat "rustc " file-name " && "
                                                    (file-name-base file-name)))
                                     (switch-to-buffer-other-window "*compilation*"))
                                 ;; 如果是在 Cargo 项目中，使用 cargo run
                                 (progn
                                   (compile "cargo run")
                                   (switch-to-buffer-other-window "*compilation*"))))))))

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