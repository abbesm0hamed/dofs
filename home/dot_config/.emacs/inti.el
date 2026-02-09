;;; init.el --- My Emacs Configuration -*- lexical-binding: t -*-

;; ===== PACKAGE SETUP =====
(require 'package)
(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu" . "https://elpa.gnu.org/packages/")
                         ("nongnu" . "https://elpa.nongnu.org/nongnu/")))
(package-initialize)

;; Bootstrap use-package
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))
(require 'use-package)
(setq use-package-always-ensure t)  ; Auto-install packages

;; ===== BASIC SETTINGS =====
(setq inhibit-startup-message t)    ; No startup screen
(tool-bar-mode -1)                  ; No toolbar
(menu-bar-mode -1)                  ; No menu bar
(scroll-bar-mode -1)                ; No scrollbar
(setq ring-bell-function 'ignore)   ; No bell
(global-display-line-numbers-mode 1) ; Line numbers
(setq-default indent-tabs-mode nil) ; Spaces, not tabs
(setq-default tab-width 4)
(save-place-mode 1)                 ; Remember cursor position
(savehist-mode 1)                   ; Save minibuffer history
(recentf-mode 1)                    ; Track recent files
(global-auto-revert-mode 1)         ; Auto-reload changed files

;; Better defaults
(setq backup-directory-alist '(("." . "~/.emacs.d/backups")))
(setq auto-save-file-name-transforms '((".*" "~/.emacs.d/auto-save-list/" t)))
(setq custom-file (concat user-emacs-directory "custom.el"))
(when (file-exists-p custom-file)
  (load custom-file))

;; ===== EVIL MODE (Vim keybindings) =====
(use-package evil
  :init
  (setq evil-want-C-u-scroll t)
  (setq evil-want-keybinding nil)  ; Required for evil-collection
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; ===== COMPLETION =====
(use-package vertico
  :init
  (vertico-mode))

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        completion-category-defaults nil
        completion-category-overrides '((file (styles partial-completion)))))

(use-package marginalia
  :init
  (marginalia-mode))

(use-package consult
  :bind (("C-x b" . consult-buffer)
         ("C-s" . consult-line)))

;; ===== PROJECT MANAGEMENT =====
(use-package projectile
  :config
  (projectile-mode +1)
  :bind-keymap
  ("C-c p" . projectile-command-map))

;; ===== GIT =====
(use-package magit
  :bind ("C-x g" . magit-status))

;; ===== THEME =====
(use-package doom-themes
  :config
  (load-theme 'doom-one t)
  (doom-themes-visual-bell-config))

(use-package doom-modeline
  :init (doom-modeline-mode 1))

;; ===== SYNTAX CHECKING =====
(use-package flycheck
  :init (global-flycheck-mode))

;; ===== AUTOCOMPLETION =====
(use-package company
  :init (global-company-mode)
  :config
  (setq company-idle-delay 0.2
        company-minimum-prefix-length 1))

;; ===== LSP =====
(use-package lsp-mode
  :hook ((python-mode . lsp)
         (js-mode . lsp)
         (typescript-mode . lsp)
         (rust-mode . lsp)
         (web-mode . lsp))
  :commands lsp
  :config
  (setq lsp-headerline-breadcrumb-enable nil))

(use-package lsp-ui
  :commands lsp-ui-mode)

;; ===== LANGUAGE MODES =====
(use-package typescript-mode)
(use-package rust-mode)
(use-package yaml-mode)
(use-package markdown-mode)
(use-package web-mode
  :mode ("\\.html\\'" "\\.jsx\\'" "\\.tsx\\'")
  :config
  (setq web-mode-markup-indent-offset 2
        web-mode-css-indent-offset 2
        web-mode-code-indent-offset 2))

;; ===== FILE TREE =====
(use-package treemacs
  :bind ("C-c t" . treemacs))

(use-package treemacs-evil
  :after (treemacs evil))

(use-package treemacs-projectile
  :after (treemacs projectile))

;; ===== WHICH-KEY (shows keybinding hints) =====
(use-package which-key
  :init (which-key-mode)
  :config
  (setq which-key-idle-delay 0.3))

;;; init.el ends here
