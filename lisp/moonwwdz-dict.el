;;; moonwwdz-dict.el --- Chinese-English dictionary lookup using https://dict.13140000.xyz

(require 'json)  ; 确保支持 JSON 解析（Emacs < 27 需要）

(defconst moonwwdz-dict-api-url "https://dict.13140000.xyz/api/query?word=%s"
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

(defvar moonwwdz-dict--last-result nil
  "Cache the last API result as an alist.")

(defun moonwwdz-dict-lookup (word)
  "Query the dictionary API for WORD and display translation."
  (interactive
   (list (read-string "Word to look up: " nil 'moonwwdz-dict-history (thing-at-point 'word t))))
  (unless (string-trim word)
    (error "Empty word"))
  (let ((url-request-extra-headers '(("User-Agent" . "Emacs Elisp"))))
    (url-retrieve
     (format moonwwdz-dict-api-url (url-encode-url word))
     'moonwwdz-dict--receive-callback
     (list word)
     nil
     (list (cons 'buffer-file-coding-system 'utf-8)))))

(defun moonwwdz-dict--receive-callback (status word)
  (declare (ignore status))
  (goto-char (point-min))
  (re-search-forward "^$" nil 'move)
  (let ((json-text (buffer-substring-no-properties (point) (point-max)))
        result translation)
    (kill-buffer (current-buffer))
    (set-buffer-file-coding-system 'utf-8)
    (condition-case err
        (progn
          (setq result (json-read-from-string json-text))
          (setq moonwwdz-dict--last-result result)
          (setq translation (alist-get 'translation result))
          (if translation
              (moonwwdz-dict--show-result word translation)
            (moonwwdz-dict--show-error word "No translation available")))
      (error (moonwwdz-dict--show-error word (format "JSON parse error: %s" (error-message-string err)))))))


(defun moonwwdz-dict--show-result (word translation)
  "Display the result in a buffer."
  (let ((buf (get-buffer-create moonwwdz-dict-buffer-name)))
    (with-current-buffer buf
      (setq buffer-read-only nil)  ; 临时允许编辑
      (erase-buffer)
      (insert (format "📘 Word: %s\n\n" word))
      (insert (format "📝 Translation: %s\n" translation))
      (when-let ((phonetic (alist-get 'phonetic (moonwwdz-dict--get-last-result))))
        (insert (format "\n🔊 Phonetic: [%s]\n" phonetic)))
      (moonwwdz-dict-mode)  ; 重新启用 mode（会再次设置 read-only）
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

(defun moonwwdz-dict--get-last-result ()
  "Return last parsed result."
  moonwwdz-dict--last-result)

;; Define a simple major mode for styling
(define-derived-mode moonwwdz-dict-mode special-mode "MoonDict"
  "Major mode for displaying dictionary results from moonwwdz-dict."
  (setq buffer-read-only t)
  (use-local-map (make-sparse-keymap)))

;; Optional: Quick command to lookup word at point
(defun moonwwdz-dict-lookup-at-point ()
  "Look up the word at point."
  (interactive)
  (moonwwdz-dict-lookup (thing-at-point 'word t)))

;; Provide feature
(provide 'moonwwdz-dict)
