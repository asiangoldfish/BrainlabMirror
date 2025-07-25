(define-module (systoleos monk)
                #:use-module (gnu)
                #:use-module (gnu machine)
                #:use-module (guix)
                #:use-module (guix channels)
                #:use-module (guix gexp)
                #:use-module (guix build utils)
                #:use-module (guix build-system trivial)
                #:use-module (gnu packages chromium)
                #:use-module (gnu packages version-control)
                #:use-module (gnu packages vim)
                #:use-module (gnu packages gnome)
                #:use-module (gnu packages curl)
                #:use-module (gnu packages linux)
                #:use-module (gnu packages mtools)
                #:use-module (gnu packages package-management)
                #:use-module (gnu packages terminals)
                #:use-module (gnu packages xorg)
                #:use-module (gnu packages image-viewers)
                #:use-module (gnu packages fonts)
                #:use-module (gnu packages wm)
                #:use-module (gnu packages kde-frameworks)
                #:use-module (gnu packages xfce)
                #:use-module (gnu packages admin)
                #:use-module (gnu services)
                #:use-module (gnu services base)
                #:use-module (gnu services guix)
                #:use-module (gnu services desktop)
                #:use-module (gnu services xorg)
                #:use-module (gnu services lightdm)
                #:use-module (gnu services networking)
                #:use-module (gnu system)
                #:use-module (gnu system image)
                #:use-module (gnu system install)
                #:use-module (gnu system shadow)
                #:use-module (gnu system file-systems)
                #:use-module (gnu system keyboard)
                #:use-module (gnu system setuid)
                #:use-module (gnu bootloader)
                #:use-module (gnu bootloader grub)
                #:use-module (gnu image)
                #:use-module (gnu packages)
                #:use-module (gnu home)
                #:use-module (gnu home services)

                #:use-module (nongnu packages linux)
                #:use-module (nongnu system linux-initrd)
                
                #:use-module (srfi srfi-1))


;; ############################################################################
;;      System image definition here:
;; ############################################################################
(define fluxbox-init
  (local-file "etc/fluxbox/init"))
(define fluxbox-keys
  (local-file "etc/fluxbox/keys"))
(define fluxbox-startup
  (local-file "etc/fluxbox/startup"))
(define nftables-config
  (local-file "etc/misc/nftables.conf"))
(define fluxbox-customised-startup
  (computed-file
    "fluxbox-customised-startup"
    #~(begin
        (use-modules (ice-9 rdelim))
        (call-with-input-file #$fluxbox-startup
          (lambda (in)
            (call-with-output-file #$output
              (lambda (out)
                (let loop ()
                  (let ((line (read-line in)))
                    (unless (eof-object? line)
                      (display line out)
                      (newline out)
                      (loop))))
                (display (string-append "chromium -kiosk https://revealjs.com/demo/" " &\n"
                                        "exec fluxbox -log ~/.fluxbox/log\n") out))))))))

(define user-home
  (home-environment
    (services
     (cons* (service home-xdg-configuration-files-service-type
                     `())
            (service home-files-service-type
                     `((".fluxbox/init" ,fluxbox-init)
                       (".fluxbox/keys" ,fluxbox-keys)
                       (".fluxbox/startup" ,fluxbox-customised-startup)
                       )) %base-home-services))))


(define-public systoleos-monk
  (operating-system
    (inherit installation-os)

    ;; Use the full Linux kernel from Nonguix channel
    ;; so that the image can run on most commercial hardware
    (kernel linux)
    (initrd microcode-initrd)
    (firmware (list linux-firmware iucode-tool amd-microcode intel-microcode))

    (host-name "monk")
    (timezone "Europe/Oslo")

    (bootloader (bootloader-configuration
                  (bootloader grub-efi-bootloader)
                  (targets '("/boot/efi"))))

    (users (append (list 
                     (user-account
                           (name "monk")
                           (comment "")
                           (uid 1000)
                           (password "")
                           (group "users")
                           (home-directory "/home/monk")
                           (supplementary-groups (list "netdev"
                                                       "audio" "video")))
    
                     (user-account
                           (name "admin")
                           (comment "")
                           (uid 1003)
                           (password "")
                           (group "users")
                           (home-directory "/home/admin")
                           (supplementary-groups (list "netdev"
                                                       "audio" "video" "wheel"))))
                   %base-user-accounts))

    (sudoers-file
     (plain-file "sudoers"
                 (string-append (plain-file-content %sudoers-specification)
                                (format #f "~a ALL = NOPASSWD: ALL~%"
                                        "admin"))))

    (setuid-programs (append (list (setuid-program
                                   (program (file-append sudo "/bin/sudo"))))
                           %setuid-programs))

    (packages (append (list
                       ;; terminal emulator
                       xterm
                       xf86-input-mouse

                       ;; utils
                       git
                       curl
                       vim
                       sudo

                       ;; Network
                       network-manager
                       ungoogled-chromium

                       ;; desktop environment
                       feh
                       fluxbox
                       font-bitstream-vera
                       font-dejavu
                       oxygen-icons
                       thunar
                       xrandr) %base-packages))

    (services
     (append (list
                   (service lightdm-service-type
                            (lightdm-configuration (allow-empty-passwords? #t)
                                                   (debug? #t)
                                                   (xdmcp? #t)
                                                   (vnc-server? #f)
                                                   (greeters (list (lightdm-gtk-greeter-configuration
                                                                    (allow-debugging?
                                                                     #t))))
                                                   (seats (list (lightdm-seat-configuration
                                                                 (name "*")
                                                                 (autologin-user
                                                                  "monk")
                                                                 (user-session
                                                                  "fluxbox"))))))
                   
                   (service nftables-service-type
                            (nftables-configuration (ruleset (local-file
                                                              "etc/nftables.conf"))))

                   (service guix-home-service-type
                            `(("monk" ,user-home)))

                   (set-xorg-configuration
                    (xorg-configuration (keyboard-layout (keyboard-layout
                                                          "altgr-intl")))
                    lightdm-service-type)

                    (extra-special-file
                      "/etc/NetworkManager/system-connections/KD_5G.nmconnection"
                      (local-file "etc/NetworkManager/KD_5G.nmconnection"))
                      )

             (modify-services %desktop-services
               (delete gdm-service-type))))))
