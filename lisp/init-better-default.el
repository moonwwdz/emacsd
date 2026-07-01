;;; init-better-default.el --- 增强默认设置  -*- lexical-binding: t; -*-
(setq system-time-locale "C")
(when (find-font (font-spec :family "LXGW WenKai Mono Screen"))
  (let ((size (if (eq system-type 'darwin) 16 14)))
    (set-frame-font (format "LXGW WenKai Mono Screen %d" size) nil t)
    (set-face-attribute 'default nil :family "LXGW WenKai Mono Screen" :height 120)))

;; --group-directories-first 是 GNU ls 特性；macOS 自带 BSD ls 不支持，需用 gls
(cond
 ((and (eq system-type 'darwin) (executable-find "gls"))
  (setq insert-directory-program "gls"
        dired-listing-switches "-alh --group-directories-first"))
 ((eq system-type 'darwin)
  (setq dired-listing-switches "-alh"))
 (t
  (setq dired-listing-switches "-alh --group-directories-first")))
(setq dired-kill-when-opening-new-dired-buffer t) ; 进子目录复用 buffer，不堆积

(define-key global-map (kbd "RET") 'newline-and-indent)

(require 'hungry-delete)
(global-hungry-delete-mode)

;; hungry-delete 会在 sp-delete-pair 触发前清空空格，导致括号删不干净；提前调 sp 修正
(defun my/sp-delete-pair-before-hungry-delete (n &rest _)
  (save-match-data (sp-delete-pair n)))
(advice-add 'hungry-delete-backward :before #'my/sp-delete-pair-before-hungry-delete)
;;(electric-pair-mode 1)

(require 'smartparens-config)
(smartparens-global-mode t)

(setq auto-mode-alist
      (append
       '(("\\.js\\'" . js2-mode)
         ("\\.html\\'" . web-mode))
          auto-mode-alist))

;; 补全栈：vertico(纵向 UI) + orderless(模糊匹配) + marginalia(注解) + consult(命令)
(require 'vertico)
(vertico-mode 1)
(setq vertico-cycle t)
(require 'marginalia)
(marginalia-mode 1)
(require 'orderless)
(setq completion-styles '(orderless basic)
      completion-category-overrides '((file (styles partial-completion))))
(require 'savehist)   ; vertico 按历史排序依赖 savehist
(savehist-mode 1)
(require 'vertico-repeat)
(add-hook 'minibuffer-setup-hook #'vertico-repeat-save)

(require 'hl-todo)
(global-hl-todo-mode 1)

(with-eval-after-load 'grep (require 'wgrep)) ; 首次用 grep 时才载入，由 wgrep 自身挂钩

;; treesit-auto 会把 python/go/rust-mode 重映射到 *-ts-mode，而 lsp-bridge 挂在非 ts 版上，
;; 一旦 grammar 装好就会静默关掉这三门语言的 LSP，故从 auto-langs 中排除。
(when (treesit-available-p)
  (require 'treesit-auto)
  (setq treesit-auto-install 'prompt)
  (setq treesit-auto-langs
        (seq-difference treesit-auto-langs '(python go gomod rust)))
  (global-treesit-auto-mode 1))

(require 'popwin)
(popwin-mode t)

(require 'dired-x)
(setq dired-dwim-target t)

;; 备份集中到 ~/.emacs.d/backups/，自动保存到 auto-save/，不污染工作目录
(let ((backup-dir (expand-file-name "backups/" user-emacs-directory))
      (auto-save-dir (expand-file-name "auto-save/" user-emacs-directory)))
  (unless (file-directory-p backup-dir)    (make-directory backup-dir t))
  (unless (file-directory-p auto-save-dir) (make-directory auto-save-dir t))
  (setq backup-directory-alist `((".*" . ,backup-dir))
        auto-save-file-name-transforms `((".*" ,auto-save-dir t))
        make-backup-files t
        backup-by-copying t     ; 拷贝而非改名，保留硬链接与属主
        version-control t
        delete-old-versions t
        kept-new-versions 6
        kept-old-versions 2))

(require 'recentf)
(recentf-mode 1)
(setq recentf-max-menu-items 25)

(show-paren-mode t)
(global-auto-revert-mode 1)
(setq ring-bell-function 'ignore)
(setq mouse-yank-at-point t)
(setq select-enable-clipboard t)
(setq save-interprogram-paste-before-kill t)
(fset 'yes-or-no-p 'y-or-n-p)

(require 'ibuffer)
(setq ibuffer-saved-filter-groups
      (quote (("default"
               ("Dired" (mode . dired-mode))
               ("Markdown" (or
                            (name . "^diary$")
                            (mode . markdown-mode)))
               ("ReStructText" (mode . rst-mode))
               ("Python" (or (mode . python-mode)
                             (mode . ipython-mode)
                             (mode . inferior-python-mode)))
               ("Ruby" (or
                        (mode . ruby-mode)
                        (mode . enh-ruby-mode)
                        (mode . inf-ruby-mode)))))))

(setq-default tab-width 4)
(setq-default indent-tabs-mode nil)
(setq c-basic-offset 4)

(defun remove-dos-eol ()
  "Replace DOS eolns CR LF with Unix eolns CR."
  (interactive)
  (goto-char (point-min))
  (while (search-forward "\r" nil t) (replace-match "")))

(defun my-web-mode-indent-setup ()
  (setq web-mode-markup-indent-offset 2)
  (setq web-mode-css-indent-offset 2)
  (setq web-mode-code-indent-offset 2))

(add-hook 'web-mode-hook 'my-web-mode-indent-setup)

(defun my-toggle-web-indent ()
  (interactive)
  (if (or (eq major-mode 'js-mode) (eq major-mode 'js2-mode))
      (progn
        (setq js-indent-level (if (= js-indent-level 2) 4 2))
        (setq js2-basic-offset (if (= js2-basic-offset 2) 4 2))))
  (if (eq major-mode 'web-mode)
      (progn (setq web-mode-markup-indent-offset (if (= web-mode-markup-indent-offset 2) 4 2))
             (setq web-mode-css-indent-offset (if (= web-mode-css-indent-offset 2) 4 2))
             (setq web-mode-code-indent-offset (if (= web-mode-code-indent-offset 2) 4 2))))
  (if (eq major-mode 'css-mode)
      (setq css-indent-offset (if (= css-indent-offset 2) 4 2)))
  (setq indent-tabs-mode nil))

(defun occur-dwim ()
  "Call `occur' with a sane default."
  (interactive)
  (push (if (region-active-p)
            (buffer-substring-no-properties
             (region-beginning)
             (region-end))
          (let ((sym (thing-at-point 'symbol)))
            (when (stringp sym)
              (regexp-quote sym))))
        regexp-history)
  (call-interactively 'occur))

(defun js2-imenu-make-index ()
      (interactive)
      (save-excursion
        (imenu--generic-function '(("describe" "\\s-*describe\\s-*(\\s-*[\"']\\(.+\\)[\"']\\s-*,.*" 1)
                                   ("it" "\\s-*it\\s-*(\\s-*[\"']\\(.+\\)[\"']\\s-*,.*" 1)
                                   ("test" "\\s-*test\\s-*(\\s-*[\"']\\(.+\\)[\"']\\s-*,.*" 1)
                                   ("before" "\\s-*before\\s-*(\\s-*[\"']\\(.+\\)[\"']\\s-*,.*" 1)
                                   ("after" "\\s-*after\\s-*(\\s-*[\"']\\(.+\\)[\"']\\s-*,.*" 1)
                                   ("Function" "function[ \t]+\\([a-zA-Z0-9_$.]+\\)[ \t]*(" 1)
                                   ("Function" "^[ \t]*\\([a-zA-Z0-9_$.]+\\)[ \t]*=[ \t]*function[ \t]*(" 1)
                                   ("Function" "^var[ \t]*\\([a-zA-Z0-9_$.]+\\)[ \t]*=[ \t]*function[ \t]*(" 1)
                                   ("Function" "^[ \t]*\\([a-zA-Z0-9_$.]+\\)[ \t]*()[ \t]*{" 1)
                                   ("Function" "^[ \t]*\\([a-zA-Z0-9_$.]+\\)[ \t]*:[ \t]*function[ \t]*(" 1)
                                   ("Task" "[. \t]task([ \t]*['\"]\\([^'\"]+\\)" 1)))))
(add-hook 'js2-mode-hook
              (lambda ()
                (setq imenu-create-index-function 'js2-imenu-make-index)))

;; i3 等无 KDE 的桌面下 gpg-agent 会回退到 pinentry-curses/tty，GUI Emacs 无终端看不到弹框；
;; loopback 让 GPG 解密走 minibuffer，需配合 ~/.gnupg/gpg-agent.conf allow-loopback-pinentry
(setq epg-pinentry-mode 'loopback)

;; C-x p b 改用 consult-project-buffer；两层延迟加载，不强制 require project/consult
(with-eval-after-load 'project
  (with-eval-after-load 'consult
    (define-key project-prefix-map "b" #'consult-project-buffer)))

(provide 'init-better-default)
