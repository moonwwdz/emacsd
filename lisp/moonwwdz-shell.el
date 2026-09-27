;;; moonwwdz-shell.el --- Shell 脚本配置  -*- lexical-binding: t; -*-
;;shell配置

;; C-c C-c 运行当前脚本。compile-command 必须 buffer-local：全局 setq 会让
;; 后打开的脚本覆盖先打开的，回到前一个 buffer 按 C-c C-c 会跑错脚本。
;; 调用时再算命令：已可执行（有 shebang，保存时自动 chmod +x）直接执行以尊重
;; shebang，否则用 bash。
(defun moonwwdz-shell-run ()
  "运行当前 shell 脚本（经 `compile'，可在提示里修改命令）。"
  (interactive)
  (when buffer-file-name
    (let ((name (shell-quote-argument (file-name-nondirectory buffer-file-name))))
      (setq-local compile-command
                  (if (file-executable-p buffer-file-name)
                      (concat "./" name)
                    (concat "bash " name)))))
  (call-interactively #'compile))

;; treesit-auto 装好 bash grammar 后 .sh 会进 bash-ts-mode，它不跑 sh-mode-hook、
;; 也不用 sh-mode-map，所以键位两边都绑，钩子挂两者共同的父模式 sh-base-mode。
(with-eval-after-load 'sh-script
  (define-key sh-mode-map (kbd "C-c C-c") #'moonwwdz-shell-run)
  (when (boundp 'bash-ts-mode-map)
    (define-key bash-ts-mode-map (kbd "C-c C-c") #'moonwwdz-shell-run)))

(add-hook 'sh-base-mode-hook
          (lambda () (add-hook 'after-save-hook
                               #'executable-make-buffer-file-executable-if-script-p
                               nil t)))


(provide 'moonwwdz-shell)
