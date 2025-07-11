;; This operating-system image definition can be built with:
;; `guix system image -L . -t iso9660 systoleos/base.scm`

(define-module (systoleos base)
                #:use-module (gnu)
                #:use-module (gnu machine)
                #:use-module (gnu machine ssh)
                #:use-module (guix)
                #:use-module (guix channels)
                #:use-module (guix gexp)
                #:use-module (guix build utils)
                #:use-module (guix build-system trivial)
                #:use-module (gnu packages version-control)
                #:use-module (gnu packages vim)
                #:use-module (gnu packages ssh)
                #:use-module (gnu packages gnome)
                #:use-module (gnu packages curl)
                #:use-module (gnu packages linux)
                #:use-module (gnu packages mtools)
                #:use-module (gnu packages package-management)
                #:use-module (gnu packages terminals)
                #:use-module (gnu packages xorg)
                #:use-module (gnu packages conky)
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
                #:use-module (gnu services ssh)
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
                #:use-module (guix-systole services dicomd-service)
                #:use-module (guix-systole packages slicer)
                #:use-module (guix-systole packages openigtlink))


;; ############################################################################
;;      System image definition here:
;; ############################################################################

;; Fluxbox configuration inspired by guix-psy-dicom
;; https://github.com/OUH-MESHLab/guix-psy-dicom/blob/enhancement/psydicom_system/config.scm
(define conkyrc
  (local-file "etc/conky/conky.conf"))
(define fluxbox-init
  (local-file "etc/fluxbox/init"))
(define fluxbox-keys
  (local-file "etc/fluxbox/keys"))
(define fluxbox-startup
  (local-file "etc/fluxbox/startup"))
(define ideskrc
  (local-file "etc/idesk/ideskrc"))
(define idesk-icon-lnk
  (local-file "etc/idesk/DICOMStore.lnk"))
(define nftables-config
  (local-file "etc/misc/nftables.conf"))
(define fluxbox-startup-with-slicer
  (computed-file
    "fluxbox-startup-with-slicer"
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
                ;; Append Slicer and exec fluxbox at the end
                (display (string-append #$(file-append slicer-5.8 "/Slicer-wrapper") " &\n"
                                        "exec fluxbox -log ~/.fluxbox/log\n") out))))))))
;; Slicerapp-real in ~/.fluxbox/apps

(define user-home
  (home-environment
    (packages (list slicer-5.8 slicer-openigtlink))
    (services
     (cons* (service home-xdg-configuration-files-service-type
                     `())
            (service home-files-service-type
                     `((".fluxbox/init" ,fluxbox-init)
                       (".fluxbox/keys" ,fluxbox-keys)
                       ; (".fluxbox/startup" ,fluxbox-startup)
                       (".fluxbox/startup" ,fluxbox-startup-with-slicer)
                       (".ideskrc" ,ideskrc))) %base-home-services))))

(define-public systoleos-base
  (operating-system
    (inherit installation-os)

    ;; Use the full Linux kernel from Nonguix channel
    ;; so that the image can run on most commercial hardware
    ;(kernel linux)
    ; (initrd microcode-initrd)
    ;(firmware (list linux-firmware iucode-tool amd-microcode intel-microcode))

    ;; Add the 'net.ifnames' argument to prevent network interfaces
    ;; from having really long names.  This can cause an issue with
    ;; wpa_supplicant when you try to connect to a wifi network.
    ;(kernel-arguments '("quiet" "modprobe.blacklist=radeon,amdgpu" "net.ifnames=0"))

    (host-name "systole")
    (timezone "Europe/Oslo")

    ;; Use the UEFI variant of GRUB with the EFI System
    ;; Partition mounted on /boot/efi.
    (bootloader (bootloader-configuration
                  (bootloader grub-efi-bootloader)
                  (targets '("/boot/efi"))))


    (file-systems (append (list (file-system
                                  (device "/dev/nvme0n1p3")  ;; Specify where your system is mounted.
                                  (mount-point "/")     ;; Setup a mounting point. 
                                  (type "ext4"))
								(file-system
								  (device "/dev/nvme0n1p1")
								  (mount-point "/boot/efi")
								  (type "vfat")))       ;; Specify the file system. 
                                    %base-file-systems))

    ;; The `brainlabmirror` account must be initialised with `passwd` command
    (users (append (list 
                     (user-account
                           (name "brainlabmirror")
                           (comment "BrainLab")
                           (uid 1000)
                           (password "")
                           (group "users")
                           (home-directory "/home/brainlabmirror")
                           (supplementary-groups (list "dicom" "netdev"
                                                       "audio" "video" "wheel")))
    
                     (user-account
                           (name "systole")
                           (comment "test")
                           (uid 1003)
                           (password "")
                           (group "users")
                           (home-directory "/home/systole")
                           (supplementary-groups (list "dicom" "netdev"
                                                       "audio" "video" "wheel"))))
                   %base-user-accounts))

    (sudoers-file
     (plain-file "sudoers"
                 (string-append (plain-file-content %sudoers-specification)
                                (format #f "~a ALL = NOPASSWD: ALL~%"
                                        "brainlabmirror"))))

    (setuid-programs (append (list (setuid-program
                                   (program (file-append sudo "/bin/sudo"))))
                           %setuid-programs))

    (packages (append (list
                       ;; Slicer
                       ; slicer-5.8

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
                       openssh

                       ;; desktop environment
                       conky
                       feh
                       fluxbox
                       font-bitstream-vera
                       font-dejavu
                       idesk
                       oxygen-icons
                       thunar
                       xrandr) %base-packages))

    (services
     (append (list

                   ;; LightDM display manager
                   ;; Configuration documentation: https://guix.gnu.org/manual/en/html_node/X-Window.html
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
                                                                  "brainlabmirror")
                                                                 (user-session
                                                                  ;; "xfce.desktop"
                                                                  "fluxbox"))))))
                   
                   ;; nftables service
                   (service nftables-service-type
                            (nftables-configuration (ruleset (local-file
                                                              "etc/nftables.conf"))))

                   (service guix-home-service-type
                            `(("brainlabmirror" ,user-home)))

                   (set-xorg-configuration
                    (xorg-configuration (keyboard-layout (keyboard-layout
                                                          "altgr-intl")))
                    lightdm-service-type)

                   ;; Use Dicomd service defined in guix-systole
                   (service dicomd-service-type)

                   ;; Symlink background artwork into the OS image
                   (extra-special-file
                     "/run/current-system/profile/share/backgrounds/systole/Systole_Magnet_base_1280_1024.png"
                     (local-file "../guix-systole-artwork/backgrounds/Systole_Magnet_base_1280_1024.png"))

                    (service openssh-service-type
                      (openssh-configuration
                        (public-key-authentication? #t)
                        (password-authentication? #f)
                        (authorized-keys
                          `(("brainlabmirror" ,(local-file "/home/khai/.ssh/id_rsa.pub"))))))

                   )

             (modify-services %desktop-services
               (delete gdm-service-type)
               (guix-service-type config =>
                                  (guix-configuration
                                   (authorized-keys (append `(,(local-file
                                                                "/etc/guix/signing-key.pub")) %default-authorized-guix-keys)))))

             ))))
