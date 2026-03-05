;; -*- lexical-binding: t; -*-

;; ------ USER INTERFACE
;; Frame size
(setq default-frame-alist
      '((width . 110)
        (height . 64)))

(setq visual-fill-column-width 120
      visual-fill-column-center-text t)

(add-hook 'org-mode-hook #'visual-fill-column-mode)

(defun jd/org-mode-visual-fill ()
  (visual-fill-column-mode 1))

;; Theme & Font
(setq doom-theme 'doom-gruvbox)
(setq doom-font (font-spec :family "Agave Nerd Font" :size 14))

;; Column number in modeline
(column-number-mode 1)

;; Line numbers (Doom way)
;; Options: nil, t, 'relative
(setq display-line-numbers-type 'relative)

;; Disable line numbers in specific modes
(dolist (mode '(org-mode-hook
                term-mode-hook
                shell-mode-hook
                eshell-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(setq confirm-kill-emacs nil)

;; ------ INDENTATION
(setq-default tab-width 2)
(setq-default evil-shift-width 2)
(setq-default indent-tabs-mode nil)

;; ------ ORG
(setq org-directory "~/st/org")

(defun jd/org-mode-setup ()
  (org-indent-mode)
  (visual-line-mode 1)
  (setq evil-auto-indent nil))

(after! org

  (add-hook 'org-mode-hook #'jd/org-mode-setup)
  (add-hook 'org-mode-hook #'hl-todo-mode)

  (setq org-ellipsis "..."
        org-hide-emphasis-markers t
        org-src-fontify-natively t
        org-fontify-quote-and-verse-blocks t
        org-src-tab-acts-natively t
        org-edit-src-content-indentation 2
        org-startup-folded 'showeverything
        org-cycle-separator-lines 2)

  (setq org-agenda-files
        '("~/st/org/archive.org"
          "~/st/org/tasks.org"
          "~/st/org/inbox.org"
          "~/st/org/meetings.org"
          "~/st/org/projects.org"))

  (setq org-log-done 'time
        org-log-into-drawer t
        org-agenda-start-with-log-mode t
        org-agenda-start-on-weekday 0)

  (setq org-todo-keywords
        '((sequence
           "TODO(t)" "NEXT(n)" "IN-PROGRESS(i)" "WAIT(w@/!)" "REVIEW(v)"
           "|" "DONE(d!)" "CANCELLED(c@)")
          (sequence
           "BACKLOG(b)" "PLANNED(p)" "READY(r)" "ACTIVE(a)" "HOLD(h@)"
           "|" "COMPLETED(m!)")))

  (defun jd/org-agenda-format-project (txt)
    "Append the PROJECT property of the task to the agenda item."
    (let ((proj (org-entry-get (get-text-property 0 'org-hd-marker txt) "PROJECT")))
      (if proj
          (concat txt " (" proj ")")
        txt)))

  (setq org-agenda-custom-commands
        '(("d" "Daily Agenda + Tasks with Project"
           ((agenda ""
                    ((org-agenda-span 1)
                     (org-agenda-overriding-header "Today's Schedule")))
            (alltodo ""
                     ((org-agenda-overriding-header "Meetings")
                      (org-agenda-files '("~/st/org/meetings.org"))))
            (alltodo ""
                     ((org-agenda-overriding-header "Tasks")
                      (org-agenda-files '("~/st/org/tasks.org"))))
            (alltodo ""
                     ((org-agenda-overriding-header "Inbox")
                      (org-agenda-files '("~/st/org/inbox.org"))))))))

  ;; Refile
  (setq org-refile-targets '((nil :maxlevel . 1)
                             (org-agenda-files :maxlevel . 1))
        org-outline-path-complete-in-steps nil
        org-refile-use-outline-path t)

  ;; Babel
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((emacs-lisp . t)))

  (push '("conf-unix" . conf-unix) org-src-lang-modes)

  ;; Evil keybindings
  ;;(after! evil
  ;;  (after! org
  ;;   (evil-define-key '(normal insert visual) org-mode-map
  ;;     (kbd "C-j") #'org-next-visible-heading
  ;;     (kbd "C-k") #'org-previous-visible-heading
  ;;     (kbd "M-j") #'org-metadown
  ;;     (kbd "M-k") #'org-metaup)))

  ;; Faces
  (set-face-attribute 'org-document-title nil
                      :font "Agave Nerd Font"
                      :weight 'bold
                      :height 1.0)

  (dolist (face '(org-level-1 org-level-2 org-level-3
                   org-level-4 org-level-5 org-level-6
                   org-level-7 org-level-8))
    (set-face-attribute face nil
                        :font "Agave Nerd Font"
                        :weight 'medium
                        :height 1.0))

  (set-face-attribute 'org-block nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-table nil :inherit 'fixed-pitch)
  (set-face-attribute 'org-code nil :inherit '(shadow fixed-pitch))
  (set-face-attribute 'org-verbatim nil :inherit '(shadow fixed-pitch))

  ;; Structure templates
  (require 'org-tempo)
  (add-to-list 'org-structure-template-alist '("sh" . "src sh"))
  (add-to-list 'org-structure-template-alist '("el" . "src emacs-lisp"))
  (add-to-list 'org-structure-template-alist '("py" . "src python"))
)

;; ------ EVIL ORG
(use-package! evil-org
  :after org
  :hook ((org-mode . evil-org-mode)
         (org-agenda-mode . evil-org-mode))
  :config
  (require 'evil-org-agenda)
  (evil-org-agenda-set-keys))

;; ------ ORG ROAM
(defun jd/org-get-projects ()
  "Return a list of project names from projects.org top-level headings."
  (let ((file "~/st/org/projects.org")
        projects)
    (when (file-exists-p file)
      (with-current-buffer (find-file-noselect file)
        (org-element-map (org-element-parse-buffer) 'headline
          (lambda (hl)
            (when (= (org-element-property :level hl) 1)
              (push (org-element-property :raw-value hl) projects))))))
    (reverse projects))) ;; reverse to keep original order

(use-package! org-roam
  :custom
  (org-roam-directory "~/st/org/")
  (org-roam-completion-everywhere t)

  (org-roam-capture-templates
   '(("d" "default" plain
      "%?"
      :if-new (file+head "${slug}.org"
                         "#+title: ${title}\n#+author: Jaj Dollesin\n#+date: %U\n\n")
      :unnarrowed t)

     ("p" "project" entry
      "* %^{Project Name}\n:PROPERTIES:\n:CREATED: %U\n:OWNER: Jaj Dollesin\n:REPO:%^{Repository}\n:END:\n** Details\n- Domain:\n- Server:%?"
      :target (file "projects.org")
      :unnarrowed t)

     ("t" "Task" entry
      "* TODO %^{Task}\n:PROJECT: %(completing-read \"Project: \" (jd/org-get-projects))\n%^G%?"
      :target (file "tasks.org")
      :prepend t
      :empty-lines 1
      :unnarrowed t)

     ("m" "Meeting" entry
      "* TODO %^{Meeting}\n:PROJECT: %^{Project}\nSCHEDULED: <%^{Date}>\n%?"
      :target (file "meetings.org")
      :unnarrowed t)

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

;; ------ AUTO ARCHIVE
(setq org-archive-location "~/st/org/archive.org::")
(setq org-archive-mark-done nil)

(defun jd/org-auto-archive-done-tasks ()
  (when (and (buffer-file-name)
             (string= (buffer-file-name)
                      (expand-file-name "~/st/org/tasks.org"))
             (string= org-state "DONE"))
    (org-archive-subtree)))

(add-hook 'org-after-todo-state-change-hook
          #'jd/org-auto-archive-done-tasks)
