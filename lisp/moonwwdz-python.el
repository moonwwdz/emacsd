;; Python 配置

;; pip install ipython  # 交互式解释器
;; pip install uv       # 虚拟环境管理

;; 基础设置
(defun my-python-mode-config ()
  (setq python-indent-offset 4
	python-indent 4
	indent-tabs-mode nil
	default-tab-width 4

	;; 设置 run-python 的参数
	python-shell-interpreter "ipython"
	python-shell-interpreter-args "-i"
	python-shell-prompt-regexp "In \\[[0-9]+\\]: "
	python-shell-prompt-output-regexp "Out\\[[0-9]+\\]: "
	python-shell-completion-setup-code "from IPython.core.completerlib import module_completion"
	python-shell-completion-module-string-code "';'.join(module_completion('''%s'''))\n"
	python-shell-completion-string-code "';'.join(get_ipython().Completer.all_completions('''%s'''))\n")

  (add-to-list 'auto-mode-alist '("\\.py\\'" . python-mode))
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
  "Activate uv .venv in current project."
  (interactive)
  (let* ((project-root (or (project-root (project-current)) default-directory))
         (venv-path (expand-file-name ".venv" project-root))
         (python-path (expand-file-name "bin/python" venv-path)))
    (if (file-exists-p python-path)
        (progn
          (pyvenv-activate venv-path)
          (message "Activated uv venv: %s" venv-path))
      (message "No .venv found in %s" project-root))))

(add-hook 'python-mode-hook 'uv-activate)

;; run-python 的时候，python shell 里显示一堆乱码
(setenv "IPY_TEST_SIMPLE_PROMPT" "1")

(provide 'moonwwdz-python)
