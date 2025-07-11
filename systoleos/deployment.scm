;; ############################################################################
;;      Deployment configuration for SystoleOS BrainLab Mirror
;; ############################################################################
;; Deployment guide:
;; ======
;; Deployment with the suggested method requires a local copy of the 
;; guix-systole repository at https://github.com/SystoleOS/guix-systole.git, and
;; a local copy of BrainlabMirror repository at 
;; https://github.com/OUH-MESHlab/BrainlabMirror.git.
;;
;; You are advised to review BrainlabMirror/systoleos/base.scm before
;; deployment. Either change parameters there, or adjust parameters in the
;; inhereted operating system in this file.

;; Usage: guix deploy -L /path/to/guix-systole -L /path/to/brainlabmirror
;;          deployment.scm

(use-modules (systoleos base))

;; Uncomment the below to inherit from base and modify it.
; (define systole-deployment
;   (operating-system
;     (inherit systoleos-base)))

(list (machine
       (operating-system systoleos-base)      ; Specified OS definition.
       (environment managed-host-environment-type)
       (configuration (machine-ssh-configuration
                       (host-name "")                 ; Target IP address
                       (system "x86_64-linux")        ; Target system.
                       (user "brainlabmirror")        ; Target User for SSH.
                       (host-key "")
                       (identity "")                  ; Host ssh path.
                       (port 22)))))

