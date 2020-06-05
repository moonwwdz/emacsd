;;golang 配置

;; go get github.com/rogpeppe/godef
;; go get golang.org/x/tools/cmd/goimports
;; go get -u github.com/nsf/gocode

;; (add-to-list 'load-path "~/.emacs.d/lisp/golang/goflymake")
;; (require 'go-flymake)
;; (add-to-list 'load-path "~/.emacs.d/lisp/golang/goflymake")
;; (require 'go-flycheck)

(require 'company-go)
(require 'go-eldoc)
(require 'go-mode)
(require 'auto-complete-config)
(require 'golint)
(ac-config-default)
(defun go-mode-setup ()
  (go-eldoc-setup)
  (setq indent-tabs-mode 1)
  (setq tab-width 4)
  (setq gofmt-command "goimports")
  (setq compile-command (format "go run %s" (file-name-nondirectory buffer-file-name)))
  ;; (setq compile-command "go build -v && go test -v && go vet")
  ;; (define-key (current-local-map) "\C-c\C-c" 'compile)
  (define-key (current-local-map) "\C-c\C-c" '(lambda()
						" go run file directly "
						(interactive)
						(compile compile-command)
						(switch-to-buffer-other-window "*compilation*")))

  (define-key (current-local-map) "\C-c\C-p" 'compile)
  
  (add-hook 'before-save-hook 'gofmt-before-save)
  (local-set-key (kbd "M-.") 'godef-jump))

(add-hook 'go-mode-hook 'go-mode-setup)

(provide 'moonwwdz-golang)
