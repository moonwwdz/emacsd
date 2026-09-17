# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Emacs configuration repository (`~/.emacs.d`) with a modular structure. The configuration is designed for daily use and includes support for multiple programming languages, org-mode, and various productivity tools.

## Installation & Setup

```bash
# macOS 需要安装 Python 3.10+（系统自带 3.9 不够）
brew install python@3.12
ln -s python3.12 /opt/homebrew/bin/python3

# macOS dired 目录优先排序依赖 GNU ls
brew install coreutils

# Linux (Arch) 安装字体
yay -S ttf-lxgw-wenkai-screen

# Python 依赖（lsp-bridge 运行所需）
pip3 install epc orjson sexpdata six setuptools paramiko rapidfuzz watchdog packaging pyyaml --break-system-packages

# 克隆配置
git clone https://github.com/moonwwdz/emacsd.git ~/.emacs.d
cd ~/.emacs.d
git submodule init
git submodule update
```

### Language Dependencies

**Go:**
```bash
go install golang.org/x/tools/gopls@latest
go install golang.org/x/tools/cmd/goimports@latest
go install github.com/go-delve/delve/cmd/dlv@latest
```

**Rust:**
```bash
rustup component add rust-src rustfmt clippy rust-analyzer
```

**Python:**
```bash
pip3 install basedpyright ipython pytest uv
```

## Architecture

### Core Configuration Files

- **`early-init.el`** - 早于 package.el 和建帧执行：禁用 UI 控件（从源头不绘制）、最大化、native-comp 静音、frame-inhibit-implicit-resize；Emacs 27+ 专属
- **`init.el`** - Main configuration entry point that loads all modules
- **`lisp/init-*.el`** - Modular configuration files:
  - `init-packages.el` - Package management and installation
  - `init-ui.el` - User interface and theme settings
  - `init-better-default.el` - Enhanced default settings
  - `init-org.el` - Org-mode configuration
  - `init-keyboard.el` - Keybinding definitions

### Custom Modules

- **`lisp/moonwwdz-*.el`** - Personal custom utilities:
  - `moonwwdz-golang.el` - Go 开发（Test/Benchmark 单用例运行、goimports 保存格式化）
  - `moonwwdz-rust.el` - Rust 开发（`#[test]` 单用例运行、`src/bin` 目标识别运行、保存自动格式化、langserver 配置覆盖）
  - `moonwwdz-python.el` - Python development setup (uv/pyvenv 自动激活)
  - `moonwwdz-shell.el` - Shell configuration (保存时自动 chmod +x)
  - `moonwwdz-dict.el` - Dictionary integration (dict.13140000.xyz API)
  - `moonwwdz-helper.el` - General helper functions
  - `moonwwdz-media.el` - 电影库（NFO）管理：扫描纯电影库、海报/元数据展示、NFO 编辑、外调播放器
- **`lisp/git-package.el`** - Third-party git submodule packages configuration (lsp-bridge, evil, rime, dired-sidebar, org-modern, etc.)

### Package Structure

- **`git-package/`** - Git submodules with custom packages:
  - `lsp-bridge` - LSP client with async completion
  - `evil` - Vim emulation layer
  - `emacs-rime` - Rime input method integration
  - `nov` - EPUB reader
  - `org-modern` - Modern org-mode styling
  - `mastodon` - Mastodon client

- **`theme/`** - Custom color themes (molokai variants)

- **`elpa/`** - Installed ELPA packages

## Key Features

### Development Support
- Go development with LSP integration
- JavaScript/JS2 mode
- Rust mode
- Python development with uv/pyvenv integration
- Git integration via magit

### Org-Mode
- HTML export functionality
- Modern styling with org-modern
- Capture templates with `C-c c`

### Input & Dictionary
- Rime input method support
- English-Chinese dictionary lookup
- Youdao and Mac dictionary integration

### UI/UX
- Evil mode for Vim keybindings
- lsp-bridge for LSP auto-completion (requires Python 3.10+)
- Dired sidebar for file navigation (`C-x C-n`)
- Tab-bar for workspace management: each tab is an independent window layout; `C-x t` prefix to manage, `C-<tab>` / `C-S-<tab>` to cycle tabs
- `rainbow-mode` shows color codes as swatches (enabled in elisp/css/web/conf modes)
- `hl-todo` highlights TODO/FIXME/HACK keywords
- `wraplish` auto-inserts spaces between CJK and ASCII characters (hooks `text-mode`; `message-mode` excluded to avoid corrupting email headers)

### Minibuffer Completion & Navigation
- Completion stack: **vertico** (vertical UI) + **consult** (commands) + **orderless** (fuzzy matching) + **marginalia** (annotations); `savehist` for history-based sorting
- `avy` for quick on-screen jumps; `vundo` for a visual undo tree
- `wgrep` makes grep buffers editable for batch search-and-replace (lazy-loaded with grep)
- `treesit-auto` auto-enables tree-sitter for non-lsp-bridge languages (json/yaml/toml/…); python/go/rust are deliberately excluded so they keep using lsp-bridge on the non-`*-ts-mode` major modes

### Media Library (NFO)
- `moonwwdz-media` (`C-c m`): 扫描「一文件夹一部电影」的 NFO 电影库（Kodi/Jellyfin/Emby/TMM 刮削产物），列表/详情展示（海报+元数据+简介+背景图），可编辑 NFO、外调播放器
- 默认读 `moonwwdz-media-root-dir`（nil 则每次提示）；图片本地优先（poster/-poster/folder/cover/thumb…），本地缺失时按 nfo 内 `<thumb>`/`<fanart>` URL 下载到 `~/.emacs.d/.cache/moonwwdz-media/`
- 表单编辑（`E`）用 dom 重序列化保证 well-formed，但会丢失刮削器注释（如 `<!--created by TMM-->`）；`e` 直接打开原始 nfo 用 nxml-mode 编辑
- 列表/详情内部键位：`RET` 详情/播放、`e` 打开 nfo、`E` 表单改字段、`p` 外调播放器、`/` 过滤、`g` 刷新、`q` 退出

## Essential Keybindings

| Keyboard | Action |
|----------|--------|
| `C-s` | consult-line (in-buffer incremental search) |
| `C-x b` | consult-buffer (switch buffer) |
| `C-c C-r` | vertico-repeat (repeat last minibuffer session) |
| `C-'` | avy-goto-char-timer (jump to char on screen) |
| `C-x u` | vundo (visual undo tree) |
| `C-c C-l` | Edit org-mode links |
| `C-c c` | Org-capture |
| `C-c g` | Magit status |
| `C-c a` | Org-agenda |
| `C-x C-n` | Toggle dired sidebar |
| `C-x C-r` | Recent files |
| `C-x C-b` | ibuffer |
| `C-<tab>` | tab-bar-switch-to-next-tab |
| `C-S-<tab>` | tab-bar-switch-to-prev-tab |
| `C-c n` | Jump to next diagnostic |
| `C-c p` | Jump to previous diagnostic |
| `C-c d` | Mac dictionary lookup (macOS only) |
| `C-c y` | Dictionary lookup (dict.13140000.xyz) |
| `C-c m` | 电影库（NFO）管理 (moonwwdz-media) |
| `M-.` | Jump to definition (lsp-bridge) |
| `M-,` | Return from definition |
| `C-.` | Show documentation (lsp-bridge) |
| `M-?` | Find references (lsp-bridge) |
| `C-c r` | Rename symbol (lsp-bridge) |
| `C-c q` | Code action / quickfix (lsp-bridge) |
| `C-c C-p` | Peek definition (lsp-bridge) |
| `C-c j` | Search workspace symbols (lsp-bridge) |
| `C-c h` | Incoming call hierarchy (lsp-bridge) |
| `M-n` / `M-p` | Select next/prev completion candidate (acm) |
| `C-=` | Expand region |
| `C-\` | Toggle input method (rime) |

### project.el Keybindings (C-x p prefix)

| Keyboard | Action |
|----------|--------|
| `C-x p f` | Find file in project |
| `C-x p p` | Switch project |
| `C-x p b` | consult-project-buffer (switch buffer in project) |
| `C-x p g` | Search in project (grep) |

### M-s Prefix Keybindings

| Keyboard | Action |
|----------|--------|
| `M-s o` | Occur (search word at point) |
| `M-s i` | consult-imenu |
| `M-s g` | consult-ripgrep (project-wide content search) |
| `M-s j` | avy-goto-line |
| `M-s s` | Toggle sdcv helper (English word completion) |
| `M-s w` | Insert current week heading |
| `M-s t` | Toggle theme (modus-operandi / modus-vivendi) |
| `M-s f` | Insert file content at point |
| `M-s p` | Toggle paste mode |
| `M-s e` | iedit mode (multi-cursor edit) |
| `M-s c` | Add spaces between CJK and ASCII (region or whole buffer) |

### Language-specific Keybindings (Go / Rust / Python)

| Keyboard | Go | Rust | Python |
|----------|-----|------|--------|
| `C-c C-c` | `go run` | `cargo run` | `python3` run |
| `C-c C-b` | `go build` | `cargo build` | — |
| `C-c C-t` | `go test`（Test/Benchmark 内只跑该用例） | `cargo test`（#[test] 内只跑该用例） | `pytest` |
| `C-c C-k` | `go vet` | `cargo check` | `py_compile` |

所有 `C-c C-c` 支持 `C-u` 前缀传入参数。Go 的 `C-c C-t`：光标在 `Test`/`Fuzz` 函数内只跑当前包该用例（`go test -run '^NAME$' .`），`Benchmark` 函数用 `-bench` 跑并跳过普通测试，否则全仓库 `go test ./...`；`C-u` 前缀手动输入 `-run` 正则（默认值为光标处用例名）。Rust 的 `C-c C-t`：光标在 `#[test]` 函数内（含 `#[tokio::test]` 等）只跑该用例，否则全量 `cargo test`；`C-u` 前缀手动输入过滤词（默认值为光标处用例名）。Python 额外保留 `F5` 快速执行脚本。Rust 在 `src/bin/NAME.rs`（或 `src/bin/NAME/main.rs`）下用 `cargo run --bin NAME`，其余 cargo 项目用 `cargo run`，无 `Cargo.toml` 时回退 `rustc` 直接编译运行。

## Development Notes

- Requires Emacs 30+, tested on GNU Emacs 31.1
- Configuration uses a modular approach with separate files for different aspects
- Custom packages are managed as git submodules in `git-package/`
- Personal custom utilities are prefixed with `moonwwdz-`
- The setup supports both Chinese and English input methods
- Uses `cl-lib` (not deprecated `cl`) for Common Lisp extensions
- Uses `advice-add` (not deprecated `defadvice`) for function advice
- Font configuration uses `find-font` guard to avoid errors when fonts are not installed
- Emacs 30 defaults `.py` to `python-ts-mode`; explicit `auto-mode-alist` entry forces `python-mode` for lsp-bridge compatibility
- `treesit-auto` is configured to **exclude** `python`/`go`/`gomod`/`rust` from `treesit-auto-langs`: its `major-mode-remap-alist` entries would otherwise remap `python-mode`/`go-mode`/`rust-mode` to `*-ts-mode` once a grammar is installed, which would silently disable lsp-bridge (it hooks the non-ts major modes in `git-package.el`). When adding a new lsp-bridge language, also add it to this exclusion list.
- Rust 的 rust-analyzer 配置由 `lisp/langserver/rust-analyzer.json` **整体替换** lsp-bridge 内置默认（`moonwwdz-rust.el` 里 `setq lsp-bridge-user-langserver-dir` 指向该目录；用户文件存在即完全覆盖，不是深合并，改配置需两处对齐）。三个覆盖项：`cargo.autoreload: true`（修 src/bin 等目录新建文件不进 crate graph 无补全）、`cargo.features`/`checkOnSave.features: []` 官方默认（lsp-bridge 默认 `"all"` 会让后台重建分析期间补全排队 3~10 秒甚至返回空候选，2026-09 实测修复）、`checkOnSave.command: clippy`（保存时除编译错误还给 lint）。代价：非默认 feature 门控的 API 拿不到补全，确有需要的项目局部改回。
- **submodule 的运行时依赖必须手动列进 `my/packages`**：git submodule 不走 package.el，package.el 不知道谁在用它，跑 `package-autoremove` 会误删。现有三个：`dired-subtree`（dired-sidebar 依赖）、`popup`（emacs-rime TTY 候选 `rime-show-candidate 'popup` 依赖）、`tomelr`（submodule 版 ox-hugo 依赖，elpa 版 ox-hugo 已删）。新增 submodule 若有 elpa 依赖，同样要入清单。
- org-roam submodule **保留但停用**（git-package.el 里加载块全注释、`init-org.el` 里 capture 模板已注释留存）；恢复只需解开 git-package.el 的 org-roam 块注释。company-english-helper submodule 已移除（依赖已弃用的 company，0 引用）。
- Minibuffer completion uses the vertico stack (vertico/consult/orderless/marginalia), not ivy/counsel/swiper; `M-x`/`C-x C-f`/`C-h f`/`C-h v` use native commands enhanced by vertico + marginalia
- Shell scripts are automatically made executable on first save via `executable-make-buffer-file-executable-if-script-p`
- `(fullscreen . maximized)` and all frame decoration settings live in `early-init.el` (via `default-frame-alist`), applied before the first frame is created — do not add frame-alist entries in `init-better-default.el`
- GC is managed by **gcmh**: `gc-cons-threshold` is raised to 128 MB during active use (via `pre-command-hook`) and lowered on idle. If gcmh is unavailable at startup, falls back to a fixed 64 MB threshold. Do not set `gc-cons-threshold` manually after startup.
- File backups are centralised to `~/.emacs.d/backups/` (versioned, 6 kept) and auto-save to `~/.emacs.d/auto-save/`; `make-backup-files` is **enabled** — the old `nil` setting has been removed.
- Project navigation uses built-in **project.el** (`C-x p` prefix), not projectile. `C-x p b` is rebound to `consult-project-buffer`.
- `wraplish` hooks `text-mode` to auto-insert spaces between CJK and ASCII. `message-mode` is excluded (via `my/wraplish-disable` on `message-mode-hook`) to prevent space injection into email headers. When adding a new text-derived mode that should NOT get wraplish, add a similar hook.
- `dired-listing-switches` uses `--group-directories-first` on Linux; on macOS uses `gls` (from `coreutils`) if available, otherwise falls back to plain `-alh`. Install with `brew install coreutils` to get directory-first sorting on macOS.
- lsp-bridge 启用 inlay hints（变量后自动显示推断类型）、document-highlight（光标符号高亮）、which-function（mode-line 显示当前函数）；`lsp-bridge-symbols-enable-which-func` 需配合 `which-function-mode` 才生效。rust-analyzer 默认提供类型提示，无需额外服务器配置。inlay hint 的诊断钩子刷新经 0.5s idle-timer 防抖（`git-package.el` 的 `my/lsp-bridge-inlay-hint-after-diagnostic`，直接刷新会在大文件上频繁重建 overlay 造成输入卡顿），诊断更新后的补刷新保留——它修复小文件打开后类型提示不显示的问题
