;; -*- lexical-binding: t; -*-

;; ═══════════════════════════════════════════════════════════════════
;; UI
;; ═══════════════════════════════════════════════════════════════════

(setq default-frame-alist
      '((width . 110)
        (height . 54)))

(setq visual-fill-column-width 120
      visual-fill-column-center-text t)

(add-hook 'org-mode-hook #'visual-fill-column-mode)

(defun jd/org-mode-visual-fill ()
  (visual-fill-column-mode 1))

;; Theme & Font
(setq doom-theme 'doom-rose-pine)
(setq doom-font (font-spec :family "CaskaydiaCove Nerd Font" :size 12))

;; Column number in modeline
(column-number-mode 1)

;; Line numbers
;; Options: nil, t, 'relative
(setq display-line-numbers-type 'relative)

(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(setq confirm-kill-emacs nil)

;; ═══════════════════════════════════════════════════════════════════
;; INDENTATION
;; ═══════════════════════════════════════════════════════════════════

(setq-default tab-width 2)
(setq-default evil-shift-width 2)
(setq-default indent-tabs-mode nil)

;; ═══════════════════════════════════════════════════════════════════
;; ORG
;; ═══════════════════════════════════════════════════════════════════

(setq org-directory "~/org/")

(defun jd/org-mode-setup ()
  (org-indent-mode)
  (visual-line-mode 1)
  (setq evil-auto-indent nil))

(after! org

  (add-hook 'org-mode-hook #'jd/org-mode-setup)
  (add-hook 'org-mode-hook #'hl-todo-mode)

  ;; ─── Display ──────────────────────────────────────────────────
  (setq org-ellipsis "..."
        org-hide-emphasis-markers t
        org-src-fontify-natively t
        org-fontify-quote-and-verse-blocks t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 2
        org-startup-folded 'overview
        org-cycle-separator-lines 2)

  ;; ─── Agenda Files ─────────────────────────────────────────────
  ;; Picks up inbox, tasks, meetings, bills + ALL client files automatically
  (setq org-agenda-files
        (append
         (mapcar (lambda (f) (concat org-directory f))
                 '("inbox.org"
                   "tasks.org"
                   "meetings.org"
                   "bills.org"))
         (file-expand-wildcards (concat org-directory "clients/*.org"))))

  ;; ─── Logging ──────────────────────────────────────────────────
  (setq org-log-done 'time
        org-log-into-drawer t
        org-agenda-start-with-log-mode nil   ;; off by default, less noise
        org-agenda-start-day nil
        org-agenda-start-on-weekday nil)

  ;; ─── TODO Keywords ────────────────────────────────────────────
  (setq org-todo-keywords
        '((sequence
           "TODO(t)"        ;; not started
           "NEXT(n!)"       ;; decided: do this next
           "IN-PROGRESS(i)" ;; actively working
           "WAIT(w@/!)"     ;; blocked on someone else
           "REVIEW(v)"      ;; needs review / QA
           "|"
           "DONE(d!)"
           "CANCELLED(c@)")))

  (setq org-todo-keyword-faces
        '(("TODO"        . (:foreground "#ff6b6b" :weight bold))
          ("NEXT"        . (:foreground "#ffd93d" :weight bold))
          ("IN-PROGRESS" . (:foreground "#4fc3f7" :weight bold))
          ("WAIT"        . (:foreground "#a8a8a8" :weight bold))
          ("REVIEW"      . (:foreground "#ce93d8" :weight bold))
          ("DONE"        . (:foreground "#6bcb77" :weight bold))
          ("CANCELLED"   . (:foreground "#555555" :strike-through t))))

  ;; ─── Priority ─────────────────────────────────────────────────
  (setq org-priority-highest ?A
        org-priority-lowest  ?C
        org-priority-default ?B)

  ;; ─── Tags ─────────────────────────────────────────────────────
  (setq org-tag-alist
        '((:startgroup)
          ("bug"     . ?b)
          ("feature" . ?f)
          ("waiting" . ?w)
          ("invoice" . ?i)
          (:endgroup)))

  ;; ─── Agenda Custom Commands ───────────────────────────────────
  (setq org-agenda-block-separator "")
  (setq org-agenda-compact-blocks nil)
  (setq org-agenda-skip-scheduled-if-done t)
  (setq org-agenda-skip-deadline-if-done t)
  (setq org-agenda-window-setup 'current-window)

  (defun my/client-org-files ()
    (file-expand-wildcards
     (expand-file-name "clients/*.org" org-directory)))

  (setq org-agenda-custom-commands
        '(
          ;; ── d: Daily Driver — open every morning ──────────────
          ("d" "🗓 Daily Driver"
           ((agenda ""
                    ((org-agenda-span 1)
                     (org-agenda-sorting-strategy
                      '(deadline-up priority-down time-up))
                     (org-deadline-warning-days 2)
                     (org-agenda-overriding-header
                      "━━━ ⚡ TODAY — Deadlines & Scheduled ━━━━━━━━━━━\n")))
            (todo "NEXT|IN-PROGRESS"
                  ((org-agenda-overriding-header
                    "\n━━━ 🎯 IN FLIGHT — Next & In Progress ━━━━━━━━━━\n")
                   (org-agenda-sorting-strategy '(priority-down deadline-up))))
            (todo "TODO"
                  ((org-agenda-skip-function
                    '(org-agenda-skip-entry-if 'scheduled 'deadline))
                   (org-agenda-sorting-strategy '(priority-down effort-up))
                   (org-agenda-max-entries 8)
                   (org-agenda-overriding-header
                    "\n━━━ 📋 UNSCHEDULED — Priority Pool (top 8) ━━━━━\n")))
            (todo "WAIT"
                  ((org-agenda-overriding-header
                    "\n━━━ ⏳ WAITING ON SOMEONE ━━━━━━━━━━━━━━━━━━━━━\n")))
            (todo "REVIEW"
                  ((org-agenda-overriding-header
                    "\n━━━ 🔍 NEEDS REVIEW ━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")))))

          ;; ── o: Overdue Audit — when overwhelmed ───────────────
          ("o" "🚨 Overdue & At Risk"
           ((agenda ""
                    ((org-agenda-span 1)
                     (org-agenda-use-time-grid nil)
                     (org-agenda-entry-types '(:deadline :scheduled))
                     (org-deadline-warning-days 3)
                     (org-agenda-sorting-strategy '(deadline-up priority-down))
                     (org-agenda-overriding-header
                      "━━━ 🚨 OVERDUE + DUE IN 3 DAYS ━━━━━━━━━━━━━━━━\n")))))

          ;; ── w: Week Ahead — for planning ──────────────────────
          ("w" "📆 Week Ahead"
           ((agenda ""
                    ((org-agenda-span 7)
                     (org-agenda-sorting-strategy '(deadline-up priority-down))
                     (org-agenda-overriding-header
                      "━━━ 📆 NEXT 7 DAYS ━━━━━━━━━━━━━━━━━━━━━━━━━━━\n")))
            (todo "NEXT"
                  ((org-agenda-overriding-header
                    "\n━━━ ⚡ NEXT Actions across all projects ━━━━━━━━\n")))))

          ;; ── p: Client Projects — all client tasks only ─────────
          ("p" "👤 Client Projects"
           ((agenda ""
                    ((org-agenda-overriding-header
                      "━━━ 📆 DEADLINES & SCHEDULED ━━━━━━━━━━━━━━━━━━━\n")
                     (org-agenda-files
                      (file-expand-wildcards
                       (concat (file-name-as-directory org-directory) "clients/*.org")))
                     (org-agenda-span 7)
                     (org-agenda-use-time-grid nil)
                     (org-agenda-include-deadlines t)
                     (org-agenda-include-todos t)
                     (org-agenda-sorting-strategy
                      '(deadline-up priority-down time-up))
                     ))
            (todo "TODO|NEXT|IN-PROGRESS|WAIT|REVIEW"
                  ((org-agenda-files
                    (file-expand-wildcards
                     (concat org-directory "clients/*.org")))
                   (org-agenda-sorting-strategy
                    '(priority-down deadline-up category-up))
                   (org-agenda-overriding-header
                    "━━━ 📁 ALL CLIENT TASKS by Priority ━━━━━━━━━━━━\n"))))
           nil
           nil)))

  ;; ─── Refile ───────────────────────────────────────────────────
  (setq org-refile-targets
        '((org-agenda-files :maxlevel . 3)
          (nil :maxlevel . 3)))
  (setq org-refile-use-outline-path 'file)
  (setq org-refile-allow-creating-parent-nodes 'confirm)
  (setq org-outline-path-complete-in-steps nil)

  ;; ─── Capture Templates ────────────────────────────────────────
  (setq org-capture-templates
        '(
          ;; Fastest capture — everything goes to inbox first
          ("i" "📥 Inbox" entry
           (file+headline "~/org/inbox.org" "Uncategorized")
           "* TODO %?\n  Captured: %U\n  %a"
           :empty-lines 1)

          ;; Client task — pick which client file
          ("c" "👤 Client Task" entry
           (file+headline
            (lambda ()
              (completing-read
               "Client: "
               (file-expand-wildcards (concat org-directory "clients/*.org"))))
            "📋 Active Tasks")
           "* TODO [#B] %?\n  SCHEDULED: %t\n  :PROPERTIES:\n  :EFFORT: \n  :END:"
           :empty-lines 1)

          ;; Bug report — goes straight to client Bugs section
          ("b" "🐛 Bug Report" entry
           (file+headline
            (lambda ()
              (completing-read
               "Client: "
               (file-expand-wildcards (concat org-directory "clients/*.org"))))
            "🐛 Bugs")
           "* TODO [#A] %?  :bug:\n  DEADLINE: %t\n  - Reported by ::\n  - Steps      ::\n  - Expected   ::\n  - Actual     ::"
           :empty-lines 1)

          ;; Personal / admin task
          ("t" "✅ Personal Task" entry
           (file+headline "~/org/tasks.org" "🔵 Someday / Backlog")
           "* TODO [#C] %?\n  %U"
           :empty-lines 1)

          ;; Meeting note
          ("m" "📅 Meeting" entry
           (file+headline "~/org/meetings.org" "📝 Past Meetings")
           "* %U Meeting: %?\n  - Attendees ::\n  - Discussed ::\n  - Decisions ::\n  - Actions   ::"
           :empty-lines 1)

          ;; Weekly review — creates a dated file in journal/weekly/
          ("w" "📆 Weekly Review" plain
           (file (lambda ()
                   (let ((date (format-time-string "%Y-%m-%d")))
                     (expand-file-name
                      (concat "journal/weekly/review-" date ".org")
                      org-directory))))
           (file "~/org/weekly-review-template.org")
           :immediate-finish t
           :jump-to-captured t)))

  ;; ─── Babel ────────────────────────────────────────────────────
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)))

  (push '("conf-unix" . conf-unix) org-src-lang-modes)

  ;; ─── Faces ────────────────────────────────────────────────────
  (set-face-attribute 'org-document-title nil
                      :font "CaskaydiaCove Nerd Font"
                      :weight 'bold
                      :height 1.0)

  (dolist (face '(org-level-1 org-level-2 org-level-3
                  org-level-4 org-level-5 org-level-6
                  org-level-7 org-level-8))
    (set-face-attribute face nil
                        :font "CaskaydiaCove Nerd Font"
                        :weight 'medium
                        :height 1.0))

  (set-face-attribute 'org-block   nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table   nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code    nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))

  ;; ─── Structure Templates ──────────────────────────────────────
  (require 'org-tempo)
  (add-to-list 'org-structure-template-alist '("sh" . "src sh"))
  (add-to-list 'org-structure-template-alist '("ts" . "src typescript"))

) ;; end (after! org)

;; ═══════════════════════════════════════════════════════════════════
;; EVIL ORG
;; ═══════════════════════════════════════════════════════════════════

(use-package! evil-org
  :after org
  :hook ((org-mode . evil-org-mode)
         (org-agenda-mode . evil-org-mode))
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

;; ═══════════════════════════════════════════════════════════════════
;; ORG ROAM
;; ═══════════════════════════════════════════════════════════════════

(defun jd/org-get-clients ()
  "Return a list of client org files from clients/ directory."
  (file-expand-wildcards (concat org-directory "clients/*.org")))

(use-package! org-roam
  :custom
  (org-roam-directory "~/org/")
  (org-roam-completion-everywhere t)

  (org-roam-capture-templates
   '(
     ;; Default note — goes to notes/
     ("d" "default" plain
      "%?"
      :if-new (file+head "notes/${slug}.org"
                         "#+title: ${title}\n#+author: Jaj Dollesin\n#+date: %U\n\n")
      :unnarrowed t)

     ;; Dev note — goes to notes/dev/
     ("v" "dev note" plain
      "%?"
      :if-new (file+head "notes/dev/${slug}.org"
                         "#+title: ${title}\n#+author: Jaj Dollesin\n#+date: %U\n\n")
      :unnarrowed t)

     ;; New client project — creates file in clients/
     ("p" "client project" plain
      "* 📌 Meta
  :PROPERTIES:
  :CONTACT:    %^{Contact name}
  :EMAIL:      %^{Email}
  :REPO:       %^{Repo URL}
  :STAGING:
  :PRODUCTION:
  :STARTED:    %U
  :CONTRACT:
  :END:

* 📋 Active Tasks

* 🐛 Bugs

* ✨ Feature Requests

* ⏳ Waiting / Blocked

* 💰 Invoices & Billing

* 📅 Meetings

* ✅ Done
"
      :if-new (file+head "clients/${slug}.org"
                         "#+title: ${title}\n\n")
      :unnarrowed t)

     ;; Task — goes to tasks.org
     ("t" "Task" entry
      "* TODO %^{Task}\n%^G%?"
      :target (file "tasks.org")
      :prepend t
      :empty-lines 1
      :unnarrowed t)

     ;; Meeting
     ("m" "Meeting" entry
      "* TODO %^{Meeting}\nSCHEDULED: <%^{Date}>\n%?"
      :target (file "meetings.org")
      :unnarrowed t)

     ;; Inbox
     ("i" "inbox" entry
      "* TODO %^{Task}\t%^G\n%?"
      :target (file "inbox.org")
      :unnarrowed t)))

  :bind (("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ("C-c n l" . org-roam-buffer-toggle))

  :config
  (org-roam-db-autosync-mode))

;; ═══════════════════════════════════════════════════════════════════
;; AUTO ARCHIVE
;; ═══════════════════════════════════════════════════════════════════

(setq org-archive-location "~/org/archive.org::")
(setq org-archive-mark-done nil)

(defun jd/org-auto-archive-done-tasks ()
  "Auto-archive DONE tasks from client files and tasks.org."
  (when (and (buffer-file-name)
             (or
              ;; archive from tasks.org
              (string= (expand-file-name (buffer-file-name))
                       (expand-file-name "~/org/tasks.org"))
              ;; archive from any client file
              (string-prefix-p
               (expand-file-name "~/org/clients/")
               (expand-file-name (buffer-file-name))))
             (string= org-state "DONE"))
    (org-archive-subtree)))

(add-hook 'org-after-todo-state-change-hook
          #'jd/org-auto-archive-done-tasks)

;; Manual archive of all DONE tasks in current buffer
;; Run with: M-x jd/org-archive-all-done
(defun jd/org-archive-all-done ()
  "Archive all DONE and CANCELLED tasks in current buffer."
  (interactive)
  (org-map-entries
   (lambda ()
     (org-archive-subtree)
     (setq org-map-continue-from (outline-previous-heading)))
   "/DONE|CANCELLED" 'file))

;; ═══════════════════════════════════════════════════════════════════
;; KEYBINDINGS
;; ═══════════════════════════════════════════════════════════════════

;; F12 → Daily Driver (zero friction morning open)
(defun jd/daily-driver ()
  "Open Daily Driver agenda view."
  (interactive)
  (org-agenda nil "d"))

(global-set-key (kbd "<f12>") #'jd/daily-driver)

;; F11 → Quick inbox capture
(defun jd/quick-capture ()
  "Quick capture to inbox."
  (interactive)
  (org-capture nil "i"))

(global-set-key (kbd "<f11>") #'jd/quick-capture)
