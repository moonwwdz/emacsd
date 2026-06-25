# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a personal Emacs configuration repository (`~/.emacs.d`) with a modular structure. The configuration is designed for daily use and includes support for multiple programming languages, org-mode, and various productivity tools.

## Installation & Setup

```bash
# macOS 需要安装 Python 3.10+（系统自带 3.9 不够）
brew install python@3.12
ln -s python3.12 /opt/homebrew/bin/python3

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

- **`init.el`** - Main configuration entry point that loads all modules
- **`lisp/init-*.el`** - Modular configuration files:
  - `init-packages.el` - Package management and installation
  - `init-ui.el` - User interface and theme settings
  - `init-better-default.el` - Enhanced default settings
  - `init-org.el` - Org-mode configuration
  - `init-keyboard.el` - Keybinding definitions

### Custom Modules

- **`lisp/moonwwdz-*.el`** - Personal custom utilities:
  - `moonwwdz-golang.el` - Go development setup
  - `moonwwdz-rust.el` - Rust development setup
  - `moonwwdz-python.el` - Python development setup (uv/pyvenv 自动激活)
  - `moonwwdz-shell.el` - Shell configuration (保存时自动 chmod +x)
  - `moonwwdz-dict.el` - Dictionary integration (dict.13140000.xyz API)
  - `moonwwdz-helper.el` - General helper functions
- **`lisp/git-package.el`** - Third-party git submodule packages configuration (lsp-bridge, evil, rime, dired-sidebar, org-modern, etc.)

### Package Structure

- **`git-package/`** - Git submodules with custom packages:
  - `lsp-bridge` - LSP client with async completion
  - `evil` - Vim emulation layer
  - `emacs-rime` - Rime input method integration
  - `company-english-helper` - English word completion
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
- Dired sidebar for file navigation
- Tab bar mode for workspace management

## Essential Keybindings

| Keyboard | Action |
|----------|--------|
| `C-c C-l` | Edit org-mode links |
| `C-c c` | Org-capture |
| `C-c g` | Magit status |
| `C-c a` | Org-agenda |
| `C-x C-n` | Toggle dired sidebar |
| `C-x C-r` | Recent files |
| `C-x C-b` | ibuffer |
| `C-c n` | Jump to next diagnostic |
| `C-c p` | Jump to previous diagnostic |
| `C-c d` | Mac dictionary lookup (macOS only) |
| `C-c y` | Dictionary lookup (dict.13140000.xyz) |
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

### M-s Prefix Keybindings

| Keyboard | Action |
|----------|--------|
| `M-s o` | Occur (search word at point) |
| `M-s i` | counsel-imenu |
| `M-s s` | Toggle sdcv helper (English word completion) |
| `M-s w` | Insert current week heading |
| `M-s t` | Toggle theme (modus-operandi / modus-vivendi) |
| `M-s f` | Insert file content at point |
| `M-s p` | Toggle paste mode |
| `M-s e` | iedit mode (multi-cursor edit) |
| `M-s c` | Add spaces between CJK and ASCII (region or whole buffer) |

### Org-roam Keybindings

| Keyboard | Action |
|----------|--------|
| `C-c n i` | Insert org-roam node |
| `C-c n f` | Find org-roam node |
| `C-c n l` | Toggle org-roam buffer |
| `C-c n u` | Org-roam UI mode |
| `C-c n c` | Org-roam capture |
| `C-c n d` | Org-roam dailies |

### Language-specific Keybindings (Go / Rust / Python)

| Keyboard | Go | Rust | Python |
|----------|-----|------|--------|
| `C-c C-c` | `go run` | `cargo run` | `python3` run |
| `C-c C-b` | `go build` | `cargo build` | — |
| `C-c C-t` | `go test` | `cargo test` | `pytest` |
| `C-c C-k` | `go vet` | `cargo check` | `py_compile` |

所有 `C-c C-c` 支持 `C-u` 前缀传入参数。Python 额外保留 `F5` 快速执行脚本。Rust 在 `src/bin/NAME.rs`（或 `src/bin/NAME/main.rs`）下用 `cargo run --bin NAME`，其余 cargo 项目用 `cargo run`，无 `Cargo.toml` 时回退 `rustc` 直接编译运行。

## Development Notes

- Requires Emacs 30+, tested on GNU Emacs 30.2
- Configuration uses a modular approach with separate files for different aspects
- Custom packages are managed as git submodules in `git-package/`
- Personal custom utilities are prefixed with `moonwwdz-`
- The setup supports both Chinese and English input methods
- Uses `cl-lib` (not deprecated `cl`) for Common Lisp extensions
- Uses `advice-add` (not deprecated `defadvice`) for function advice
- Font configuration uses `find-font` guard to avoid errors when fonts are not installed
- Emacs 30 defaults `.py` to `python-ts-mode`; explicit `auto-mode-alist` entry forces `python-mode` for lsp-bridge compatibility
- Shell scripts are automatically made executable on first save via `executable-make-buffer-file-executable-if-script-p`
- Window starts maximized via `(fullscreen . maximized)` in `default-frame-alist`
- lsp-bridge 启用 inlay hints（变量后自动显示推断类型）、document-highlight（光标符号高亮）、which-function（mode-line 显示当前函数）；`lsp-bridge-symbols-enable-which-func` 需配合 `which-function-mode` 才生效。rust-analyzer 默认提供类型提示，无需额外服务器配置