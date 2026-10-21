;;; moonwwdz-helper.el --- 通用辅助函数  -*- lexical-binding: t; -*-
;; 打开/关闭粘贴模式，粘贴模式下没有自动补全和自动缩进
;; org 全部延迟加载（init-org.el 记录的启动优化）：本文件启动期不 require 任何
;; org 家族，org/org-datetree 由工作日志命令在 my/work-journal-with-date 内按需
;; 加载（org 顶层即加载 org-macs，宏内可直接用 org-with-wide-buffer）
(defvar smartparens-mode)                             ; smartparens-mode 变量（if 条件判断）
(defvar org-not-done-keywords)                        ; org 变量（carry-over 收集未完成 TODO 用）
(declare-function smartparens-mode "smartparens" (&optional arg)) ; 函数（启用/关闭粘贴补全）

;; 工作日志文件单一事实来源：下面三个命令与 init-org.el 的 l/L/w/T capture
;; 模板、wc/ww agenda 视图共用（模板与 agenda settings 都是符号引用，运行期取值）
(defvar moonwwdz-work-journal-file "~/Documents/emacsNotes/org/work-journal.org"
  "工作日志文件（datetree by day）。")

(defun moonwwdz-toggle-paste-helper()
  (interactive)
  (if smartparens-mode
	  (progn
		(smartparens-mode -1)
		(electric-indent-local-mode -1)
		(message "Paste mode enabled"))
	(progn
	  (smartparens-mode 1)
	  (electric-indent-local-mode 1)
	  (message "Paste mode disabled"))))
;; 各语言 C-c C-c/C-b/C-t/C-k 共用：编译并切到 *compilation* 窗口
(defun moonwwdz-compile (cmd)
  "运行 CMD 并选中 *compilation* 窗口。"
  (compile cmd)
  (switch-to-buffer-other-window "*compilation*"))

;; 工作日志命令共用的前奏：按需加载 org（维持启动延迟加载）、打开日志文件、
;; 定位（不存在则创建）DATE 的 datetree 日节点，BODY 在 wide-buffer 下执行；
;; 结束后自动保存（org-datetree 可能刚创建年/月/日三级节点），返回 BODY 最后一式的值
(defmacro my/work-journal-with-date (date &rest body)
  "在 `moonwwdz-work-journal-file' 的 DATE 日节点上下文中执行 BODY。"
  (declare (indent 1))
  `(progn
     (require 'org)                ; org 顶层即加载 org-macs，org-with-wide-buffer 可直接用
     (require 'org-datetree)
     (with-current-buffer (find-file-noselect moonwwdz-work-journal-file)
       (prog1
           (org-with-wide-buffer
            (org-datetree-find-date-create ,date)
            ,@body)
         (save-buffer)))))

(defun moonwwdz-work-log-quick (&optional todo)
  "一键追加一行工作日志到今天的 datetree 节点（走 init-org.el 的 l/L 模板，
:immediate-finish 免进 capture buffer，不切换当前 buffer）。
带 C-u 前缀（TODO 非 nil）时插入为 TODO 条目，便于 carry-over 跟进未完成项。"
  (interactive "P")
  (org-capture nil (if todo "L" "l")))

(defun moonwwdz-capture-work (&optional timed)
  "一键进入工作日志 capture，跳过 C-c c 模板选择菜单，直接使用 w 模板。
适合需要写标题和多行正文的详细条目。
带 C-u 前缀 TIMED 时改用计时模板 T：自动 clock-in 并标记 TODO，用于记工时。"
  (interactive "P")
  (org-capture nil (if timed "T" "w")))

(defun moonwwdz-work-journal-today ()
  "打开 work-journal.org 并跳到今天的 datetree 节点（不存在则创建）。
用于快速回顾当日记录的工作流水。"
  (interactive)
  (require 'calendar)
  ;; 定位结果取 marker（org-with-wide-buffer 会还原 point），跳转与滚动放到
  ;; 宏外：switch-to-buffer 若在宏的 save-excursion 内执行，窗口显示与当前
  ;; 缓冲会错位，dedicated 窗口（编译/gdb）下更是直接报错
  (let* ((res (my/work-journal-with-date (calendar-current-date)
               (org-back-to-heading t)
               (cons (current-buffer) (point-marker))))
         (buf (car res))
         (pos (cdr res)))
    (switch-to-buffer buf)
    (goto-char pos)
    (set-marker pos nil)
    ;; org-reveal 在 Emacs 30 已含「展开当前条目」：标题行、祖先、正文一并处理
    (org-reveal)
    (recenter)))

(defun my/work-journal--plain-title (title)
  "去掉标题行中的来源标注 (← MM-DD)，供幂等去重比较。
不锚定行尾：带 org 标签的标题标注位于标签之前（中间位置）。"
  (replace-regexp-in-string "[ \t]*(← [0-9]\\{2\\}-[0-9]\\{2\\})" "" title))

(defun my/work-journal--tagged-heading (heading from-tag)
  "给标题行追加来源标注 FROM-TAG。
标题带 org 标签时插到标签之前（标签必须位于行尾才被识别，追加在其后会破坏标签）。"
  (if (string-match "[ \t]+\\(:[[:alnum:]_@#%:]+:\\)[ \t]*\\'" heading)
      (replace-match (concat " " from-tag " " (match-string 1 heading))
                     t t heading)
    (concat heading " " from-tag)))

(defun my/work-journal--strip-clock (text)
  "剥离子树文本 :LOGBOOK: 里的 CLOCK 行与只剩空壳的 LOGBOOK。
副本保留 CLOCK 会让 clock report 把同一段工时计两次，未关闭的 CLOCK
还会成为悬空运行时钟。"
  (with-temp-buffer
    (insert text)
    (goto-char (point-min))
    (flush-lines "^[ \t]*CLOCK: \\[[0-9]")
    (goto-char (point-min))
    (while (re-search-forward "^[ \t]*:LOGBOOK:\n[ \t]*:END:\n?" nil t)
      (replace-match ""))
    (buffer-string)))

(defun my/work-journal--top-todo-p ()
  "point 在标题行上：条目为未完成 TODO 且祖先链上没有未完成 TODO 祖先。
有未完成 TODO 祖先的深层条目随父条目子树整体带走，不单独收集。
（不用 org-map-entries 的 match 扫描：它走 org-scan-tags 会 require 整个
org-agenda，违背 org 按需加载；祖先链要逐层检查，只看直接父级会漏）"
  (and (member (org-get-todo-state) org-not-done-keywords)
       (save-excursion
         (let (skip)
           (while (and (not skip) (org-up-heading-safe))
             (when (member (org-get-todo-state) org-not-done-keywords)
               (setq skip t)))
           (not skip)))))

(defun moonwwdz-work-journal-carry-over ()
  "将今天工作日志中未完成的 TODO 条目复制到明天的 datetree 节点（次日继续跟进）。
原条目保留不动；副本剥离 :LOGBOOK: 的 CLOCK 记录、按明天日节点重新定级，
来源日期 (← MM-DD) 标注在 org 标签之前；幂等——明天节点已有同标题（忽略来源
标注）的条目跳过，条目原带旧来源标注时替换为本次日期，不逐日累积。"
  (interactive)
  (require 'calendar)   ; calendar-current-date 等非 autoload，cold 会话首次调用需显式加载
  (let* ((today (calendar-current-date))
         (tomorrow (calendar-current-date 1)) ; 内建 offset 参数即「N 天后」，省去绝对日期往返
         ;; 来源日期跟随今天节点而非墙上时钟，跨零点执行不漂移
         (from-tag (format "(← %02d-%02d)" (nth 0 today) (nth 1 today)))
         ;; 收集今天节点下所有「顶层」未完成 TODO 子树；收集过的整树直接跳过。
         ;; 每项存 (纯标题 . 其余文本)：标题用 org-get-heading（无星号前缀），
         ;; 与 existing 侧的同源取法对齐，幂等比较才比得中
         (items (my/work-journal-with-date today
                  (org-back-to-heading t)
                  (let ((bound (save-excursion
                                 (org-end-of-subtree t)
                                 (point)))
                        acc)
                    (save-excursion
                      (while (and (outline-next-heading) (< (point) bound))
                        (when (my/work-journal--top-todo-p)
                          (push (list (org-outline-level)
                                      (org-get-heading)
                                      (my/work-journal--strip-clock
                                       (buffer-substring-no-properties
                                        (line-end-position)
                                        (save-excursion
                                          (org-end-of-subtree t)
                                          (point)))))
                                acc)
                          (org-end-of-subtree t)))
                      (nreverse acc)))))
         (inserted 0)
         (skipped 0))
    (when items
      (my/work-journal-with-date tomorrow
        (org-back-to-heading t)
        (let* ((bound (save-excursion (org-end-of-subtree t) (point)))
               ;; 明天节点已有条目的核心标题（去来源标注），幂等去重基准
               (existing
                (save-excursion
                  (let (titles)
                    (while (and (outline-next-heading) (< (point) bound))
                      (push (my/work-journal--plain-title (org-get-heading)) titles))
                    titles)))
               ;; 副本统一挂在日节点下一级（与 org-capture entry 同级）
               (target (1+ (org-outline-level))))
          (save-excursion
            (goto-char bound)
            (dolist (it items)
              (let ((level (nth 0 it))
                    (heading (nth 1 it))
                    (rest (nth 2 it)))
                (if (member (my/work-journal--plain-title heading) existing)
                    (setq skipped (1+ skipped))
                  (let ((start (point)))
                    ;; 顶层按原层级写星号（子树内部相对层级随之原样保留），
                    ;; 再整体平移到 target 级。forward-line 落到新条目标题行首
                    ;; （前导 \n 由我们插入，位置确定）：back-to-heading 会回溯
                    ;; 到上一条目子树的最后一个标题上，promote 打错对象
                    (insert "\n" (make-string level ?*) " "
                            (my/work-journal--tagged-heading
                             (my/work-journal--plain-title heading) from-tag)
                            rest "\n")
                    (save-excursion
                      (goto-char start)
                      (forward-line 1)
                      (let ((delta (- target (org-outline-level))))
                        (if (> delta 0)
                            (dotimes (_ delta) (org-demote-subtree))
                          (dotimes (_ (- delta)) (org-promote-subtree))))))
                  (setq inserted (1+ inserted)))))))))
    (message "carry-over: 带入 %d 条，跳过已存在 %d 条" inserted skipped)))


(defun moonwwdz-org-insert-custom-headlines ()
(interactive)
  (save-excursion
    (let ((headline-text (nth 4 (org-heading-components)))
          (custom-text '("首次学习" "隔天的复习" "三天的复习" "七天的复习" "半个月的复习" "一个月的复习" "三个月的复习" "六个月的复习"))
          (memory-curve-days '(0 1 4 11 26 56 146 266)))
      (org-metaright)
      (org-end-of-line)
      (dotimes (i 8)
        (org-insert-heading-respect-content)
        (let ((timestamp (format-time-string "<%Y-%m-%d %a 21:00>" (time-add (current-time) (* (nth i memory-curve-days) 86400)))))
          (insert (format "TODO  %s-%s %s"  (nth i custom-text) headline-text timestamp))))))
  (org-metaleft))

(defun moonwwdz-insert-current-week ()
  (interactive)
  (insert (format-time-string "** 第 %V 周 \n 1. ")))

;; 切换主题
(defun moonwwdz-toggle-theme ()
  "Toggle between modus-operandi and modus-vivendi themes."
  (interactive)
  (if (custom-theme-enabled-p 'modus-operandi)
      (progn
        (disable-theme 'modus-operandi)
        (load-theme 'modus-vivendi t))
    (progn
      (disable-theme 'modus-vivendi)
      (load-theme 'modus-operandi t))))

;; 选择一个文件，将文件的全部内容插入到当前光标位置"
(defun moonwwdz-insert-file-content-at-point ()
  (interactive)
  (let ((file-path (read-file-name "select one note: " "~/Documents/org-roam/")))
    (when (file-exists-p file-path)
      (insert-file-contents file-path))))


;; 对存量文本批量在中文与英文/数字边界补空格
;; （wraplish 只处理实时输入，无法处理打开的旧文件；此命令弥补这个空缺）
(defun moonwwdz-space-cjk-ascii ()
  "在当前 region（未选中则整个 buffer）的中文与英文/数字边界插入空格。
中文与英数相邻、英数与中文相邻各补一个空格；已有空格的不重复处理。"
  (interactive)
  (save-restriction
    (narrow-to-region (if (use-region-p) (region-beginning) (point-min))
                      (if (use-region-p) (region-end) (point-max)))
    (save-excursion
      (goto-char (point-min))
      ;; 中文 + 英数 -> 中文 空格 英数
      (while (re-search-forward "\\([一-龥]+\\)\\([0-9A-Za-z]+\\)" nil t)
        (replace-match "\\1 \\2"))
      (goto-char (point-min))
      ;; 英数 + 中文 -> 英数 空格 中文
      (while (re-search-forward "\\([0-9A-Za-z]+\\)\\([一-龥]+\\)" nil t)
        (replace-match "\\1 \\2")))))

;;;; 网络代理：本地 7890 存活则走代理，不在则直连
(defvar my/proxy-host "127.0.0.1")
(defvar my/proxy-port 7890)

(defun my/proxy-available-p ()
  "探测本地代理端口是否有服务在监听。"
  (condition-case nil
      (let ((proc (open-network-stream " *proxy-probe*" nil
                                       my/proxy-host my/proxy-port
                                       :timeout 1)))
        (prog1 (process-live-p proc)
          (delete-process proc)))
    ((error quit) nil)))

(defun my/setup-proxy ()
  "按本地代理存活情况设置 Emacs 出网代理。
存活时两层都指向代理：url-proxy-services（package.el、url-retrieve
等 Emacs url 层）与 http(s)_proxy 环境变量（git clone 装 tree-sitter
grammar、lsp-bridge 的 python 子进程等）；不在则全部清空直连。
localhost 始终不走代理。"
  (interactive)
  (if (my/proxy-available-p)
      (let ((addr (format "%s:%d" my/proxy-host my/proxy-port)))
        (setq url-proxy-services
              `(("http" . ,addr)
                ("https" . ,addr)
                ("no_proxy" . "localhost,127.0.0.1")))
        (setenv "http_proxy" (concat "http://" addr))
        (setenv "https_proxy" (concat "http://" addr))
        (setenv "no_proxy" "localhost,127.0.0.1")
        (message "proxy on: %s" addr))
    (setq url-proxy-services nil)
    (setenv "http_proxy" nil)
    (setenv "https_proxy" nil)
    (setenv "no_proxy" nil)
    (message "proxy off, direct connection")))

;; 启动时设置一次；联网操作前重新探测，中途开关代理也能自适应
(require 'url-vars)
(my/setup-proxy)
(dolist (fn '(treesit-install-language-grammar
              package-refresh-contents
              package-install))
  (advice-add fn :before
              (lambda (&rest _) (my/setup-proxy))))

(provide 'moonwwdz-helper)
