;;; moonwwdz-rust.el --- Rust 开发配置  -*- lexical-binding: t; -*-
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
;; 覆盖项一：cargo.autoreload 改为 true（rust-analyzer 官方默认）。
;; 背景：在 src/bin、examples、tests、benches 等目录新建 .rs 文件后，rust-analyzer 的
;; should_refresh_for_change 会判定需要重新加载工作区；但 lsp-bridge 默认 autoreload:false 禁用了自动 reload，
;; 导致新文件不进 crate graph（unlinked-file 诊断），rust-analyzer 不提供补全，必须重启 emacs。
;; 覆盖项二：cargo.features / checkOnSave.features 从 "all" 改回官方默认 []。
;; 背景：lsp-bridge 默认 "all" 会把每个依赖的全部 feature 拉进 crate graph，proc-macro 与索引量暴涨；
;; 后台重建分析（开项目/保存/工作区变更后的预热窗口）期间补全请求会排队数秒甚至返回空候选，
;; 表现为「输入 for 等关键字后补全菜单偶尔迟迟不弹出」。实测中型项目（~500 crate）：
;; "all" 下预热期出现 3~10 秒尖峰与空响应，[] 下全程 4~107ms。
;; 代价：cfg(feature=...) 门控在非默认 feature 下的 API 拿不到补全/诊断；确有需要的项目再局部改回。
;; 覆盖项三：checkOnSave.command 改为 clippy，保存时除编译错误外还给 lint 建议
;; （无用 clone、多余 borrow 等）。clippy 是 rustup 默认组件（CLAUDE.md 安装说明已含）。
(setq lsp-bridge-user-langserver-dir (expand-file-name "lisp/langserver" user-emacs-directory))

;; 保存时自动格式化
(add-hook 'rust-mode-hook
          (lambda ()
            (setq rust-indent-offset 4)
            (setq compilation-read-command nil)
            (add-hook 'before-save-hook #'rust-format-buffer nil t)))

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

;; 检测光标是否在测试函数内，返回函数名或 nil。
;; rust-analyzer 的 runnable 协议最准，但 lsp-bridge 不支持，这里用正则近似：
;; 向上找最近的 fn 声明，再扫其紧邻上方的连续属性行（#[...]、///），含 test 字样
;; 即视为测试函数（覆盖 #[test]、#[tokio::test]、#[rstest] 等）。
;; 只认紧邻属性行，避免误捞上一个函数的 #[test]。
(defun moonwwdz-rust--test-fn-at-point ()
  (save-excursion
    (when (re-search-backward
           "^\\s-*\\(?:pub\\(?:\\s-+crate\\)?\\s-+\\)?\\(?:async\\s-+\\)?fn\\s-+\\([[:word:]_!?]+\\)"
           nil t)
      (let ((fn-name (match-string-no-properties 1)))
        (catch 'found
          (forward-line -1)
          (while (and (not (bobp))
                      (looking-at-p "[ \t]*\\(///?\\|#\\[\\)"))
            (when (looking-at-p "[ \t]*#\\[[^]]*test")
              (throw 'found fn-name))
            (forward-line -1))
          nil)))))

;; Cargo 常用命令快捷键
(add-hook 'rust-mode-hook
          (lambda ()
            ;; C-c C-b 构建
            (local-set-key (kbd "C-c C-b")
                           (lambda ()
                             (interactive)
                             (compile "cargo build")
                             (switch-to-buffer-other-window "*compilation*")))
            ;; C-c C-t 测试：光标在 #[test] 函数内只跑该用例（全量测试大项目等不起），
            ;; 否则全量 cargo test；C-u 前缀手动输入过滤词（默认值为光标处用例名）
            (local-set-key (kbd "C-c C-t")
                           (lambda (arg)
                             (interactive "P")
                             (let* ((default (moonwwdz-rust--test-fn-at-point))
                                    (filter (if arg
                                                (read-string "Test filter: " default)
                                              default)))
                               (compile (concat "cargo test"
                                                (if (and filter (not (string= filter "")))
                                                    (concat " " filter)
                                                  "")))
                               (switch-to-buffer-other-window "*compilation*"))))
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