;;; moonwwdz-python.el --- Python 开发配置  -*- lexical-binding: t; -*-
;; Python 配置

;; pip install ipython  # 交互式解释器
;; pip install uv       # 虚拟环境管理

;; 强制 .py 使用 python-mode（而非 Emacs 30 默认的 python-ts-mode），
;; lsp-bridge 的 python-mode hook 才能生效。必须在顶层设置，放进 python-mode-hook 永不触发。
(add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))

;; 基础设置
(defun my-python-mode-config ()
  (setq python-indent-offset 4
	python-indent 4
	indent-tabs-mode nil

	;; 设置 run-python 的参数（ipython 未安装时回退到 python3，避免 run-python 失败）
	python-shell-interpreter (if (executable-find "ipython") "ipython" "python3")
	python-shell-interpreter-args "-i"
	python-shell-prompt-regexp "In \\[[0-9]+\\]: "
	python-shell-prompt-output-regexp "Out\\[[0-9]+\\]: "
	python-shell-completion-setup-code "from IPython.core.completerlib import module_completion"
	python-shell-completion-module-string-code "';'.join(module_completion('''%s'''))\n"
	python-shell-completion-string-code "';'.join(get_ipython().Completer.all_completions('''%s'''))\n")

  (hs-minor-mode t)
  (auto-fill-mode 0)
  (set (make-local-variable 'electric-indent-mode) nil)

  ;; 启用 electric-pair-mode 自动补全括号
  (electric-pair-local-mode 1))

(add-hook 'python-mode-hook 'my-python-mode-config)

;; 一键运行 (C-c C-c)，带前缀 C-u 可输入参数
(add-hook 'python-mode-hook
          (lambda ()
            (local-set-key (kbd "C-c C-c")
                           (lambda (arg)
                             (interactive "P")
                             (let* ((file-name buffer-file-name)
                                    (args (if arg (read-string "Args: ") "")))
                               (compile (concat "python3 " file-name
                                                (unless (string= args "") (concat " " args))))
                               (switch-to-buffer-other-window "*compilation*"))))))

;; Python 常用命令快捷键
(add-hook 'python-mode-hook
          (lambda ()
            ;; C-c C-t 测试
            (local-set-key (kbd "C-c C-t")
                           (lambda ()
                             (interactive)
                             (compile "python3 -m pytest")
                             (switch-to-buffer-other-window "*compilation*")))
            ;; C-c C-k 检查代码
            (local-set-key (kbd "C-c C-k")
                           (lambda ()
                             (interactive)
                             (compile (concat "python3 -m py_compile " buffer-file-name))
                             (switch-to-buffer-other-window "*compilation*")))
            ;; F5 快速执行脚本
            (local-set-key (kbd "<f5>")
                           (lambda ()
                             (interactive)
                             (save-buffer)
                             (shell-command (format "python3 %s" (file-name-nondirectory buffer-file-name)))))))

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
        (if (file-exists-p python-path)
            (progn
              (pyvenv-activate venv-path)
              (message "Activated uv venv: %s" venv-path))
          (message "No .venv found in %s" root))))))

(add-hook 'python-mode-hook 'uv-activate)

;; run-python 的时候，python shell 里显示一堆乱码
(setenv "IPY_TEST_SIMPLE_PROMPT" "1")

(provide 'moonwwdz-python)
