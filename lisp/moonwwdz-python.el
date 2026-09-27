;;; moonwwdz-python.el --- Python 开发配置  -*- lexical-binding: t; -*-
;; Python 配置

;; pip install ipython  # 交互式解释器
;; pip install uv       # 虚拟环境管理

;; 强制 .py 使用 python-mode（而非 Emacs 30 默认的 python-ts-mode），
;; lsp-bridge 的 python-mode hook 才能生效。必须在顶层设置，放进 python-mode-hook 永不触发。
(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))

;; 基础设置
;; run-python 解释器：有 ipython 用 ipython（--simple-prompt 避免 shell 里一堆控制符乱码），
;; 否则回退 python3。每次进 python-mode 时判断：venv 激活后 PATH 里可能才有 ipython。
;; 提示符与补全不用手工配：Emacs 30+ 的 python.el 默认 python-shell-prompt-input-regexps
;; 已含 IPython 的 "In [N]: "，原生补全也通用；旧写法覆盖 python-shell-completion-setup-code
;; 反而会破坏 python.el 自带的补全初始化。
(defun my-python-mode-config ()
  (if (executable-find "ipython")
      (setq python-shell-interpreter "ipython"
            python-shell-interpreter-args "-i --simple-prompt")
    (setq python-shell-interpreter "python3"
          python-shell-interpreter-args "-i"))
  (setq python-indent-offset 4
	indent-tabs-mode nil)

  (hs-minor-mode t)
  (auto-fill-mode 0)
  (electric-indent-local-mode -1))

;; 括号配对由全局 smartparens 负责，不再叠加 electric-pair-local-mode（两套并存会重复处理）
(add-hook 'python-mode-hook 'my-python-mode-config)

;; 一键运行 (C-c C-c)，带前缀 C-u 可输入参数
(add-hook 'python-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c C-c")
                           (lambda (arg)
                             (interactive "P")
                             (let* ((file-name buffer-file-name)
                                    (args (if arg (read-string "Args: ") "")))
                               (moonwwdz-compile
                                (concat "python3 " (shell-quote-argument file-name)
                                        (unless (string= args "") (concat " " args)))))))))

;; Python 常用命令快捷键
(add-hook 'python-mode-hook
          (lambda ()
            ;; C-c C-t 测试
            (local-set-key (kbd "C-c C-t")
                           (lambda ()
                             (interactive)
                             (moonwwdz-compile "python3 -m pytest")))
            ;; C-c C-k 检查代码
            (local-set-key (kbd "C-c C-k")
                           (lambda ()
                             (interactive)
                             (moonwwdz-compile
                              (concat "python3 -m py_compile " (shell-quote-argument buffer-file-name)))))
            ;; F5 快速执行脚本
            (local-set-key (kbd "<f5>")
                           (lambda ()
                             (interactive)
                             (save-buffer)
                             (shell-command
                              (concat "python3 " (shell-quote-argument
                                                  (file-name-nondirectory buffer-file-name))))))))

;; uv 虚拟环境激活
(defun uv-activate ()
  "Activate uv .venv in current project (skip if already active)."
  (interactive)
  (let* ((proj (project-current))
         (root (if proj (project-root proj) default-directory))
         (venv-path (expand-file-name ".venv" root)))
    (unless (and (bound-and-true-p pyvenv-virtual-env)
                 (file-equal-p pyvenv-virtual-env venv-path))
      (let ((python-path (expand-file-name "bin/python" venv-path)))
        (cond
         ((file-exists-p python-path)
          (pyvenv-activate venv-path)
          (message "Activated uv venv: %s" venv-path))
         ;; 挂在 python-mode-hook 上时静默：否则每打开一个无 venv 的脚本都刷一条消息
         ((called-interactively-p 'interactive)
          (message "No .venv found in %s" root)))))))

(add-hook 'python-mode-hook 'uv-activate)

(provide 'moonwwdz-python)
