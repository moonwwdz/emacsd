;;; moonwwdz-dict.el --- Chinese-English dictionary lookup using https://dict.13140000.xyz  -*- lexical-binding: t; -*-

(require 'json)  ; 确保支持 JSON 解析（Emacs < 27 需要）

(defconst moonwwdz-dict-api-url "https://dict.13140000.xyz/api/query?q=%s"
  "API endpoint for dictionary lookup at https://dict.13140000.xyz.")

(defcustom moonwwdz-dict-buffer-name "*Moonwwdz Dictionary*"
  "Name of the buffer to display dictionary results."
  :type 'string
  :group 'moonwwdz-dict)

(defcustom moonwwdz-dict-default-word "hello"
  "Default word to look up if none provided."
  :type 'string
  :group 'moonwwdz-dict)

(defvar moonwwdz-dict-history nil
  "History list for word lookups.")


(defun moonwwdz-dict-lookup (word)
  "Query the dictionary API for WORD and display translation."
  (interactive
   (list (read-string "Word to look up: " nil 'moonwwdz-dict-history (thing-at-point 'word t))))
  (unless (string-trim word)
    (error "Empty word"))
  (let ((url-request-extra-headers '(("User-Agent" . "Emacs Elisp"))))
    (url-retrieve
     (format moonwwdz-dict-api-url (url-hexify-string word))
     'moonwwdz-dict--receive-callback
     (list word)
     t)))

(defun moonwwdz-dict--receive-callback (_status word)
  (goto-char (point-min))
  (re-search-forward "^$" nil 'move)
  (let ((json-text (decode-coding-string
                     (buffer-substring-no-properties (point) (point-max))
                     'utf-8))
        result data translation)
    (kill-buffer (current-buffer))
    (condition-case err
        (progn
          (setq result (json-read-from-string json-text))
          (setq data (alist-get 'data result))
          (setq translation (when data (alist-get 'translation data)))
          (if translation
              (moonwwdz-dict--show-result word (or data result))
            (moonwwdz-dict--show-error word "No translation available")))
      (error (moonwwdz-dict--show-error word (format "JSON parse error: %s" (error-message-string err)))))))


(defun moonwwdz-dict--show-result (word data)
  "Display the result in a buffer."
  (let ((buf (get-buffer-create moonwwdz-dict-buffer-name)))
    (with-current-buffer buf
      (setq buffer-read-only nil)
      (erase-buffer)
      (insert (format "Word: %s\n\n" word))
      (when-let* ((phonetic (alist-get 'phonetic data)))
        (insert (format "Phonetic: [%s]\n" phonetic)))
      (when-let* ((translation (alist-get 'translation data)))
        (insert (format "\nTranslation: %s\n" translation)))
      (when-let* ((definition (alist-get 'definition data)))
        (insert (format "\nDefinition: %s\n" definition)))
      (moonwwdz-dict-mode)
      (goto-char (point-min)))
    (pop-to-buffer buf)))

(defun moonwwdz-dict--show-error (word msg)
  "Show error message in the dictionary buffer."
  (let ((buf (get-buffer-create moonwwdz-dict-buffer-name)))
    (with-current-buffer buf
      (setq buffer-read-only nil)  ; 允许编辑
      (erase-buffer)
      (insert (format "❌ Lookup failed for '%s'\n\n%s" word msg))
      (moonwwdz-dict-mode)  ; 恢复 mode 和只读状态
      (goto-char (point-min)))
    (pop-to-buffer buf)))

;; Define a simple major mode for styling
(define-derived-mode moonwwdz-dict-mode special-mode "MoonDict"
  "Major mode for displaying dictionary results from moonwwdz-dict."
  (setq buffer-read-only t)
  (define-key moonwwdz-dict-mode-map (kbd "q") #'delete-window)
  (evil-local-set-key 'normal (kbd "q") #'delete-window))

;; Optional: Quick command to lookup word at point
(defun moonwwdz-dict-lookup-at-point ()
  "Look up the word at point."
  (interactive)
  (moonwwdz-dict-lookup (thing-at-point 'word t)))

;; Provide feature
(provide 'moonwwdz-dict)
