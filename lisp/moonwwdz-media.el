;;; moonwwdz-media.el --- 电影库（NFO）管理：扫描、展示、编辑  -*- lexical-binding: t; -*-

;;; Commentary:
;; 面向「一文件夹一部电影」的 NFO 电影库（Kodi/Jellyfin/Emby/TMM 刮削产物）。
;;
;; 提供三类操作：
;;   1. 列表视图（tabulated-list）：可排序、可按标题/年份/类型/导演子串过滤。
;;   2. 详情视图：海报 + 元数据 + 简介 + 背景图（本地优先，可选按 nfo 内 URL 下载）。
;;   3. NFO 编辑：`e' 直接打开原始 nfo（nxml-mode）；`E' 表单式逐字段写回 XML。
;;
;; 入口：M-x moonwwdz-media（默认读 `moonwwdz-media-root-dir'，带前缀强制提示）。
;; 文件配对策略（同一目录内）：movie.nfo > 与视频同名的 nfo > 目录内唯一 nfo；
;; 视频文件同理三级回退；图片按 poster/-poster/folder/cover/thumb 等候选优先级查找。

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'xml)
(require 'dom)
(require 'image)
(require 'seq)
(require 'url)
(require 'tabulated-list)

;; evil 为外部包（运行时由 git-package.el 加载），声明函数以消除 byte-compile 警告。
(declare-function evil-define-key "evil" (state map key def &rest bindings))
(declare-function evil-set-initial-state "evil" (mode state))
;; w32-shell-execute 仅 Windows 内建，声明以消除非 Windows 平台的 byte-compile 警告。
(declare-function w32-shell-execute "w32fns.c" (operation document &optional parameters show-flag))

;;;; 配置项

(defgroup moonwwdz-media nil
  "电影库（NFO）管理。"
  :group 'convenience)

(defcustom moonwwdz-media-root-dir nil
  "电影库根目录。
设为 nil 时，`moonwwdz-media' 命令会提示输入目录。"
  :type '(choice (directory :tag "目录") (const :tag "每次提示" nil))
  :group 'moonwwdz-media)

(defcustom moonwwdz-media-video-extensions
  '("mkv" "mp4" "avi" "mov" "wmv" "flv" "ts" "m4v" "webm" "mpg" "mpeg" "rmvb" "rm" "iso")
  "视频文件扩展名（不含点，小写）。"
  :type '(repeat string)
  :group 'moonwwdz-media)

(defcustom moonwwdz-media-player-command
  (cond ((eq system-type 'darwin) "open")
        ((eq system-type 'windows-nt) "start")
        (t "mpv"))
  "播放视频的外部命令。
macOS 默认 `open'（用系统默认播放器）；Linux 默认 `mpv'；
Windows 默认哨兵值 \"start\"——非真实程序，会走 `w32-shell-execute' 用系统关联程序打开。
想指定播放器直接改本项，例如设为 \"mpv\"。"
  :type 'string
  :group 'moonwwdz-media)

(defcustom moonwwdz-media-player-args nil
  "传给 `moonwwdz-media-player-command' 的固定参数列表。
视频路径会追加在这些参数之后。"
  :type '(repeat string)
  :group 'moonwwdz-media)

(defcustom moonwwdz-media-poster-width 300
  "详情视图海报最大宽度（像素）。"
  :type 'integer
  :group 'moonwwdz-media)

(defcustom moonwwdz-media-fanart-width 600
  "详情视图背景图（fanart）最大宽度（像素）。设为 0 不显示。"
  :type 'integer
  :group 'moonwwdz-media)

(defcustom moonwwdz-media-max-actors 10
  "详情视图最多显示的演员数量。"
  :type 'integer
  :group 'moonwwdz-media)

(defcustom moonwwdz-media-cache-dir
  (expand-file-name ".cache/moonwwdz-media/" user-emacs-directory)
  "从 nfo 内 URL 下载图片的缓存目录。"
  :type 'directory
  :group 'moonwwdz-media)

(defcustom moonwwdz-media-fetch-remote-images t
  "本地无图片时，是否按 nfo 内 <thumb>/<fanart> 的 URL 下载并缓存展示。"
  :type 'boolean
  :group 'moonwwdz-media)

(defcustom moonwwdz-media-image-extensions
  '("jpg" "jpeg" "png" "webp")
  "图片文件扩展名（小写，不含点）。"
  :type '(repeat string)
  :group 'moonwwdz-media)

;;;; 常量与 buffer-local 状态

(defconst moonwwdz-media-list-buffer-name "*Moonwwdz Movies*"
  "列表视图 buffer 名。")

(defconst moonwwdz-media-detail-buffer-name "*Moonwwdz Movie Detail*"
  "详情视图 buffer 名。")

(defvar-local moonwwdz-media--root nil
  "当前列表 buffer 对应的电影库根目录。")

(defvar-local moonwwdz-media--movies nil
  "当前列表 buffer 的全量电影列表（过滤前）。")

(defvar-local moonwwdz-media--filter nil
  "当前列表 buffer 的过滤字符串（nil 表示无过滤）。")

(defvar-local moonwwdz-media--last-width nil
  "上次重排列宽时的窗口宽度，用于检测窗口大小变化。")

(defvar-local moonwwdz-media--synced-movie nil
  "上次同步到详情的 movie，列表光标移动时据此去重。")

(defvar-local moonwwdz-media--detail-movie nil
  "当前详情 buffer 展示的电影。")

;;;; Faces

(defface moonwwdz-media-title-face
  '((t :inherit bold :height 1.4))
  "详情视图标题外观。"
  :group 'moonwwdz-media)

(defface moonwwdz-media-field-face
  '((t :inherit font-lock-keyword-face))
  "详情视图字段标签外观。"
  :group 'moonwwdz-media)

(defface moonwwdz-media-value-face
  '((t :inherit default))
  "详情视图字段值外观。"
  :group 'moonwwdz-media)

(defface moonwwdz-media-dim-face
  '((t :inherit shadow))
  "详情视图次要信息（年份、原名、文件大小等）外观。"
  :group 'moonwwdz-media)

(defface moonwwdz-media-section-face
  '((t :inherit font-lock-type-face :weight bold))
  "详情视图分区标题外观。"
  :group 'moonwwdz-media)

(defface moonwwdz-media-tag-face
  '((t :inherit font-lock-constant-face :box (:line-width -1)))
  "类型 / 标签徽章外观（横向展示）。"
  :group 'moonwwdz-media)

;;;; 数据模型

(cl-defstruct (moonwwdz-media-movie
               (:copier nil))
  "一部电影的元数据。"
  title originaltitle year plot outline rating rating-source rating-votes
  runtime genres director credits studio mpaa countries premiered tags
  actors nfo-path video-path poster-path fanart-path dir)

;;;; XML / NFO 解析

(defun moonwwdz-media--xml-file-to-dom (file)
  "读取 FILE 为 XML，返回根元素 dom 节点；失败或不可读返回 nil。"
  (when (file-readable-p file)
    (condition-case err
        (with-temp-buffer
          ;; 用 utf-8（而非 utf-8-unix）自动识别并转换 CRLF，避免 Windows
          ;; 刮削器产出的 nfo 在多行 <plot> 中残留 ^M。
          (let ((coding-system-for-read 'utf-8))
            (insert-file-contents file))
          (when (eq (char-after 1) ?﻿) ; 跳过 UTF-8 BOM
            (delete-char 1))
          (car (xml-parse-region (point-min) (point-max))))
      (error
       (message "moonwwdz-media: 解析 %s 失败：%s" file (error-message-string err))
       nil))))

(defun moonwwdz-media--text (dom tag)
  "取 DOM 下第一个 TAG 节点的纯文本（trim 后）；无则空串。"
  (let ((node (car (dom-by-tag dom tag))))
    (if node (string-trim (dom-text node)) "")))

(defun moonwwdz-media--multi-text (dom tag)
  "取 DOM 下所有 TAG 节点的文本列表（每个已 trim，过滤空值）。"
  (let (result)
    (dolist (node (dom-by-tag dom tag))
      (let ((txt (string-trim (dom-text node))))
        (unless (string-empty-p txt)
          (push txt result))))
    (nreverse result)))

(defun moonwwdz-media--rating-node (dom)
  "返回 DOM 下的 rating 节点（兼容 <ratings><rating> 与老式 <rating>）。
<ratings> 下有多个 <rating> 时，优先返回 default=\"true\" 的节点。"
  (let ((ratings-node (car (dom-by-tag dom 'ratings))))
    (if ratings-node
        (let ((ratings (dom-by-tag ratings-node 'rating)))
          (or (seq-find (lambda (r)
                          (member (dom-attr r 'default) '("true" "1")))
                        ratings)
              (car ratings)))
      (car (dom-by-tag dom 'rating)))))

(defun moonwwdz-media--parse-rating (dom)
  "解析评分值。优先 <ratings><rating><value>，回退老式裸 <rating>。"
  (let ((node (moonwwdz-media--rating-node dom)))
    (if node
        (let ((value-node (car (dom-by-tag node 'value))))
          ;; 现代结构取 <value>；老式裸 <rating>7.5</rating> 无 <value>，
          ;; 回退取节点自身文本（旧版 dom-text 会拼上子节点文本，但裸
          ;; rating 没有子元素，等价于直接读数值）。
          (string-trim (if value-node (dom-text value-node) (dom-text node))))
      "")))

(defun moonwwdz-media--rating-source (dom)
  "评分来源（themoviedb/imdb 等），取 rating 节点 name 属性。"
  (let ((node (moonwwdz-media--rating-node dom)))
    (or (and node (dom-attr node 'name)) "")))

(defun moonwwdz-media--rating-votes (dom)
  "评分票数。"
  (let ((node (moonwwdz-media--rating-node dom)))
    (if node (moonwwdz-media--text node 'votes) "")))

(defun moonwwdz-media--parse-actors (dom)
  "解析演员列表，元素形如 \"姓名\" 或 \"姓名 (角色)\"。"
  (let (result)
    (dolist (node (dom-by-tag dom 'actor))
      (let ((name (moonwwdz-media--text node 'name))
            (role (moonwwdz-media--text node 'role)))
        (unless (string-empty-p name)
          (push (if (string-empty-p role) name (format "%s (%s)" name role))
                result))))
    (nreverse result)))

(defun moonwwdz-media--runtime-display (runtime)
  "美化时长：纯数字追加 min，其余原样返回。"
  (let ((r (string-trim runtime)))
    (if (and (not (string-empty-p r))
             (string-match-p "\\`[0-9]+\\'" r))
        (concat r "min")
      r)))

(defun moonwwdz-media--parse-movie (dom nfo-path dir)
  "从 DOM 构造 movie 对象，附加来源 NFO-PATH 和 DIR。"
  (let* ((base (file-name-base nfo-path))
         (movie (make-moonwwdz-media-movie
                 :title (moonwwdz-media--text dom 'title)
                 :originaltitle (moonwwdz-media--text dom 'originaltitle)
                 :year (moonwwdz-media--text dom 'year)
                 :plot (moonwwdz-media--text dom 'plot)
                 :outline (moonwwdz-media--text dom 'outline)
                 :rating (moonwwdz-media--parse-rating dom)
                 :rating-source (moonwwdz-media--rating-source dom)
                 :rating-votes (moonwwdz-media--rating-votes dom)
                 :runtime (moonwwdz-media--text dom 'runtime)
                 :genres (moonwwdz-media--multi-text dom 'genre)
                 :director (string-join (moonwwdz-media--multi-text dom 'director) " / ")
                 :credits (string-join (moonwwdz-media--multi-text dom 'credits) " / ")
                 :studio (string-join (moonwwdz-media--multi-text dom 'studio) " / ")
                 :mpaa (moonwwdz-media--text dom 'mpaa)
                 :countries (moonwwdz-media--multi-text dom 'country)
                 :premiered (moonwwdz-media--text dom 'premiered)
                 :tags (moonwwdz-media--multi-text dom 'tag)
                 :actors (moonwwdz-media--parse-actors dom)
                 :nfo-path nfo-path
                 :dir dir
                 :video-path (moonwwdz-media--find-video dir base)
                 :poster-path (moonwwdz-media--find-poster dir base)
                 :fanart-path (moonwwdz-media--find-fanart dir base))))
    ;; 标题为空时用目录名兜底，避免列表出现空行
    (when (string-empty-p (moonwwdz-media-movie-title movie))
      (setf (moonwwdz-media-movie-title movie)
            (file-name-nondirectory (directory-file-name dir))))
    movie))

(defun moonwwdz-media--parse-movie-from-file (nfo-path)
  "从 NFO 文件构造 movie 对象；根节点非 <movie> 或解析失败返回 nil。
借此跳过 tvshow.nfo / episodedetails / album.nfo 等非电影 nfo。"
  (let ((dom (moonwwdz-media--xml-file-to-dom nfo-path)))
    (when (and dom (eq (dom-tag dom) 'movie))
      (moonwwdz-media--parse-movie dom nfo-path (file-name-directory nfo-path)))))

;;;; 文件配对（视频 / 海报 / 背景图）

(defun moonwwdz-media--directory-files (dir)
  "返回 DIR 下所有文件的完整路径列表（不含 . ..）。"
  (when (file-directory-p dir)
    (directory-files dir t directory-files-no-dot-files-regexp)))

(defconst moonwwdz-media--extra-video-regexp
  (rx (or "-trailer" "-sample" "-clip" "-scene" "-featurette"
          "-behindthescenes" "-deleted" "-interview" "-short" "-extra")
      string-end)
  "预告片/样片/花絮等附属视频文件名（basename）特征，回退选片时排除。")

(defun moonwwdz-media--find-video (dir base)
  "在 DIR 找视频文件，优先与 BASE 同名；否则取第一个正片（排除预告/样片/花絮）。"
  (let* ((all (moonwwdz-media--directory-files dir))
         (vids (cl-remove-if-not
                (lambda (f)
                  (member (downcase (or (file-name-extension f) ""))
                          moonwwdz-media-video-extensions))
                all))
         (features (cl-remove-if
                    (lambda (f)
                      (string-match-p moonwwdz-media--extra-video-regexp
                                      (downcase (file-name-base f))))
                    vids)))
    (or (cl-find-if (lambda (f) (string= (file-name-base f) base)) vids)
        (car features)
        (car vids))))

(defun moonwwdz-media--find-image-by-names (dir names)
  "在 DIR 按候选文件名（NAMES，不含扩展名）优先级找第一张存在的图片。"
  (cl-loop for name in names
           for cand = (cl-loop for ext in moonwwdz-media-image-extensions
                               for path = (expand-file-name (concat name "." ext) dir)
                               when (file-regular-p path) return path)
           when cand return cand))

(defun moonwwdz-media--find-poster (dir base)
  "在 DIR 找海报图。
候选包含固定名（poster/folder/cover…）与 <base>-poster/<base>-thumb/<base> 三种
基于 nfo 名的形式（Kodi/TMM 标准命名）。"
  (moonwwdz-media--find-image-by-names
   dir (append '("poster" "folder" "cover" "thumb" "default" "movie" "title")
               (list (concat base "-poster")
                     (concat base "-thumb")
                     base))))

(defun moonwwdz-media--find-fanart (dir base)
  "在 DIR 找背景图（fanart）。"
  (moonwwdz-media--find-image-by-names
   dir (append '("fanart" "background" "backdrop" "art")
               (list (concat base "-fanart")))))

;;;; 递归扫描

(defun moonwwdz-media--nfo-priority (nfo)
  "同目录多个 nfo 时的优先级：movie.nfo(0) > 其它(1)。数值越小越优先。"
  (if (string-equal-ignore-case (file-name-nondirectory nfo) "movie.nfo") 0 1))

(defun moonwwdz-media--scan (root)
  "递归扫描 ROOT 下所有 <movie> nfo，返回按标题排序的 movie 列表。
同一目录出现多个 nfo（如 movie.nfo 与 <视频名>.nfo）时按 `moonwwdz-media--nfo-priority'
只保留一个，避免重复条目。"
  (let ((seen-dirs (make-hash-table :test 'equal))
        movies (count 0))
    (dolist (nfo (sort (directory-files-recursively root "\\.nfo\\'")
                       (lambda (a b)
                         (let ((pa (moonwwdz-media--nfo-priority a))
                               (pb (moonwwdz-media--nfo-priority b)))
                           (if (= pa pb) (string< a b) (< pa pb))))))
      (cl-incf count)
      (when (zerop (% count 50))
        (message "moonwwdz-media: 扫描中… %d" count))
      (let ((dir (file-name-directory nfo)))
        (unless (gethash dir seen-dirs)
          (let ((movie (moonwwdz-media--parse-movie-from-file nfo)))
            (when movie
              (puthash dir t seen-dirs)   ; 该目录已取到电影，跳过同目录其它 nfo
              (push movie movies))))))
    (message "moonwwdz-media: 扫描完成，共 %d 部" (length movies))
    (sort movies
          (lambda (a b)
            (string< (downcase (moonwwdz-media-movie-title a))
                     (downcase (moonwwdz-media-movie-title b)))))))

;;;; 列表视图

(defun moonwwdz-media--rating-num (s)
  "把评分字符串转浮点数（解析失败为 0.0）。"
  (float (string-to-number s)))

(defun moonwwdz-media--sort-by-year (a b)
  "列表按年份降序的比较函数。"
  (> (string-to-number (aref (cadr a) 1))
     (string-to-number (aref (cadr b) 1))))

(defun moonwwdz-media--sort-by-rating (a b)
  "列表按评分降序的比较函数。"
  (> (moonwwdz-media--rating-num (aref (cadr a) 2))
     (moonwwdz-media--rating-num (aref (cadr b) 2))))

(defun moonwwdz-media--sort-by-runtime (a b)
  "列表按时长降序的比较函数。"
  (> (string-to-number (aref (cadr a) 3))
     (string-to-number (aref (cadr b) 3))))

(defun moonwwdz-media--list-format ()
  "根据当前窗口宽度生成 tabulated-list-format，让列表占满窗口。
标题拿剩余空间的大部分（随窗口变宽而变宽，不封顶），类型约占 1/3（16~40）。"
  (let* ((w (max 60 (window-body-width)))
         (padding (* tabulated-list-padding 5)) ; 5 列各自的左右内边距
         (fixed-col 24)                         ; 年份6 + 评分8 + 时长10
         (remain (max 0 (- w padding fixed-col)))
         (genre-w (max 16 (min 40 (/ remain 3))))
         (title-w (max 20 (- remain genre-w))))
    (vector (list "标题" title-w t)
            (list "年份" 6 'moonwwdz-media--sort-by-year)
            (list "评分" 8 'moonwwdz-media--sort-by-rating)
            (list "时长" 10 'moonwwdz-media--sort-by-runtime)
            (list "类型" genre-w t))))

(defun moonwwdz-media--cell-title (movie)
  "列表显示用的标题文本（附原始标题与鼠标提示）。"
  (let ((title (moonwwdz-media-movie-title movie))
        (orig (moonwwdz-media-movie-originaltitle movie)))
    (propertize
     (if (or (string-empty-p orig) (string= title orig))
         title
       (format "%s  /  %s" title orig))
     'mouse-face 'highlight
     'help-echo "RET / mouse-1: 查看详情")))

(defun moonwwdz-media--filtered-movies ()
  "按当前 `moonwwdz-media--filter' 过滤后的电影列表。"
  (if (or (null moonwwdz-media--filter) (string-empty-p moonwwdz-media--filter))
      moonwwdz-media--movies
    (let ((needle (regexp-quote (downcase moonwwdz-media--filter))))
      (cl-remove-if-not
       (lambda (m)
         (or (string-match-p needle (downcase (moonwwdz-media-movie-title m)))
             (string-match-p needle (downcase (moonwwdz-media-movie-originaltitle m)))
             (string-match-p needle (downcase (moonwwdz-media-movie-year m)))
             (string-match-p needle (downcase (moonwwdz-media-movie-director m)))
             (seq-some (lambda (g) (string-match-p needle (downcase g)))
                       (moonwwdz-media-movie-genres m))))
       moonwwdz-media--movies))))

(defun moonwwdz-media--entries ()
  "构造 tabulated-list entries（id 为 movie 对象）。"
  (mapcar
   (lambda (m)
     (list m (vector (moonwwdz-media--cell-title m)
                     (moonwwdz-media-movie-year m)
                     (moonwwdz-media-movie-rating m)
                     (moonwwdz-media--runtime-display (moonwwdz-media-movie-runtime m))
                     (let ((gs (moonwwdz-media-movie-genres m)))
                       (if gs (string-join gs " / ") "—")))))
   (moonwwdz-media--filtered-movies)))

(defun moonwwdz-media--populate ()
  "根据当前过滤填充列表。"
  (setq tabulated-list-entries (moonwwdz-media--entries))
  (tabulated-list-print t))

(defun moonwwdz-media--refresh ()
  "重新扫描根目录并填充列表。"
  (if (or (null moonwwdz-media--root)
          (not (file-directory-p moonwwdz-media--root)))
      (user-error "moonwwdz-media: 未设置有效的电影库目录，按 C-c m 重新指定")
    (message "moonwwdz-media: 正在扫描 %s …" moonwwdz-media--root)
    (setq tabulated-list-format (moonwwdz-media--list-format))
    (tabulated-list-init-header)
    (let ((movies (moonwwdz-media--scan moonwwdz-media--root)))
      (setq moonwwdz-media--movies movies
            moonwwdz-media--filter nil))
    (moonwwdz-media--populate)))

(defun moonwwdz-media--on-window-change ()
  "当前列表 buffer 所在窗口宽度变化时，重新计算列宽并重排。"
  (when (and (eq major-mode 'moonwwdz-media-list-mode)
             (get-buffer-window (current-buffer)))
    (let ((w (window-body-width)))
      (unless (equal w moonwwdz-media--last-width)
        (setq moonwwdz-media--last-width w
              tabulated-list-format (moonwwdz-media--list-format))
        (tabulated-list-init-header)
        (tabulated-list-print t)))))

(defun moonwwdz-media--display-list (root)
  "在 ROOT 扫描并弹出列表视图。"
  (if (or (null root) (string-empty-p (string-trim root))
          (not (file-directory-p root)))
      (user-error "moonwwdz-media: 无效的电影库目录 %S；请用 M-x moonwwdz-media 指定" root)
    (let ((buf (get-buffer-create moonwwdz-media-list-buffer-name)))
      (with-current-buffer buf
        (moonwwdz-media-list-mode)        ; 必须先启用 mode：它会 kill-all-local-variables
        (setq moonwwdz-media--root (expand-file-name root)))  ; 再设置 buffer-local 状态
      (pop-to-buffer buf)
      (with-current-buffer buf            ; pop 后窗口宽度才准，此时刷新以动态适配列宽
        (moonwwdz-media--refresh)))))

(defvar moonwwdz-media-list-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'moonwwdz-media-open-detail)
    (define-key map [mouse-1] #'moonwwdz-media-open-detail)
    (define-key map (kbd "e") #'moonwwdz-media-edit-nfo)
    (define-key map (kbd "E") #'moonwwdz-media-edit-field)
    (define-key map (kbd "p") #'moonwwdz-media-play)
    (define-key map (kbd "/") #'moonwwdz-media-filter)
    (define-key map (kbd "g") #'moonwwdz-media-rescan)
    (define-key map (kbd "q") #'quit-window)
    map)
  "电影库列表视图按键。")

(define-derived-mode moonwwdz-media-list-mode tabulated-list-mode "MoonMovies"
  "电影库列表视图。
键位：RET 详情 / e 编辑nfo / E 改字段 / p 播放 / / 过滤 / g 重扫 / q 退出。
\\{moonwwdz-media-list-mode-map}"
  (setq tabulated-list-format (moonwwdz-media--list-format))
  (setq tabulated-list-padding 2)
  (add-hook 'tabulated-list-revert-hook #'moonwwdz-media--populate nil t)
  (add-hook 'window-configuration-change-hook #'moonwwdz-media--on-window-change nil t)
  (add-hook 'post-command-hook #'moonwwdz-media--sync-detail nil t)
  (tabulated-list-init-header))

;;;; 详情视图

(defun moonwwdz-media--http-url-p (txt)
  "TXT 是否为 http(s) URL。"
  (and (stringp txt) (string-match-p "\\`https?://" txt)))

(defun moonwwdz-media--direct-thumb-url (node)
  "取 NODE 直接子节点中的 <thumb> URL（优先 aspect=\"poster\"）。
只看直接子节点，避免误取 <actor>/<fanart> 内嵌套的 thumb。"
  (let ((thumbs (cl-remove-if-not
                 (lambda (c) (and (consp c) (eq (dom-tag c) 'thumb)))
                 (dom-children node))))
    (or (cl-loop for th in thumbs
                 when (and (equal (dom-attr th 'aspect) "poster")
                           (moonwwdz-media--http-url-p (string-trim (dom-text th))))
                 return (string-trim (dom-text th)))
        (cl-loop for th in thumbs
                 for txt = (string-trim (dom-text th))
                 when (moonwwdz-media--http-url-p txt) return txt))))

(defun moonwwdz-media--first-remote-url (node tag)
  "取 NODE 下第一个 TAG 节点中形如 http(s) 的 URL 文本（含后代）。"
  (cl-loop for n in (dom-by-tag node tag)
           for txt = (string-trim (dom-text n))
           when (moonwwdz-media--http-url-p txt) return txt))

(defun moonwwdz-media--url-extension (url)
  "取 URL 路径部分的扩展名（剥离 ?query 与 #fragment），无则返回 \"jpg\"。"
  (let* ((path (car (split-string url "[?#]")))
         (ext (file-name-extension path)))
    (if (and ext (not (string-empty-p ext))) ext "jpg")))

(defvar moonwwdz-media--cache-only nil
  "非 nil 时 `moonwwdz-media--download-cache' 只用已有缓存、不发起网络下载。
在列表光标联动（post-command-hook）时绑为 t，避免阻塞 UI。")

(defun moonwwdz-media--download-cache (url cache-dir)
  "把 URL 下载到 CACHE-DIR（按 sha1 命名），返回本地路径；失败或纯缓存模式下未命中返回 nil。"
  (let* ((hash (secure-hash 'sha1 url))
         (ext (moonwwdz-media--url-extension url))
         (path (expand-file-name (concat hash "." ext) cache-dir)))
    (cond
     ((file-exists-p path) path)
     (moonwwdz-media--cache-only nil) ; 联动时不阻塞下载
     (t
      (condition-case err
          (progn
            (make-directory cache-dir t)
            (url-copy-file url path t)
            path)
        (error
         (message "moonwwdz-media: 下载图片失败 %s：%s"
                  url (error-message-string err))
         nil))))))

(defun moonwwdz-media--remote-image (movie kind)
  "按 nfo 内 URL 取 MOVIE 的 KIND(poster/fanart) 图片，下载缓存后返回本地路径。
下载失败返回 nil（不抛错，避免中断详情渲染 / post-command-hook）。"
  (when (and moonwwdz-media-fetch-remote-images
             (moonwwdz-media-movie-nfo-path movie))
    (let* ((dom (moonwwdz-media--xml-file-to-dom (moonwwdz-media-movie-nfo-path movie)))
           (url (when dom
                  (pcase kind
                    ;; poster：只取 <movie> 直接子 <thumb>，排除 actor/fanart 内的 thumb。
                    ('poster (moonwwdz-media--direct-thumb-url dom))
                    ('fanart (let ((fan (car (dom-by-tag dom 'fanart))))
                               (when fan (moonwwdz-media--first-remote-url fan 'thumb))))))))
      (when url (moonwwdz-media--download-cache url moonwwdz-media-cache-dir)))))

(defun moonwwdz-media--detail-poster (movie)
  "返回可显示的海报路径（本地优先，回退 nfo 内 URL 缓存）。"
  (or (moonwwdz-media-movie-poster-path movie)
      (moonwwdz-media--remote-image movie 'poster)))

(defun moonwwdz-media--detail-fanart (movie)
  "返回可显示的背景图路径（本地优先，回退 nfo 内 URL 缓存）。"
  (or (moonwwdz-media-movie-fanart-path movie)
      (moonwwdz-media--remote-image movie 'fanart)))

(defun moonwwdz-media--insert-image (path max-width)
  "在当前 buffer 插入 PATH 图片（最大宽度 MAX-WIDTH）。
终端或图片不可显示时插入占位文本。"
  (if (and (display-images-p) (file-exists-p path))
      (insert-image (create-image path nil nil :max-width max-width))
    (insert (propertize (format "[图片: %s]" (file-name-nondirectory path))
                        'face 'shadow))))

(defun moonwwdz-media--insert-field (label value)
  "插入一行缩进的 \"LABEL: VALUE\"。VALUE 为空则跳过。"
  (unless (or (null value) (string-empty-p value))
    (insert "  " (propertize label 'face 'moonwwdz-media-field-face)
            (propertize ": " 'face 'shadow)
            (propertize value 'face 'moonwwdz-media-value-face) "\n")))

(defun moonwwdz-media--insert-section (title)
  "插入分区标题（前置空行 + 着色标题）。"
  (insert "\n" (propertize title 'face 'moonwwdz-media-section-face) "\n"))

(defun moonwwdz-media--insert-tags (label items)
  "插入缩进的 LABEL: 后跟横向徽章列表；ITEMS 全空则整行跳过。"
  (let ((tags (cl-remove-if (lambda (s) (or (null s) (string-empty-p s))) items)))
    (when tags
      (insert "  " (propertize label 'face 'moonwwdz-media-field-face)
              (propertize ": " 'face 'shadow)
              (mapconcat (lambda (s)
                           (propertize (concat " " s " ") 'face 'moonwwdz-media-tag-face))
                         tags
                         " ")
              "\n"))))

(defun moonwwdz-media--human-size (bytes)
  "把字节数转为人类可读字符串（如 1.2 GB）。"
  (cond
   ((>= bytes 1073741824) (format "%.1f GB" (/ bytes 1073741824.0)))
   ((>= bytes 1048576) (format "%.1f MB" (/ bytes 1048576.0)))
   ((>= bytes 1024) (format "%.1f KB" (/ bytes 1024.0)))
   (t (format "%d B" bytes))))

(defun moonwwdz-media--insert-meta-line (movie)
  "横向插入评分 / 时长 / 分级等标签行（紧凑）。"
  (let (parts)
    (let ((rating (moonwwdz-media-movie-rating movie)))
      (unless (or (null rating) (string-empty-p rating))
        (let ((src (moonwwdz-media-movie-rating-source movie))
              (votes (moonwwdz-media-movie-rating-votes movie)))
          (push (mapconcat
                 #'identity
                 (cl-remove-if (lambda (s) (or (null s) (string-empty-p s)))
                               (list (format "⭐ %s" rating)
                                     (unless (or (null src) (string-empty-p src)) src)
                                     (unless (or (null votes) (string-empty-p votes))
                                       (format "%s票" votes))))
                 " · ")
                parts))))
    (let ((rt (moonwwdz-media--runtime-display (moonwwdz-media-movie-runtime movie))))
      (unless (or (null rt) (string-empty-p rt))
        (push (format "⏱ %s" rt) parts)))
    (let ((mpaa (moonwwdz-media-movie-mpaa movie)))
      (unless (or (null mpaa) (string-empty-p mpaa))
        (push mpaa parts)))
    (when parts
      (insert "  " (mapconcat #'identity (nreverse parts) "    ") "\n"))))

(defun moonwwdz-media--detail-buffer ()
  "获取详情 buffer，必要时创建并启用一次 `moonwwdz-media-detail-mode'。"
  (let ((buf (get-buffer-create moonwwdz-media-detail-buffer-name)))
    (with-current-buffer buf
      (unless (derived-mode-p 'moonwwdz-media-detail-mode)
        (moonwwdz-media-detail-mode)))
    buf))

(defun moonwwdz-media--render-detail (movie)
  "在当前详情 buffer 渲染 MOVIE（不清窗口、不抢焦点、不重启 mode）。"
  (let ((inhibit-read-only t))
    (erase-buffer)
    (setq moonwwdz-media--detail-movie movie)
    ;; 海报
    (when-let* ((poster (moonwwdz-media--detail-poster movie)))
      (moonwwdz-media--insert-image poster moonwwdz-media-poster-width)
      (insert "\n"))
    ;; 标题 + 年份
    (insert (propertize (moonwwdz-media-movie-title movie)
                        'face 'moonwwdz-media-title-face))
    (let ((year (moonwwdz-media-movie-year movie)))
      (unless (or (null year) (string-empty-p year))
        (insert (propertize (format "  (%s)" year) 'face 'moonwwdz-media-dim-face))))
    (insert "\n")
    (let ((orig (moonwwdz-media-movie-originaltitle movie)))
      (unless (or (null orig) (string-empty-p orig)
                  (string= orig (moonwwdz-media-movie-title movie)))
        (insert (propertize orig 'face 'moonwwdz-media-dim-face) "\n")))
    (insert "\n")
    ;; 元数据标签行 + 分类信息
    (moonwwdz-media--insert-meta-line movie)
    (moonwwdz-media--insert-tags "类型" (moonwwdz-media-movie-genres movie))
    (moonwwdz-media--insert-field "国家" (string-join (moonwwdz-media-movie-countries movie) " / "))
    (moonwwdz-media--insert-field "首映" (moonwwdz-media-movie-premiered movie))
    (moonwwdz-media--insert-tags "标签" (moonwwdz-media-movie-tags movie))
    ;; 演职
    (moonwwdz-media--insert-section "演职")
    (moonwwdz-media--insert-field "导演" (moonwwdz-media-movie-director movie))
    (moonwwdz-media--insert-field "编剧" (moonwwdz-media-movie-credits movie))
    (moonwwdz-media--insert-field "出品" (moonwwdz-media-movie-studio movie))
    (moonwwdz-media--insert-field "主演"
      (string-join (seq-take (moonwwdz-media-movie-actors movie)
                             moonwwdz-media-max-actors) "、"))
    ;; 简介
    (let ((plot (moonwwdz-media-movie-plot movie)))
      (unless (or (null plot) (string-empty-p plot))
        (moonwwdz-media--insert-section "简介")
        (insert (propertize (concat "  " plot) 'face 'moonwwdz-media-value-face) "\n")))
    ;; 文件
    (let ((video (moonwwdz-media-movie-video-path movie)))
      (when video
        (moonwwdz-media--insert-section "文件")
        (insert "  " (propertize (file-name-nondirectory video)
                                  'face 'moonwwdz-media-value-face))
        (when (file-exists-p video)
          (let ((size (file-attribute-size (file-attributes video))))
            (when size
              (insert (propertize (format "    ·    %s" (moonwwdz-media--human-size size))
                                  'face 'shadow)))))
        (insert "\n")))
    ;; 背景图
    (when (> moonwwdz-media-fanart-width 0)
      (when-let* ((fanart (moonwwdz-media--detail-fanart movie)))
        (insert "\n")
        (moonwwdz-media--insert-image fanart moonwwdz-media-fanart-width)
        (insert "\n")))
    (goto-char (point-min))))

(defvar moonwwdz-media--inhibit-detail-popup nil
  "非 nil 时 `moonwwdz-media--show-detail' 只更新内容，不 `display-buffer' 弹窗。
`moonwwdz-media-finish-edit' 保存时绑为 t，避免 after-save 刷新与随后的 switch 叠加出多余窗口。")

(defun moonwwdz-media--show-detail (movie)
  "在详情 buffer 渲染 MOVIE 并显示。
详情已可见则只更新内容；否则弹出到另一窗口（保留列表可见，便于联动浏览）。
`moonwwdz-media--inhibit-detail-popup' 为 t 时只更新内容不弹窗。"
  (with-current-buffer (moonwwdz-media--detail-buffer)
    (moonwwdz-media--render-detail movie))
  (unless (or moonwwdz-media--inhibit-detail-popup
              (get-buffer-window moonwwdz-media-detail-buffer-name))
    (display-buffer moonwwdz-media-detail-buffer-name
                    '((display-buffer-pop-up-window)
                      (inhibit-same-window . t)))))

(defun moonwwdz-media--sync-detail ()
  "列表光标行变化时，静默更新已存在的详情 buffer 内容（不抢焦点）。"
  (when (and (eq major-mode 'moonwwdz-media-list-mode)
             (buffer-live-p (get-buffer moonwwdz-media-detail-buffer-name)))
    (let ((movie (tabulated-list-get-id)))
      (when (and movie (not (eq movie moonwwdz-media--synced-movie)))
        (setq moonwwdz-media--synced-movie movie)
        (with-current-buffer moonwwdz-media-detail-buffer-name
          ;; 联动渲染只用已有缓存，绝不发起阻塞下载（避免卡住光标导航）。
          (let ((moonwwdz-media--cache-only t))
            (moonwwdz-media--render-detail movie)))
        (when-let* ((win (get-buffer-window moonwwdz-media-detail-buffer-name)))
          (with-selected-window win (goto-char (point-min))))))))

(defvar moonwwdz-media-detail-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'moonwwdz-media-play)
    (define-key map (kbd "p") #'moonwwdz-media-play)
    (define-key map (kbd "e") #'moonwwdz-media-edit-nfo)
    (define-key map (kbd "E") #'moonwwdz-media-edit-field)
    (define-key map (kbd "g") #'moonwwdz-media-refresh-detail)
    (define-key map (kbd "q") #'moonwwdz-media-quit-detail)
    map)
  "电影详情视图按键。")

(define-derived-mode moonwwdz-media-detail-mode special-mode "MoonMovie"
  "电影详情视图。
键位：RET/p 播放 / e 编辑nfo / E 改字段 / g 刷新 / q 返回。
\\{moonwwdz-media-detail-mode-map}"
  (setq buffer-read-only t)
  (visual-line-mode 1))

;;;; 通用：取当前 movie / 命令

(defun moonwwdz-media--current-movie ()
  "返回当前列表/详情 buffer 中的 movie 对象。
列表用 `tabulated-list-get-id' 取行 id（即 movie 对象）；
注意 `tabulated-list-get-entry' 返回的是列向量，不是 id。"
  (cond
   ((eq major-mode 'moonwwdz-media-list-mode) (tabulated-list-get-id))
   ((eq major-mode 'moonwwdz-media-detail-mode) moonwwdz-media--detail-movie)
   (t nil)))

(defun moonwwdz-media-open-detail ()
  "在详情视图打开光标所在电影。"
  (interactive)
  (when-let* ((movie (moonwwdz-media--current-movie)))
    (moonwwdz-media--show-detail movie)))

(defun moonwwdz-media-play ()
  "外调播放器播放当前电影。"
  (interactive)
  (let ((movie (moonwwdz-media--current-movie)))
    (if-let* ((video (and movie (moonwwdz-media-movie-video-path movie))))
        (progn
          (if (and (eq system-type 'windows-nt)
                   (string-equal-ignore-case moonwwdz-media-player-command "start"))
              ;; "start" 是 cmd 内建命令、没有 start.exe；用系统关联程序打开。
              (w32-shell-execute "open" video)
            (apply #'start-process "moonwwdz-media-player" nil
                   moonwwdz-media-player-command
                   (append moonwwdz-media-player-args (list video))))
          (message "moonwwdz-media: 播放 %s" (moonwwdz-media-movie-title movie)))
      (message "moonwwdz-media: 未找到视频文件"))))

(defun moonwwdz-media--after-save-refresh ()
  "nfo 保存后刷新列表/详情。仅对 `moonwwdz-media-edit-nfo' 打开的 nfo buffer 生效。"
  (moonwwdz-media--after-edit buffer-file-name))

(defun moonwwdz-media-finish-edit ()
  "保存并关闭当前 nfo buffer，切回来源视图（详情优先，否则列表）。"
  (interactive)
  ;; save-buffer 会触发 after-save-hook 里的自动刷新（含 show-detail）；
  ;; 抑制其弹窗，避免与下方 switch-to-buffer 叠加出两个详情窗口。
  (let ((moonwwdz-media--inhibit-detail-popup t))
    (save-buffer))
  (let ((nfo-buf (current-buffer))
        (this-nfo (buffer-file-name))
        target)
    (cond
     ((and (buffer-live-p (get-buffer moonwwdz-media-detail-buffer-name))
           (with-current-buffer moonwwdz-media-detail-buffer-name
             (and moonwwdz-media--detail-movie
                  (string= (moonwwdz-media-movie-nfo-path moonwwdz-media--detail-movie)
                           this-nfo))))
      (setq target moonwwdz-media-detail-buffer-name))
     ((buffer-live-p (get-buffer moonwwdz-media-list-buffer-name))
      (setq target moonwwdz-media-list-buffer-name)))
    (if target
        (progn
          (switch-to-buffer target)
          (when (buffer-live-p nfo-buf) (kill-buffer nfo-buf))
          (message "moonwwdz-media: 已保存并返回 %s" target))
      (user-error "moonwwdz-media: 无可返回的视图，按 C-c m 重新打开"))))

(defun moonwwdz-media-edit-nfo ()
  "直接打开当前电影的 nfo 文件编辑。
保存（\\[save-buffer] 或 evil :w）后列表与详情自动刷新；
在 nfo buffer 里按 \\[moonwwdz-media-finish-edit] 可保存并切回来源视图。"
  (interactive)
  (let* ((movie (moonwwdz-media--current-movie))
         (nfo (and movie (moonwwdz-media-movie-nfo-path movie))))
    (if nfo
        (progn
          (find-file nfo)
          (add-hook 'after-save-hook #'moonwwdz-media--after-save-refresh nil t)
          (local-set-key (kbd "C-c C-c") #'moonwwdz-media-finish-edit)
          (message "moonwwdz-media: 编辑 nfo；保存后自动刷新，C-c C-c 保存并返回"))
      (message "moonwwdz-media: 无 nfo 文件"))))

(defun moonwwdz-media-filter (needle)
  "按 NEEDLE（标题/年份/类型/导演子串）过滤列表；空串清除过滤。"
  (interactive
   (list (read-string (format "过滤 [%s]: " (or moonwwdz-media--filter "")))))
  (setq moonwwdz-media--filter (if (string-empty-p needle) nil needle))
  (moonwwdz-media--populate))

(defun moonwwdz-media-rescan ()
  "重新扫描电影库根目录。"
  (interactive)
  (if (or (null moonwwdz-media--root)
          (not (file-directory-p moonwwdz-media--root)))
      (user-error "moonwwdz-media: 未设置有效的电影库目录，按 C-c m 重新指定")
    (moonwwdz-media--refresh)))

(defun moonwwdz-media-refresh-detail ()
  "重新读取 nfo 刷新详情视图。nfo 已删除/损坏/不再是 <movie> 时提示而不崩溃。"
  (interactive)
  (when (and (eq major-mode 'moonwwdz-media-detail-mode)
             moonwwdz-media--detail-movie)
    (let* ((nfo (moonwwdz-media-movie-nfo-path moonwwdz-media--detail-movie))
           (movie (moonwwdz-media--parse-movie-from-file nfo)))
      (if movie
          (progn
            (setq moonwwdz-media--detail-movie movie)
            (moonwwdz-media--show-detail movie))
        (message "moonwwdz-media: nfo 已无法解析（%s），保留当前详情" nfo)))))

(defun moonwwdz-media-quit-detail ()
  "关闭详情窗口并彻底 kill 详情 buffer（停止与列表的联动）。"
  (interactive)
  (let ((buf (current-buffer)))
    (quit-window)            ; 退出详情窗口（GUI 下恢复列表窗口）
    (when (buffer-live-p buf)
      (kill-buffer buf))))

;;;; 表单式字段编辑（写回 XML）

(defconst moonwwdz-media--editable-fields
  '((title . "标题")
    (originaltitle . "原始标题")
    (year . "年份")
    (plot . "剧情")
    (rating . "评分")
    (director . "导演（多个用 / 分隔）")
    (genre . "类型（多个用 / 分隔）"))
  "可表单编辑的字段： (xml-tag . 提示词)。")

(defun moonwwdz-media--field-current (movie field)
  "取 MOVIE 当前 FIELD 的字符串值。"
  (pcase field
    ('title (moonwwdz-media-movie-title movie))
    ('originaltitle (moonwwdz-media-movie-originaltitle movie))
    ('year (moonwwdz-media-movie-year movie))
    ('plot (moonwwdz-media-movie-plot movie))
    ('rating (moonwwdz-media-movie-rating movie))
    ('director (moonwwdz-media-movie-director movie))
    ('genre (string-join (moonwwdz-media-movie-genres movie) " / "))
    (_ "")))

(defun moonwwdz-media--dom-set-text (node text)
  "把 NODE 的子节点设为单个文本 TEXT（破坏性）。
等价于 Emacs 27 文档中的 `dom-set-text'，但 29.4 的 dom.el 未提供，故自实现。
dom 节点结构为 (tag attrs . children)，把 children 整体替换为 (TEXT)。"
  (setcdr (cdr node) (list text))
  node)

(defun moonwwdz-media--dom-clean-whitespace (node)
  "递归移除 NODE（含后代）中纯空白的文本子节点，便于重新缩进序列化。
xml-parse 会把元素间的空白当文本节点保留，xml-print 再加自己的缩进就会双倍空行，
故写回前先清掉这些纯空白子节点。"
  (when (consp node)
    (setcdr (cdr node)
            (cl-remove-if (lambda (c)
                            (and (stringp c)
                                 (string-match-p "\\`[ \t\r\n]*\\'" c)))
                          (cddr node)))
    (dolist (c (cddr node))
      (when (consp c) (moonwwdz-media--dom-clean-whitespace c))))
  node)

(defun moonwwdz-media--insert-after (root anchor new-node)
  "在 ROOT 的直接子节点列表中 ANCHOR 之后插入 NEW-NODE（破坏性）。"
  (let ((mem (memq anchor (cddr root))))
    (when mem
      (setcdr mem (cons new-node (cdr mem))))))

(defun moonwwdz-media--write-single (root tag value)
  "在 ROOT 替换/新建单个 TAG 节点的文本为 VALUE。"
  (let ((node (car (dom-by-tag root tag))))
    (if node
        (moonwwdz-media--dom-set-text node value)
      (dom-append-child root (dom-node tag nil value)))))

(defun moonwwdz-media--write-multivalue (root tag values)
  "在 ROOT 把所有 TAG 节点内容更新为 VALUES（尽量原位保留）。
全空则删除全部旧节点；原本没有则追加到根末尾；否则改第一个、删多余、按序原位后插。"
  (let* ((nodes (dom-by-tag root tag))
         (vals (cl-remove-if (lambda (s) (or (null s) (string-empty-p s))) values)))
    (cond
     ((null vals)
      (dolist (n nodes) (dom-remove-node root n)))
     ((null nodes)
      (dolist (v vals) (dom-append-child root (dom-node tag nil v))))
     (t
      (let ((anchor (car nodes)))
        (moonwwdz-media--dom-set-text anchor (car vals))
        (dolist (n (cdr nodes)) (dom-remove-node root n))
        (dolist (v (cdr vals))
          (let ((new (dom-node tag nil v)))
            (moonwwdz-media--insert-after root anchor new)
            (setq anchor new))))))))

(defun moonwwdz-media--write-rating (root value)
  "把 ROOT 的评分写为 VALUE，只改数值不破坏 <votes>/name 等兄弟节点。
优先写现代结构 <ratings><rating><value>；老式裸 <rating> 直接写文本；
两者皆无则新建 <ratings><rating default=\"true\"><value>…</value></rating></ratings>。"
  (let* ((ratings (car (dom-by-tag root 'ratings)))
         (rating (moonwwdz-media--rating-node root)))
    (cond
     ;; 现代结构：有 <rating>，写其 <value> 子节点（无则补一个），
     ;; 保留 <votes>、name/default 属性。
     ((and rating (car (dom-by-tag rating 'value)))
      (moonwwdz-media--dom-set-text (car (dom-by-tag rating 'value)) value))
     ;; 有 <rating> 但无 <value>：老式裸 <rating>7.5</rating>，直接改文本。
     (rating
      (moonwwdz-media--dom-set-text rating value))
     ;; 完全没有评分节点：新建现代结构。
     (t
      (let* ((value-node (dom-node 'value nil value))
             (rating-node (dom-node 'rating '((default . "true")) value-node)))
        (if ratings
            (dom-append-child ratings rating-node)
          (dom-append-child root (dom-node 'ratings nil rating-node))))))))

(defun moonwwdz-media--write-field (nfo-file tag value)
  "把 NFO-FILE 中 TAG 内容写为 VALUE（单值直接写；genre/director 按 / 拆分）。
注：使用 dom 整树重序列化，保证 well-formed，但会丢失刮削器注释与精确缩进。"
  (let ((root (or (moonwwdz-media--xml-file-to-dom nfo-file)
                  (error "moonwwdz-media: 无法解析 %s" nfo-file))))
    (cond
     ((memq tag '(genre director))
      (moonwwdz-media--write-multivalue
       root tag (mapcar #'string-trim (split-string value "/" nil "[ \t]+"))))
     ((eq tag 'rating)
      (moonwwdz-media--write-rating root value))
     (t
      (moonwwdz-media--write-single root tag value)))
    (let ((coding-system-for-write 'utf-8-unix))
      (moonwwdz-media--dom-clean-whitespace root)
      (with-temp-file nfo-file
        (insert "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n")
        (xml-print (list root))))))

(defun moonwwdz-media--after-edit (nfo)
  "nfo 写回后刷新详情与列表中受影响的条目。"
  (let ((new (moonwwdz-media--parse-movie-from-file nfo)))
    (when (and new (buffer-live-p (get-buffer moonwwdz-media-detail-buffer-name)))
      (with-current-buffer (get-buffer moonwwdz-media-detail-buffer-name)
        (when (and moonwwdz-media--detail-movie
                   (string= (moonwwdz-media-movie-nfo-path moonwwdz-media--detail-movie) nfo))
          (moonwwdz-media--show-detail new))))
    (when (and new (buffer-live-p (get-buffer moonwwdz-media-list-buffer-name)))
      (with-current-buffer (get-buffer moonwwdz-media-list-buffer-name)
        (setq moonwwdz-media--movies
              (mapcar (lambda (m) (if (string= (moonwwdz-media-movie-nfo-path m) nfo) new m))
                      moonwwdz-media--movies))
        (moonwwdz-media--populate)))))

(defun moonwwdz-media-edit-field (field)
  "表单式编辑当前电影 FIELD 字段，写回 nfo。
FIELD 为 `moonwwdz-media--editable-fields' 中的 tag。"
  (interactive
   (list (intern (completing-read
                  "编辑字段: "
                  (mapcar (lambda (c) (symbol-name (car c))) moonwwdz-media--editable-fields)
                  nil t))))
  (let* ((movie (moonwwdz-media--current-movie))
         (nfo (and movie (moonwwdz-media-movie-nfo-path movie))))
    (if (not nfo)
        (message "moonwwdz-media: 无 nfo 文件")
      (let* ((prompt (cdr (assq field moonwwdz-media--editable-fields)))
             (value (read-string (format "%s: " prompt)
                                 (moonwwdz-media--field-current movie field))))
        (moonwwdz-media--write-field nfo field value)
        (message "moonwwdz-media: 已更新 %s 的 %s" (moonwwdz-media-movie-title movie) field)
        (moonwwdz-media--after-edit nfo)))))

;;;; 入口命令

;;;###autoload
(defun moonwwdz-media (root)
  "打开电影库 ROOT，展示列表视图。
无前缀且 `moonwwdz-media-root-dir' 是有效目录时直接用它；否则提示输入。
提示默认值为 `moonwwdz-media-root-dir'，未配置时用当前目录。"
  (interactive
   (list (if (and (null current-prefix-arg)
                  moonwwdz-media-root-dir
                  (file-directory-p moonwwdz-media-root-dir))
             moonwwdz-media-root-dir
           (read-directory-name "电影库目录: "
                                (or moonwwdz-media-root-dir default-directory "~/")))))
  (moonwwdz-media--display-list root))

;;;; evil 适配

;; 自定义 buffer 用 normal state，并把单字符命令显式绑到 evil normal map，
;; 以免被 evil 默认键（如 q 录宏、p 粘贴）拦截；j/k 上下浏览保持可用。
(with-eval-after-load 'evil
  (evil-set-initial-state 'moonwwdz-media-list-mode 'normal)
  (evil-set-initial-state 'moonwwdz-media-detail-mode 'normal)
  (evil-define-key 'normal moonwwdz-media-list-mode-map
    (kbd "RET") #'moonwwdz-media-open-detail
    "e" #'moonwwdz-media-edit-nfo
    "E" #'moonwwdz-media-edit-field
    "p" #'moonwwdz-media-play
    "/" #'moonwwdz-media-filter
    "g" #'moonwwdz-media-rescan
    "q" #'quit-window)
  (evil-define-key 'normal moonwwdz-media-detail-mode-map
    (kbd "RET") #'moonwwdz-media-play
    "p" #'moonwwdz-media-play
    "e" #'moonwwdz-media-edit-nfo
    "E" #'moonwwdz-media-edit-field
    "g" #'moonwwdz-media-refresh-detail
    "q" #'moonwwdz-media-quit-detail))

(provide 'moonwwdz-media)
;;; moonwwdz-media.el ends here
