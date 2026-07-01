;;; early-init.el --- 早于 init.el 与建帧的启动优化  -*- lexical-binding: t; -*-
;; Emacs 27+ 在 package.el 初始化和建第一个 frame 之前加载本文件，
;; 在此关 UI 和延迟 package 比在 init.el 里更早，消除启动闪烁。

;; init-packages.el 会显式调 (package-initialize)，此处禁用自动初始化避免重复
(setq package-enable-at-startup nil)

;; 通过 default-frame-alist 从建帧起就不绘制这些控件，比「建后再关」更干净
(push '(menu-bar-lines . 0) default-frame-alist)
(push '(tool-bar-lines . 0) default-frame-alist)
(push '(vertical-scroll-bars) default-frame-alist)
(push '(fullscreen . maximized) default-frame-alist)

(setq frame-inhibit-implicit-resize t)           ; 避免字体/UI 变化触发多余的窗口重排
(setq native-comp-async-report-warnings-errors 'silent) ; 异步编译告警不弹 *Warnings*
(setq inhibit-compacting-font-caches t)

(provide 'early-init)
;;; early-init.el ends here
