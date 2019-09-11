(defun screen2latex-get-screenshot (filename)
  "Get a screenshot, and save it at filename"

  ;; Use the appropriate program to take the screenshot, based on the os
  (cond
   ((string-equal system-type "darwin") ; Mac OS X
    (progn
      (call-process "screencapture" nil nil nil "-i" filename)))
   ((string-equal system-type "gnu/linux") ; Linux
    (progn
      (call-process "gnome-screenshot" nil nil nil "-a" "-f" filename)))
   )
  )

(defun screen2latex ()
  "Get a screenshot for a mathematical formula and insert the corresponding LaTeX at point."

  (interactive)

  (require 'request) ;; We need request to call the Mathpix API

  ;; Load secrets
  (load-file "auth.el.gpg")

  ;; Temporary file where to save the screenshot
  (setq filename "/tmp/screentemp.png")

  ;; Convert the image to base64
  (setq image-buffer (find-file-noselect filename t t))
  (setq image (with-current-buffer image-buffer
                (base64-encode-string (buffer-string) t)))

  ;; Convert the image to LaTeX using Mathpix's OCR service
  (message "Converting...")
  (setq r (request
           "https://api.mathpix.com/v3/latex"
           :type "POST"
           :headers `(("app_id" . ,mathpix_app_id)
                      ("app_key" . ,mathpix_app_key)
                      ("Content-type" . "application/json"))
           :data (json-encode-alist
                  `(("src" . ,(concat "data:image/png;base64," image))
                    ("formats" . ,(list "latex_styled"))
                    ("format_options" .
                     ,`(("latex_styled" .
                         ,`(("transforms" .
                             (cons "rm_spaces" '()))))))))
           :parser 'json-read
           :sync t
           :complete (cl-function
                      (lambda (&key response &allow-other-keys)
                        (insert (alist-get 'latex_styled (request-response-data response)))
                        ))))

  ;; Clean up
  (delete-file filename)
  (kill-buffer image-buffer)
  )
