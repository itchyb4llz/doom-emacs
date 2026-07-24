;; -*- lexical-binding: t; -*-

(setq default-frame-alist
      '((width . 120)
        (height . 62)))

(setq visual-fill-column-width 120
      visual-fill-column-center-text t)

(add-hook 'org-mode-hook #'visual-fill-column-mode)

;; Theme & Font
(setq doom-theme 'doom-one)
(setq doom-font (font-spec :family "JetBrains Mono Nerd Font" :size 12))

;; Column number in modeline
(column-number-mode 1)

;; Line numbers — off in prose/terminal modes
(setq display-line-numbers-type 'relative)

(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(setq confirm-kill-emacs nil)

(setq-default tab-width 2)
(setq-default evil-shift-width 2)
(setq-default indent-tabs-mode nil)

(setq org-directory "~/org/")

(defun jd/org-mode-setup ()
  (org-indent-mode)
  (visual-line-mode 1)
  (setq evil-auto-indent nil))

(after! org
  (setq org-modern-star nil)
  (add-hook 'org-mode-hook #'jd/org-mode-setup)
  (add-hook 'org-mode-hook #'hl-todo-mode)

  (setq org-ellipsis "..."
        org-hide-emphasis-markers t
        org-src-fontify-natively t
        org-fontify-quote-and-verse-blocks t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 2
        org-startup-folded 'show2levels
        org-cycle-separator-lines 2)

  ;; Core files + all real client files (excludes _template.org)
  (setq org-agenda-files
        (append
         (mapcar (lambda (f) (concat org-directory f))
                 '("bills.org"
                   "calendar.org"
                   "clients.org"
                   "inbox.org"
                   "meetings.org"
                   "notes.org"
                   "projects.org"
                   "tasks.org"))))

  (setq org-log-done 'time
        org-log-into-drawer t
        org-agenda-start-with-log-mode nil
        org-agenda-start-day nil
        org-agenda-start-on-weekday nil)

  (setq org-todo-keywords
        '((sequence
           "TODO(t)"
           "NEXT(n!)"
           "IN-PROGRESS(i)"
           "WAIT(w@/!)"
           "REVIEW(v)"
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

  (setq org-priority-highest ?A
        org-priority-lowest  ?C
        org-priority-default ?B)

  (setq org-tag-alist
        '((:startgroup)
          ("bug"     . ?b)
          ("feature" . ?f)
          ("waiting" . ?w)
          ("issue" . ?i)
          ("report" . ?r)
          (:endgroup)))

  (setq org-agenda-block-separator "")
  (setq org-agenda-compact-blocks nil)
  (setq org-agenda-skip-scheduled-if-done t)
  (setq org-agenda-skip-deadline-if-done t)
  (setq org-agenda-window-setup 'current-window)

  (setq org-agenda-custom-commands
        '(
          ("d" "Dashboard"
           ((agenda ""
                    ((org-agenda-span 7)
                     (org-agenda-sorting-strategy
                      '(deadline-up priority-down time-up))
                     (org-deadline-warning-days 2)
                     (org-agenda-overriding-header
                      "Deadlines & Scheduled\n")))
            (todo "NEXT|IN-PROGRESS"
                  ((org-agenda-overriding-header
                    "\nIN FLIGHT — Next & In Progress\n")
                   (org-agenda-sorting-strategy '(priority-down deadline-up))))
            (todo "TODO"
                  ((org-agenda-skip-function
                    '(org-agenda-skip-entry-if 'scheduled 'deadline))
                   (org-agenda-sorting-strategy '(priority-down effort-up))
                   (org-agenda-max-entries 8)
                   (org-agenda-overriding-header
                    "\nUNSCHEDULED — Priority Pool (top 8)\n")))
            (todo "WAIT"
                  ((org-agenda-overriding-header
                    "\nWAITING ON SOMEONE\n")))
            (todo "REVIEW"
                  ((org-agenda-overriding-header
                    "\nNEEDS REVIEW\n")))))

          ("o" "Overdue & At Risk"
           ((agenda ""
                    ((org-agenda-span 1)
                     (org-agenda-use-time-grid nil)
                     (org-agenda-entry-types '(:deadline :scheduled))
                     (org-deadline-warning-days 3)
                     (org-agenda-sorting-strategy '(deadline-up priority-down))
                     (org-agenda-overriding-header
                      "OVERDUE + DUE IN 3 DAYS\n")))))

          ("w" "Week Ahead"
           ((agenda ""
                    ((org-agenda-span 7)
                     (org-agenda-sorting-strategy '(deadline-up priority-down))
                     (org-agenda-overriding-header
                      "NEXT 7 DAYS\n")))
            (todo "NEXT"
                  ((org-agenda-overriding-header
                    "\nNEXT Actions across all projects\n")))))))

  (setq org-refile-targets
        '((org-agenda-files :maxlevel . 3)
          (nil :maxlevel . 3)))
  (setq org-refile-use-outline-path 'file)
  (setq org-refile-allow-creating-parent-nodes 'confirm)
  (setq org-outline-path-complete-in-steps nil)

  ;; Wrapped in after! org-capture so it fires after Doom's
  ;; +org-init-capture-defaults-h (which runs on org-load-hook,
  ;; after with-eval-after-load 'org, and would overwrite these).
  (after! org-capture
    (setq org-capture-templates
          '(
            ("i" "Inbox" entry
             (file "~/org/inbox.org")
             "* TODO %?\n  Captured: %U\n  %a"
             :empty-lines 1)

            ("c" "Client" entry
             (file "~/org/clients.org")
             "* %^{Client}\n** Active Tasks\n** Bugs\n** Feature Requests\n** Waiting/Blocked\n** Invoices & Billing\n** Done/Archive\n")

            ("n" "Notes" entry
             (file+headline "~/org/notes.org" "Inbox")
             "* [%<%Y-%m-%d %a>] %^{Title}\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?"
             :empty-lines 1)

            ("b" "Bills" entry
             (file "~/org/bills.org")
             "* TODO %^{New Bill}\nDEADLINE: %^{DEADLINE}T\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?")

            ("e" "Event" entry
             (file+headline "~/org/calendar.org" "Events")
             "* %^{Event}\nSCHEDULED: %^{SCHEDULED}T\n:PROPERTIES:\n:CREATED: %U\n:CONTACT:\n:END:\n%?")

            ("d" "Deadline" entry
             (file+headline "~/org/calendar.org" "Deadlines")
             "* TODO %^{Task}\nDEADLINE: %^{Deadline}T\n:PROPERTIES:\n:CREATED: %U\n:END:\n%?")

            ("m" "Meeting" entry
             "* TODO %^{Meeting}\nSCHEDULED: <%^{Date}>\n%?"
             :target (file "meetings.org")
             :unnarrowed t))))

  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)
     (rust . t)
     (typescript . t)
     (javascript . t)))

  (push '("conf-unix" . conf-unix) org-src-lang-modes)

  (set-face-attribute 'org-document-title nil
                      :font "JetBrains Mono Nerd Font"
                      :weight 'bold
                      :height 1.0)

  (dolist (face '(org-level-1 org-level-2 org-level-3
                  org-level-4 org-level-5 org-level-6
                  org-level-7 org-level-8))
    (set-face-attribute face nil
                        :font "JetBrains Mono Nerd Font"
                        :weight 'medium
                        :height 1.0))

  (set-face-attribute 'org-block   nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table   nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code    nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))

  (require 'org-tempo)
  (add-to-list 'org-structure-template-alist '("sh" . "src sh"))
  (add-to-list 'org-structure-template-alist '("ts" . "src typescript"))

) ;; end (after! org)

(use-package! evil-org
  :after org
  :hook ((org-mode . evil-org-mode)
         (org-agenda-mode . evil-org-mode))
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

(use-package! org-roam
  :custom
  (org-roam-directory "~/org/")
  (org-roam-completion-everywhere t)

  (org-roam-capture-templates
   '(
     ("d" "Default" plain
      "%?"
      :if-new (file+head "notes/${slug}.org"
                         "#+title: ${title}\n#+date: %U\n\n")
      :unnarrowed t)

     ("i" "Inbox" entry
      "* TODO %^{Task}\t%^G\n%?"
      :target (file "inbox.org")
      :unnarrowed t)))

(org-roam-dailies-directory "~/org/journal/")
(org-roam-dailies-capture-templates
 '(("d" "default" entry
    "* %<%I:%M %p>\n%?"
    :target
    (file+head+olp
     "%<%Y-%m-%d>.org"
     "#+title: %<%Y-%m-%d>

* Metrics
** Sleep Quality
- Time to Bed (last night):
- Wake Time:

** Meals
- [ ] Breakfast:
- [ ] Lunch:
- [ ] Dinner:
- Snacks:
  -
* Morning Foundation
** TODO Morning Prayer and Scripture
** TODO Shower, Groom, and Dressed
** TODO Review Day's Battle Plan
** TODO System Update
** TODO Check Reports: issues/bugs/emails/msg/missed calls

* Today's Focus
- Main project:
- Secondary task:
- If I only finish one thing today, it will be:

* Journal
"
     ("Journal")))))

  :bind (("C-c n f" . org-roam-node-find)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ("C-c n l" . org-roam-buffer-toggle)
         :map org-mode-map
         ("C-M-i" . completion-at-point)
         :map org-roam-dailies-map
         ("Y" . org-roam-dailies-capture-yesterday)
         ("T" . org-roam-dailies-capture-tomorrow))
  :bind-keymap
  ("C-c n d" . org-roam-dailies-map)
  :config
  (require 'org-roam-dailies)
  (org-roam-db-autosync-mode))

;; (setq org-archive-location "~/org/archive.org::")
;; (setq org-archive-mark-done nil)
;;
;; (defun jd/org-auto-archive-done-tasks ()
;;   "Auto-archive DONE tasks from client files and tasks.org."
;;   (when (and (buffer-file-name)
;;              (or
;;               (string= (expand-file-name (buffer-file-name))
;;                        (expand-file-name "~/org/tasks.org"))
;;               (string-prefix-p
;;                (expand-file-name "~/org/clients/")
;;                (expand-file-name (buffer-file-name))))
;;              (string= org-state "DONE"))
;;     (org-archive-subtree)))
;;
;; (add-hook 'org-after-todo-state-change-hook
;;           #'jd/org-auto-archive-done-tasks)
;;
;; (defun jd/org-archive-all-done ()
;;   "Archive all DONE and CANCELLED tasks in current buffer."
;;   (interactive)
;;   (org-map-entries
;;    (lambda ()
;;      (org-archive-subtree)
;;      (setq org-map-continue-from (outline-previous-heading)))
;;    "/DONE|CANCELLED" 'file))

(defun jd/daily-driver ()
  "Open Daily Driver agenda view."
  (interactive)
  (org-agenda nil "d"))

(global-set-key (kbd "<f12>") #'jd/daily-driver)

(defun jd/quick-capture ()
  "Quick capture to inbox."
  (interactive)
  (org-capture nil "i"))

(global-set-key (kbd "<f11>") #'jd/quick-capture)

(defun jd/dashboard-widget-header ()
  (let* ((title "✦ Jaj's Workspace ✦")
         (date  (format-time-string "%A, %b %-d"))
         (pad-t (make-string (max 0 (/ (- (window-width (get-buffer-window (current-buffer))) (length title)) 2)) ?\s))
         (pad-d (make-string (max 0 (/ (- (window-width (get-buffer-window (current-buffer))) (length date))  2)) ?\s)))
    (insert "\n\n\n\n\n")
    (insert pad-t (propertize title 'face 'font-lock-keyword-face) "\n")

    (insert pad-d (propertize date  'face 'font-lock-comment-face) "\n")))

(defun jd/dashboard-widget-keys ()
  (let* ((inner  42)
         (pad    (make-string (max 0 (/ (- (window-width (get-buffer-window (current-buffer))) inner) 2)) ?\s))
         (sep    (propertize (make-string inner ?─) 'face 'font-lock-comment-face))
         (groups `(("ORG"
                    ("<f11>    " . "Quick Capture → inbox")
                    ("<f12>    " . "Dashboard agenda"))
                   ("CAPTURE"
                    ("SPC X    " . "Capture template"))
                   ("ROAM"
                    ("C-c n c  " . "Capture note")
                    ("C-c n f  " . "Find node")
                    ("C-c n i  " . "Insert node link")
                    ("C-c n l  " . "Toggle roam buffer")))))
    (insert "\n\n\n")
    (dolist (group groups)
      (let ((label (car group))
            (rows  (cdr group)))
        (insert pad (propertize label 'face 'font-lock-keyword-face) "\n")
        (insert pad sep "\n")
        (dolist (row rows)
          (insert pad
                  (propertize (car row) 'face 'font-lock-string-face)
                  (propertize (cdr row) 'face 'font-lock-comment-face)
                  "\n"))
        (insert "\n\n\n")))))

(setq +dashboard-functions
      '(jd/dashboard-widget-header
        jd/dashboard-widget-keys))
