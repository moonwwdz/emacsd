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

;; lsp-bridge 的 rust-analyzer 配置覆盖。
;; 用用户目录（lisp/langserver/rust-analyzer.json）覆盖 lsp-bridge submodule 的默认配置，避免改动 submodule。
;; 本文件在 init.el 中早于 git-package(require 'lsp-bridge) 加载，故此 setq 先于 lsp-bridge 读取 langserver 配置生效。
;; 覆盖项：cargo.autoreload 改为 true（rust-analyzer 官方默认）。
;; 背景：在 src/bin、examples、tests、benches 等目录新建 .rs 文件后，rust-analyzer 的
;; should_refresh_for_change 会判定需要重新加载工作区；但 lsp-bridge 默认 autoreload:false 禁用了自动 reload，
;; 导致新文件不进 crate graph（unlinked-file 诊断），rust-analyzer 不提供补全，必须重启 emacs。
(setq lsp-bridge-user-langserver-dir (expand-file-name "lisp/langserver" user-emacs-directory))

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

;; 检测当前文件是否为 cargo bin 目标，返回 bin 名或 nil。
;; 支持两种约定：src/bin/NAME.rs（bin 名 NAME）、src/bin/NAME/main.rs（bin 名 NAME）。
(defun moonwwdz-rust--bin-name (file cargo-dir)
  (when (and file cargo-dir)
    (let* ((rel (file-relative-name file (file-name-as-directory cargo-dir)))
           (parts (split-string rel "/")))
      (cond
       ;; src/bin/NAME.rs
       ((and (= (length parts) 3)
             (equal (nth 0 parts) "src")
             (equal (nth 1 parts) "bin")
             (string-suffix-p ".rs" (nth 2 parts)))
        (file-name-base file))
       ;; src/bin/NAME/main.rs
       ((and (= (length parts) 4)
             (equal (nth 0 parts) "src")
             (equal (nth 1 parts) "bin")
             (equal (nth 3 parts) "main.rs"))
        (nth 2 parts))))))

;; 一键运行 (C-c C-c)，带前缀 C-u 可输入参数
;; 文件位于 src/bin/ 下时用 cargo run --bin NAME，否则用 cargo run（无 Cargo.toml 时回退 rustc）
(add-hook 'rust-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c C-c")
                           (lambda (arg)
                             (interactive "P")
                             (let* ((file-name buffer-file-name)
                                    (args (if arg (read-string "Args: ") ""))
                                    (cargo-dir (locate-dominating-file default-directory "Cargo.toml"))
                                    (bin-name (moonwwdz-rust--bin-name file-name cargo-dir))
                                    (cmd (cond
                                          ;; src/bin 目标：cargo run --bin NAME
                                          (bin-name
                                           (concat "cargo run --bin " bin-name
                                                   (unless (string= args "") (concat " -- " args))))
                                          ;; 普通 cargo 项目：cargo run
                                          (cargo-dir
                                           (concat "cargo run"
                                                   (unless (string= args "") (concat " -- " args))))
                                          ;; 独立文件：rustc 直接编译运行
                                          (t
                                           (concat "rustc " file-name " && ./" (file-name-base file-name)
                                                   (unless (string= args "") (concat " " args)))))))
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