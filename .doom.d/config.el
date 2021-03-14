;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets.
(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

      doom-font (font-spec :family "Roboto Mono" :size 15)
      doom-variable-pitch-font (font-spec :family "Libre Baskerville")
      doom-serif-font (font-spec :family "Libre Baskerville")

;; Doom exposes five (optional) variables for controlling fonts in Doom. Here
;; are the three important ones:
;;
;; + `doom-font'
;; + `doom-variable-pitch-font'
;; + `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;;
;; They all accept either a font-spec, font string ("Input Mono-12"), or xlfd
;; font string. You generally only need these two:
;; (setq doom-font (font-spec :family "monospace" :size 12 :weight 'semi-light)
;;       doom-variable-pitch-font (font-spec :family "sans" :size 13))

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'doom-one)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

(setq search-highlight t
      search-whitespace-regexp ".*?"
      isearch-lax-whitespace t
      isearch-regexp-lax-whitespace nil
      isearch-lazy-highlight t
      isearch-lazy-count t
      lazy-count-prefix-format " (%s/%s) "
      lazy-count-suffix-format nil
      isearch-yank-on-move 'shift
      isearch-allow-scroll 'unlimited)


;; Here are some additional functions/macros that could help you configure Doom:
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.


(use-package! org-roam
  :commands (org-roam-insert-immediate org-roam-find-file org-roam-switch-to-buffer org-roam)
  :hook
  (after-init . org-roam-mode)
  :init
  (map! :leader
        :prefix "n"
        :desc "org-roam" "l" #'org-roam
        :desc "org-roam-insert-immediate" "i" #'org-roam-insert-immediate
        :desc "org-roam-switch-to-buffer" "b" #'org-roam-switch-to-buffer
        :desc "org-roam-find-file" "f" #'org-roam-find-file
        :desc "org-roam-show-graph" "g" #'org-roam-show-graph
        :desc "org-roam-insert" "i" #'org-roam-insert
        :desc "org-roam-capture" "c" #'org-roam-capture
        :desc "org-roam-dailies-capture-today" "l" #'org-roam-dailies-capture-today)
  (setq org-roam-directory (file-truename "~/code/notes/pages")
        org-roam-db-gc-threshold most-positive-fixnum
        org-roam-graph-exclude-matcher "private"
        org-roam-tag-sources '(prop last-directory)
        org-id-link-to-org-use-id t)
  :config
  (setq org-roam-capture-ref-templates
        '(("r" "ref" plain (function org-roam-capture--get-point)
           "%?"
           :file-name "${slug}"
           :head "#+roam_key: ${ref}
#+roam_tags: website
#+title: ${title}

- source :: ${ref}"
           :unnarrowed t)))
  (add-to-list 'org-capture-templates `("c" "org-protocol-capture" entry (file+olp ,(expand-file-name "reading_and_writing_inbox.org" org-roam-directory) "The List")
                                         "* TO-READ [[%:link][%:description]] %^g"
                                         :immediate-finish t))
  (setq org-roam-dailies-directory "../journals")
  (setq org-roam-dailies-capture-templates
      '(("d" "default" entry
         #'org-roam-capture--get-point
         "* %?"
         :file-name "daily/%<%Y-%m-%d>"
         :head "#+title: %<%Y-%m-%d>\n\n")))
  (set-company-backend! 'org-mode '(company-capf)))

(use-package! anki-editor
  :commands (anki-editor-mode))

(use-package! org-download
  :commands
  org-download-dnd
  org-download-yank
  org-download-screenshot
  org-download-dnd-base64
  :init
  (map! :map org-mode-map
        "s-Y" #'org-download-screenshot
        "s-y" #'org-download-yank)
  (pushnew! dnd-protocol-alist
            '("^\\(?:https?\\|ftp\\|file\\|nfs\\):" . +org-dragndrop-download-dnd-fn)
            '("^data:" . org-download-dnd-base64))
  (advice-add #'org-download-enable :override #'ignore)
  :config
  (defun +org/org-download-method (link)
    (let* ((filename
            (file-name-nondirectory
             (car (url-path-and-query
                   (url-generic-parse-url link)))))
           ;; Create folder name with current buffer name, and place in root dir
           (dirname (concat "./images/"
                            (replace-regexp-in-string " " "_"
                                                      (downcase (file-name-base buffer-file-name)))))
           (filename-with-timestamp (format "%s%s.%s"
                                            (file-name-sans-extension filename)
                                            (format-time-string org-download-timestamp)
                                            (file-name-extension filename))))
      (make-directory dirname t)
      (expand-file-name filename-with-timestamp dirname)))
  :config
  (setq org-download-screenshot-method
        (cond (IS-MAC "screencapture -i %s")
              (IS-LINUX
               (cond ((executable-find "maim")  "maim -u -s %s")
                     ((executable-find "scrot") "scrot -s %s")))))
  (setq org-download-method '+org/org-download-method))






(smartparens-global-mode t)
(add-hook 'after-init-hook 'global-company-mode)

(setq company-minimum-prefix-length 2)

(setq company-idle-delay 0.25)

(add-to-list 'company-backends 'company-capf)

(setq completion-ignore-case t)

(setq org-roam-auto-replace-fuzzy-links nil)
(with-eval-after-load 'company
  (define-key company-active-map (kbd "C-n") #'company-select-next)
  (define-key company-active-map (kbd "C-p") #'company-select-previous))


(setq org-journal-dir "~/code/notes/journals")
;; (add-to-list 'org-agenda-files (expand-file-name "~/code/notes/journals"))


(use-package! org-journal
:bind (("C-c t" . journal-file-today)
        ("C-c y" . journal-file-yesterday))
:custom
(org-journal-dir "~/code/notes/journals")
(org-journal-file-format "%Y_%m_%d.org")
(org-journal-date-format "%e %b %Y (%A)")
(org-journal-time-format "")
:preface
(defun get-journal-file-today ()
"Gets filename for today's journal entry."
(let ((daily-name (format-time-string "%Y%m%d")))
(expand-file-name (concat org-journal-dir daily-name))))

(defun journal-file-today ()
"Creates and load a journal file based on today's date."
(interactive)
(find-file (get-journal-file-today)))

(defun get-journal-file-yesterday ()
"Gets filename for yesterday's journal entry."
(let* ((yesterday (time-subtract (current-time) (days-to-time 1)))
        (daily-name (format-time-string "%Y%m%d" yesterday)))
(expand-file-name (concat org-journal-dir daily-name))))

(defun journal-file-yesterday ()
"Creates and load a file based on yesterday's date."
(interactive)
(find-file (get-journal-file-yesterday))))


(setq org-agenda-files '("~/code/notes/journals"))

(setq
 mac-command-modifier 'meta
 projectile-project-search-path '("~/code/" "~/workspace/")
 dired-dwim-target t
 org-ellipsis " ▾ "
 org-bullets-bullet-list '("·")
 org-log-done 'time
 css-indent-offset 2
 org-refile-targets (quote ((nil :maxlevel . 1)))
 org-capture-templates '(("x" "Note" entry
                          (file+olp+datetree "journal.org")
                          "**** [ ] %U %?" :prepend t :kill-buffer t)
                         ("t" "Task" entry
                          (file+headline "tasks.org" "Inbox")
                          "* [ ] %?\n%i" :prepend t :kill-buffer t))
 +doom-dashboard-banner-file (expand-file-name "logo.png" doom-private-dir)
 +org-capture-todo-file "tasks.org"
 )




(use-package! org-super-agenda
  :after org-agenda
  :config
  (add-hook! 'after-init-hook 'org-super-agenda-mode)
  (setq
   org-agenda-skip-scheduled-if-done t
   org-agenda-skip-deadline-if-done t
   org-agenda-include-deadlines t
   org-agenda-include-diary nil
   org-agenda-block-separator nil
   org-agenda-compact-blocks t
   org-agenda-start-with-log-mode t)
  (org-super-agenda-mode)
  )

    (setq org-todo-keywords
     '((sequence
           "TODO(t)"  ; A task that needs doing & is ready to do
           "PROJ(p)"  ; An ongoing project that cannot be completed in one step
           "INPROCESS(s)"  ; A task that is in progress
           "⚑ WAITING(w)"  ; Something is holding up this task; or it is paused
           "|"
           "☟ NEXT(n)"
           "✰ IMPORTANT(i)"
           "DONE(d)"  ; Task successfully completed
           "✘ CANCELED(c@)") ; Task was cancelled, aborted or is no longer applicable
          (sequence
           "✍ NOTE(N)"
           "FIXME(f)"
           "☕ BREAK(b)"
           "❤ LOVE(l)"
           "REVIEW(r)"
           )) ; Task was completed
        org-todo-keyword-faces
        '(
          ("TODO" . (:foreground "#ff39a3" :weight bold))
          ("INPROCESS"  . "orangered")
          ("✘ CANCELED" . (:foreground "white" :background "#4d4d4d" :weight bold))
          ("⚑ WAITING" . "pink")
          ("☕ BREAK" . "gray")
          ("❤ LOVE" . (:foreground "VioletRed4"
                                   ;; :background "#7A586A"
                                   :weight bold))
          ("☟ NEXT" . (:foreground "DeepSkyBlue"
                                   ;; :background "#7A586A"
                                      :weight bold))
          ("✰ IMPORTANT" . (:foreground "greenyellow"
                                      ;; :background "#7A586A"
                                      :weight bold))
          ("DONE" . "#008080")
          ("FIXME" . "IndianRed")
          ))

(setq org-agenda-custom-commands

      '(("c" "Simple agenda view"
         ((tags "PRIORITY=\"A\""
                ((org-agenda-skip-function '(org-agenda-skip-entry-if 'todo 'done))
                 (org-agenda-overriding-header "High-priority unfinished tasks:")))
          (agenda "")
          (alltodo ""
                   ((org-agenda-skip-function
                     '
                          (org-agenda-skip-if nil '(scheduled deadline)))))))))


(setq org-agenda-custom-commands
      '(
        ("c" "Unscheduled TODO"
         (
          (agenda "")
          (todo ""
                ((org-agenda-overriding-header "\nUnscheduled TODO")
                 (org-agenda-skip-function '(org-agenda-skip-entry-if 'timestamp))))
          )
         nil
         nil)))


(setq org-agenda-custom-commands
      '(("z" "Super zaen view"
         ((agenda "" ((org-agenda-span 'day)
                      (org-super-agenda-groups
                       '((:name "Today"
                                :time-grid t
                                :date today
                                :todo "TODAY"
                                :scheduled today
                                :order 1)))))
          (alltodo "" ((org-agenda-overriding-header "")
                       (org-agenda-skip-function '(org-agenda-skip-entry-if 'timestamp))
                       (org-super-agenda-groups
                        '((:name "Next to do"
                                 :todo "NEXT"
                                 :order 1)
                          (:name "Important"
                                 :tag "Important"
                                 :priority "A"
                                 :order 6)
                          (:name "Due Today"
                                 :deadline today
                                 :order 2)
                          (:name "Due Soon"
                                 :deadline future
                                 :order 8)
                          (:name "Overdue"
                                 :deadline past
                                 :order 7)
                          (:name "Assignments"
                                 :tag "Assignment"
                                 :order 10)
                          (:name "Issues"
                                 :tag "Issue"
                                 :order 12)
                          (:name "Projects"
                                 :tag "Project"
                                 :order 14)
                          (:name "Emacs"
                                 :tag "Emacs"
                                 :order 13)
                          (:name "Research"
                                 :tag "Research"
                                 :order 15)
                          (:name "To read"
                                 :tag "Read"
                                 :order 30)
                          (:name "Waiting"
                                 :todo "WAITING"
                                 :order 20)
                          (:name "trivial"
                                 :priority<= "C"
                                 :tag ("Trivial" "Unimportant")
                                 :todo ("SOMEDAY" )
                                 :order 90)
                          (:discard (:tag ("Chore" "Routine" "Daily")))))))))))


(let ((org-super-agenda-groups
       '((:name "Books to read"
                :and (:todo "TO-READ" :tag ("book" "books")))
         (:discard (:anything t)))))
  (org-todo-list))



(add-to-list 'org-agenda-custom-commands
             '("W" "Weekly review"
               agenda ""
               ((org-agenda-span 'week)
                (org-agenda-start-on-weekday 0)
                (org-agenda-start-with-log-mode t)
                (org-agenda-skip-function
                 '(org-agenda-skip-entry-if 'nottodo 'done))
                 )))
