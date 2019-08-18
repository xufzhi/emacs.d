;;; key bindings ---------------------------------------------------------------
(define-prefix-command 'emacs-prefix-key)
(global-set-key (kbd "M-;") 'emacs-prefix-key)

(defun epk-toggle-comment (&optional arg)
  (interactive "*P")
  (comment-normalize-vars)
  (if (and (not (region-active-p)) (not (looking-at "[ \t]*$")))
      (comment-or-uncomment-region (line-beginning-position)
                                   (line-end-position))
    (comment-dwim arg)))
(global-set-key (kbd "M-; M-;") 'epk-toggle-comment)

(defvar current-date-format "%Y-%m-%d")
(defvar current-datetime-format "%Y-%m-%d %H:%M:%S")
(defun epk-insert-date ()
  (interactive)
  (insert (format-time-string current-date-format (current-time))))
(defun epk-insert-datetime ()
  (interactive)
  (insert (format-time-string current-datetime-format (current-time))))

(global-set-key (kbd "M-; M-d") 'epk-insert-date)
(global-set-key (kbd "M-; d") 'epk-insert-datetime)

(defun epk-buffer-format ()
  (interactive)
  (indent-region (point-min) (point-max) nil)
  (delete-trailing-whitespace))
(global-set-key (kbd "M-; M-f") 'epk-buffer-format)

(defun epk-buffer-format-notab ()
  (interactive)
  (indent-region (point-min) (point-max) nil)
  (untabify (point-min) (point-max))
  (delete-trailing-whitespace))
(global-set-key (kbd "M-; f") 'epk-buffer-format-notab)

(defun epk-dos2unix ()
  "Automate M-% C-q C-m RET RET"
  (interactive)
  (save-excursion
    (goto-char (point-min))
    (while (search-forward (string ?\C-m)  nil t)
      (replace-match "" nil t))))

(global-set-key (kbd "M-; M-u") 'epk-dos2unix)

;;; bugfix config --------------------------------------------------------------

;; BUG: the `.emacs.d' directory being in `load-path'.
;; I find this was caused by following line, just ignore this warning.
;; (autoload 'python-mode "python-mode" "Python Mode." t)
;; change to (require 'python-mode) not fix the warning.
(defadvice display-warning
    (around no-warn-.emacs.d-in-load-path (type message &rest unused) activate)
  "Ignore the warning about the `.emacs.d' directory being in `load-path'."
  (unless (and (eq type 'initialization)
               (string-prefix-p "Your `load-path' seems to contain\nyour `.emacs.d' directory"
                                message t))
    ad-do-it))

;; BUG: Loading a theme can run Lisp code.  Really load?
(setq custom-safe-themes t)

;; BUG: start with max window
;; ref: http://emacs.stackexchange.com/questions/2999
;; How to maximize my Emacs frame on start-up
(add-to-list 'default-frame-alist '(fullscreen . maximized))

;;; font config ----------------------------------------------------------------
(add-to-list 'default-frame-alist
             '(font . "Ubuntu Mono:pixelsize=18"))

(defvar emacs-english-font "Ubuntu Mono"
  "The font name of English.")

(defvar emacs-cjk-font "WenQuanYi Micro Hei Mono"
  "The font name for CJK.")

(defvar emacs-font-size-pair '(18 . 18)
  "Default font size pair for (english . chinese)")

(defvar emacs-font-size-pair-list
  '((14 . 14) (16 . 16) (18 . 18)
    (20 . 20) (22 . 22) (24 . 24)
    (28 . 28) (32 . 32) (36 . 36)
    (40 . 40) (44 . 44) (48 . 48)
    (52 . 52) (56 . 56) (60 . 60))
  "This list is used to store matching (englis . chinese) font-size.")

(defun font-exist-p (fontname)
  "Test if this font is exist or not."
  (if (or (not fontname) (string= fontname ""))
      nil
    (if (not (x-list-fonts fontname)) nil t)))

(defun set-font (english chinese size-pair)
  "Setup emacs English and Chinese font on x window-system."

  (if (font-exist-p english)
      (set-frame-font (format "%s:pixelsize=%d" english (car size-pair)) t))

  (if (font-exist-p chinese)
      (dolist (charset '(kana han symbol cjk-misc bopomofo))
        (set-fontset-font (frame-parameter nil 'font) charset
                          (font-spec :family chinese :size (cdr size-pair))))))

;; Setup font size based on emacs-font-size-pair
(when window-system
  (set-font emacs-english-font emacs-cjk-font emacs-font-size-pair)
  )

(add-to-list 'after-make-frame-functions
             (lambda (new-frame)
               (select-frame new-frame)
               (if window-system
                   (set-font emacs-english-font emacs-cjk-font emacs-font-size-pair)
                 )))

(defun emacs-using-big-font ()
  "Using big font."
  (interactive)
  (add-to-list 'default-frame-alist
               '(font . "Ubuntu Mono:pixelsize=24"))
  (setq emacs-font-size-pair '(24 . 24))
  (set-font emacs-english-font emacs-cjk-font emacs-font-size-pair)
  (message "emacs using big font")
  )

(if (and ; (string-equal system-type "windows-nt")
     (window-system)
     (> (x-display-pixel-width) 1500))
    (add-hook 'after-init-hook 'emacs-using-big-font))

(defun emacs-step-font-size (step)
  "Increase/Decrease Emacs's font size.
STEP can be negative."
  (let ((scale-steps emacs-font-size-pair-list))
    (if (< step 0) (setq scale-steps (reverse scale-steps)))
    (setq emacs-font-size-pair
          (or (cadr (member emacs-font-size-pair scale-steps))
              emacs-font-size-pair))
    (when emacs-font-size-pair
      (message "emacs font size set to %.1f" (car emacs-font-size-pair))
      (set-font emacs-english-font emacs-cjk-font emacs-font-size-pair))))

(defun increase-emacs-font-size ()
  "Decrease Emacs's font-size acording emacs-font-size-pair-list."
  (interactive) (emacs-step-font-size 1))

(defun decrease-emacs-font-size ()
  "Increase Emacs's font-size acording emacs-font-size-pair-list."
  (interactive) (emacs-step-font-size -1))

(global-set-key (kbd "C-x C-=") 'increase-emacs-font-size)
(global-set-key (kbd "C-x C--") 'decrease-emacs-font-size)

;;; appearance config ----------------------------------------------------------
(dolist (hook '(c-mode-hook
                c++-mode-hook
                go-mode-hook
                python-mode-hook
                makefile-mode-hook
                java-mode-hook
                lisp-mode-hook
                emacs-lisp-mode-hook
                perl-mode-hook
                org-mode-hook
                js-mode-hook
                markdown-mode-hook
                ))
  (add-hook hook (lambda () (linum-mode 1))))

(setq whitespace-style '(face tabs trailing))
(setq-default comment-column 40)
(setq-default fill-column 79)

;;; edit config ----------------------------------------------------------------
(require 'browse-kill-ring)
(browse-kill-ring-default-keybindings)
(global-set-key (kbd "M-y") 'browse-kill-ring)


;;; c/cpp config ---------------------------------------------------------------
(require-package 'ggtags)

(setq ggtags-global-window-height 12)
(add-hook 'c-mode-common-hook
          (lambda ()
            (when (derived-mode-p 'c-mode 'c++-mode 'java-mode 'asm-mode)
              (ggtags-mode 1))))

(defun gtags-root-dir ()
  "Returns GTAGS root directory or nil if doesn't exist."
  (with-temp-buffer
    (if (zerop (call-process "global" nil t nil "-pr"))
        (buffer-substring (point-min) (1- (point-max)))
      nil)))

(defun gtags-update ()
  "Make GTAGS incremental update"
  (when (gtags-root-dir)
    (call-process "global" nil nil nil "-u")))

(defun gtags-update-single (filename)
  "Update Gtags database for changes in a single file"
  (interactive)
  (start-process "update-gtags" "update-gtags" "bash" "-c" (concat "cd " (gtags-root-dir) " ; gtags --single-update " filename )))

(defun gtags-update-current-file()
  (interactive)
  (defvar filename)
  (setq filename (replace-regexp-in-string (gtags-root-dir) "." (buffer-file-name (current-buffer))))
  (gtags-update-single filename)
  (message "Gtags updated for %s" filename))

;;; git config------------------------------------------------------------------

(require-package 'helm)
(require-package 'helm-git-grep)
(require 'helm-git-grep)

(global-set-key (kbd "M-; g") 'helm-git-grep)
(define-key isearch-mode-map (kbd "M-; g") 'helm-git-grep-from-isearch)
(eval-after-load 'helm
  '(define-key helm-map (kbd "M-; g") 'helm-git-grep-from-helm))

(global-set-key (kbd "M-; M-g") 'helm-git-grep-at-point)


;;; golang config---------------------------------------------------------------
(require-package 'go-mode)
(require-package 'go-guru)
(require 'go-guru)

(setq gofmt-command "goimports")        ; goimports can cleanup imports

(defun fmt-golang ()
  (interactive)
  (when (eq major-mode 'go-mode)
    (progn
      (gofmt)
      (save-buffer)
      (go-remove-unused-imports t)
      (save-buffer)
      )
    ))

(add-hook 'go-mode-hook '(lambda ()
                           (local-set-key (kbd "M-; f") 'fmt-golang)
                           (local-set-key (kbd "M-.") 'godef-jump)
                           (local-set-key (kbd "M-*") 'pop-tag-mark)
                           (local-set-key (kbd "M-]") 'go-guru-referrers)))


;;; orgmode config -------------------------------------------------------------
(require-package 'org)
(require-package 'ox-reveal)
(require-package 'plantuml-mode)
(require 'org)

;; BUG: invalid funciton org-babel-header-args-safe-fn
;; https://lists.gnu.org/archive/html/emacs-orgmode/2015-08/msg00293.html
;; M-x byte-compile-file on ob-R.el

;; BUG: html export with bad strings for fci-mode.
;; https://github.com/alpaker/Fill-Column-Indicator/issues/45
(defun fci-mode-override-advice (&rest args))
(advice-add 'org-html-fontify-code :around
            (lambda (fun &rest args)
              (advice-add 'fci-mode :override #'fci-mode-override-advice)
              (let ((result  (apply fun args)))
                (advice-remove 'fci-mode #'fci-mode-override-advice)
                result)))



(setq org-export-default-language "zh-CN"
      org-startup-indented t
      org-startup-folded 'showall
      org-pretty-entities nil           ; forbid prettify formula
      org-description-max-indent 0
      org-src-fontify-natively t
      org-export-with-priority t
      org-export-with-section-numbers nil
      org-export-babel-evaluate nil     ; dont execute babel at export
      org-export-headline-levels 4
      org-export-with-sub-superscripts nil
      org-html-preamble "<div class=\"empty\">"
      org-html-postamble "</div>"
      org-html-head-include-default-style nil
      org-html-head-include-scripts nil
      org-export-time-stamp-file nil
      org-confirm-babel-evaluate nil)

(setq org-html-head
      "<style type=\"text/css\">
 <!--/*--><![CDATA[/*><!--*/
  .status { max-width: 1200px;
    margin: 2em auto; padding: 2em;
    background-color: #ffe; }
  .title { text-align: center; }
  .subtitle { text-align: center; font-size: 28px; }
  body { background-color: #034; font-size: 16px; }
  h1 { font-size: 28px; color: #055; text-align: center; }
  h2 { font-size: 24px; color: #007; border-left: solid 8px; padding-left: 5px;}
  h3 { font-size: 22px; color: #800; border-left: solid 8px; padding-left: 5px;}
  h4 { font-size: 20px; color: #050; border-left: solid 8px; padding-left: 5px;}
  h5 { font-size: 18px; color: #808; }
  a { text-decoration: none; }
  a:visited { color: blue; }
  a:hover { color: red; }
  p { margin: 0.5em 0; }
  ul { list-style: disc; }
  dl { overflow: hidden; margin: auto 1em; }
  dt, dd { display: inline; }
  dd p { display: inline; }
  dt { font-weight: bolder; }
  dt:before { content: \"\"; display: block; }
  dt:after { content: ': '; }
  .figure { text-align: center; }
  img { max-width: 90%; }
  table { min-width: 80%; margin: 0.5em auto;
      border-top:solid 3px; border-bottom:solid 3px; }
  th { background-color: #8ee; }
  td { font-family: monospace; }
  tr:nth-child(2n+1) { background-color: #ffe; }
  tr:nth-child(2n+2) { background-color: #eee; }
  .todo   { font-weight: bold; font-family: monospace; color: red; }
  .done   { font-weight: bold; font-family: monospace; color: green; }
  .priority { font-family: monospace; color: red; }
  .tag    { background-color: #eee; font-family: monospace; }
  .timestamp { color: #bebebe; }
  .timestamp-kwd { color: #5f9ea0; }
  .org-right  { margin-left: auto; margin-right: 0px;  text-align: right; }
  .org-left   { margin-left: 0px;  margin-right: auto; text-align: left; }
  .org-center { margin-left: auto; margin-right: auto; text-align: center; }
  .underline { text-decoration: underline; }
  blockquote { margin: 0;
               background-color: #eec; color: #a00;
               padding: 1px 5px;
               border-left: thick solid #a00;
               border-top: 1px solid #e1cc89;
               border-bottom: 1px solid #e1cc89;
  }
  pre {
    color: #ddc; background-color: #111;
    font-family: monospace; overflow: auto;
    margin: 1em; padding: 0.5em; }
  pre.src { position: relative; overflow: auto; }
  caption.t-above { caption-side: top; }
  caption.t-bottom { caption-side: bottom; }
  #org-div-home-and-up
   { text-align: right; white-space: nowrap; }
  textarea { overflow-x: auto; }
  .linenr { font-size: smaller }
  .code-highlighted { background-color: #ffff00; }
  .org-info-js_info-navigation { border-style: none; }
  #org-info-js_console-label
    { font-size: 10px; font-weight: bold; white-space: nowrap; }
  .org-info-js_search-highlight
    { background-color: #ffff00; color: #000000; font-weight: bold; }
 /*]]>*/-->
</style>
<script>
function h_toggle() {
    $(\"#table-of-contents\").hide();
    $(\"h2\").click(function() {$(this).parent().children().not(\"h2\").toggle();});
    $(\"h3\").click(function() {$(this).parent().children().not(\"h3\").toggle();});
    $(\"h4\").click(function() {$(this).parent().children().not(\"h4\").toggle();});
    $(\"h5\").click(function() {$(this).parent().children().not(\"h5\").toggle();});
}
this.key_fold = 70;                          // f: hide/show content
this.key_toc  = 84;                          // t: hide/show table-of-content
this.hide_level = 0;
document.onkeydown=function(event) {
    var e = event || window.event || arguments.callee.caller.arguments[0];
    if (e && !e.ctrlKey && !e.metaKey && !e.altKey && !e.shiftKey && e.keyCode == key_fold) {
        if (hide_level < 2) {
            hide_level = 2;
            $(\"h2\").parent().children().not(\"h2\").hide();
        } else if (hide_level < 3) {
            hide_level = 3;
            $(\"h2\").parent().children().not(\"h2\").show();
            $(\"h3\").parent().children().not(\"h3\").hide();
        } else if (hide_level < 4) {
            hide_level = 4;
            $(\"h3\").parent().children().not(\"h3\").show();
            $(\"h4\").parent().children().not(\"h4\").hide();
        } else {
            hide_level = 0;
            $(\"h2\").parent().children().not(\"h2\").show();
            $(\"h3\").parent().children().not(\"h3\").show();
            $(\"h4\").parent().children().not(\"h4\").show();
        }
    }
    else if (e && !e.ctrlKey && !e.metaKey && !e.altKey && !e.shiftKey && e.keyCode == key_toc) {
        $(\"#table-of-contents\").toggle();
    }
}
$(h_toggle)
</script>
"
      )

(setq org-babel-default-header-args
      (cons '(:results . "replace verbatim output")
            (assq-delete-all :results org-babel-default-header-args)))
(setq org-babel-default-header-args
      (cons '(:exports . "both")
            (assq-delete-all :exports org-babel-default-header-args)))

(setq org-time-stamp-formats '("<%Y-%m-%d>" . "<%Y-%m-%d %H:%M>"))
(setq org-emphasis-regexp-components
      '(" \t('\"{，。、：；！" "- \t.,:!?;\")}\\，。、：；！" " \t\r\n," "." 1))
(org-set-emph-re 'org-emphasis-regexp-components org-emphasis-regexp-components)

(setq org-todo-keywords
      (quote ((sequence "TODO(t!)" "WORK(w!)" "|" "DONE(d!)")
              (sequence "STOP(s!)" "XFER(x!)" "|" "UNDO(u!)"))))

(setq org-highest-priority ?A)
(setq org-lowest-priority  ?E)
(setq org-default-priority ?C)
(setq org-priority-faces
      '((?A . (:foreground "#EE0000" :weight bold))
        (?B . (:foreground "#CC8800" :weight bold))
        (?C . (:foreground "#00BB00" :weight bold))
        (?D . (:foreground "#AAAAAA" :weight bold))
        (?E . (:foreground "#888888" :weight bold))
        ))

(after-load 'org
  (org-babel-do-load-languages
   'org-babel-load-languages
   `((R . t)
     (ditaa . t)
     (dot . t)
     (emacs-lisp . t)
     (gnuplot . t)
     (haskell . nil)
     (latex . t)
     (ledger . t)
     (ocaml . nil)
     (octave . t)
     (python . t)
     (ruby . t)
     (screen . nil)
     (,(if (locate-library "ob-sh") 'sh 'shell) . t)
     (sql . nil)
     (plantuml . t)
     (sqlite . t))))

;;; markdown config ------------------------------------------------------------
(require-package 'markdown-toc)
(require 'markdown-toc)

(setq markdown-toc-header-toc-start
      "<!-- markdown-toc start - Don't edit this section. -->")
(setq markdown-toc-header-toc-title
      "## Table of Contents ##")

(setq markdown-xhtml-header-content
      "<style type='text/css'>
body { color: #001122; background-color: #fffff0; font-size: 18px;
       max-width: 1200px; margin: 2em auto; padding: 2em;
}
a { color: #004466; text-decoration: none; }
a:hover { color: #660000; font-family: bold; }
h1 { font-size: 40px; color: #005555; text-align: center; }
h2 { font-size: 30px; color: #000077; border-left: solid 8px; padding-left: 5px;}
h3 { font-size: 28px; color: #880000; border-left: solid 8px; padding-left: 5px;}
h4 { font-size: 24px; color: #005500; border-left: solid 8px; padding-left: 5px;}
h5 { font-size: 22px; color: #880088;}
h6 { font-size: 20px; color: #000077;}
</style>")

(after-load 'markdown-mode
  (define-key markdown-mode-map (kbd "M-h") 'markdown-insert-header-dwim)
  (define-key markdown-mode-map (kbd "M-; i") 'markdown-toc-generate-or-refresh-toc)
  (define-key markdown-mode-map (kbd "M-; v") 'markdown-export-and-preview) ; simple html
  )

;; markdown mode should keep trailing-whitespace on return,
;; but delete them on save.
(add-hook 'markdown-mode-hook
          (lambda () (add-to-list 'write-file-functions 'delete-trailing-whitespace)))

(add-hook 'markdown-mode-hook 'orgtbl-mode)

;;; snippet config -------------------------------------------------------------
(require-package 'yasnippet)
(require 'yasnippet)

;; use only my own snippets, must init before set yas-global-mode
(setq yas-snippet-dirs '("~/.emacs.d/snippets"))

(yas-reload-all)                        ; (yas-global-mode 1) break magit
(dolist (hook '(prog-mode-hook
                org-mode-hook
                markdown-mode-hook
                emacs-lisp-mode-hook))
  (add-hook hook (lambda () (yas-minor-mode))))


;;; dockerfile config ----------------------------------------------------------
(require-package 'dockerfile-mode)
(require 'dockerfile-mode)

;;; end ------------------------------------------------------------------------
(provide 'init-local)
