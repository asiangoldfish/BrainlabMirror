;; ############################################################################
;;      Deployment configuration for SystoleOS BrainLab Mirror
;; ############################################################################


;; Usage: guix deploy -L . deployment.scm


;; ############################################################################
;;  System image definition modules here:
;; ############################################################################

(use-modules (gnu)
             (gnu machine)
             (gnu machine ssh)
                (guix)
                (guix channels)
                (guix gexp)
                (guix build utils)
                (guix build-system trivial)
                (gnu packages version-control)
                (gnu packages vim)
                (gnu packages curl)
                (gnu packages linux)
                (gnu packages mtools)
                (gnu packages package-management)
                (gnu packages terminals)
                (gnu packages xorg)
                (gnu packages conky)
                (gnu packages image-viewers)
                (gnu packages fonts)
                (gnu packages wm)
                (gnu packages kde-frameworks)
                (gnu packages xfce)
                (gnu packages admin)
                (gnu services)
                (gnu services base)
                (gnu services guix)
                (gnu services desktop)
                (gnu services xorg)
                (gnu services lightdm)
                (gnu services networking)
                (gnu system)
                (gnu system image)
                (gnu system install)
                (gnu system shadow)
                (gnu system file-systems)
                (gnu system keyboard)
                (gnu system setuid)
                (gnu bootloader)
                (gnu bootloader grub)
                (gnu image)
                (gnu packages)
                (gnu home)
                (gnu home services)
                (nongnu packages linux)
                (nongnu system linux-initrd)
                (guix-systole services dicomd-service)
                (guix-systole packages slicer)
                (guix-systole packages openigtlink))


;; ############################################################################
;;      System image definition here:
;; ############################################################################

;; https://substitutes.nonguix.org/signing-key.pub
(define %signing-key
  (plain-file "nonguix.pub"
   "(public-key
 (ecc
  (curve Ed25519)
  (q #C1FD53E5D4CE971933EC50C9F307AE2171A2D3B52C804642A7A35F84F3A4EA98#)))"))

;; The Nonguix channel is necessary for the Linux kernel with nonfree blobs,
;; required by most commercial hardware.
(define %channels
  (cons* (channel
           (name 'nonguix)
           (url "https://gitlab.com/nonguix/nonguix")
           ;; Enable signature verification:
           (introduction
            (make-channel-introduction
             "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
             (openpgp-fingerprint
              "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
         (channel
           (name 'guix-systole)
           (url "https://github.com/SystoleOS/guix-systole")
           (branch "dev"))
         %default-channels
         ))

(define serialise-channels
  (scheme-file "channels.scm"
               #~(begin
                   (with-output-to-file %output
                     (lambda ()
                       (display (sexp->string '%
                                              (%channels)))
                       (newline))))))

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
                       (".idesktop/DICOMStore.lnk" ,idesk-icon-lnk)
                       (".conkyrc" ,conkyrc)
                       (".ideskrc" ,ideskrc))) %base-home-services))))

(define systoleos-brainlabmirror
  (operating-system
    (inherit installation-os)

    ;; Use the full Linux kernel from Nonguix channel
    ;; so that the image can run on most commercial hardware
    (kernel linux)
    ; (initrd microcode-initrd)
    (firmware (list linux-firmware iucode-tool amd-microcode intel-microcode))

    ;; Add the 'net.ifnames' argument to prevent network interfaces
    ;; from having really long names.  This can cause an issue with
    ;; wpa_supplicant when you try to connect to a wifi network.
    (kernel-arguments '("quiet" "modprobe.blacklist=radeon,amdgpu" "net.ifnames=0"))

    (host-name "systole")
    (timezone "Europe/Oslo")

    ;; Use the UEFI variant of GRUB with the EFI System
    ;; Partition mounted on /boot/efi.
    (bootloader (bootloader-configuration
                  (bootloader grub-efi-bootloader)
                  (targets '("/boot/efi"))))


    ;; ##########################################################
    ;;  file-systems field (Needs to be adapted to target machine)
    ;; ##########################################################

    (file-systems (append (list (file-system
                                  (device "/dev/vda3")  ;; Specify where your system is mounted.
                                  (mount-point "/")     ;; Setup a mounting point. 
                                  (type "ext4")))       ;; Specify the file system. 
                                    %base-file-systems))

    ;; The `brainlabmirror` account must be initialised with `passwd` command
    (users (append (list (user-account
                           (name "brainlabmirror")
                           (comment "BrainLab")
                           (password "")
                           (group "users")
                           (supplementary-groups (list "dicom" "netdev"
                                                       "audio" "video" "wheel")))
                         (user-account
                           (name "admin")
                           (comment "Admin")
                           (group "users")
                           (supplementary-groups (list "wheel" "netdev"
                                                       "audio" "video"))))
                   %base-user-accounts))

    (sudoers-file (plain-file "sudoers"
                              (string-append (plain-file-content
                                              %sudoers-specification)
                                             (format #f
                                              "~a ALL = NOPASSWD: ALL~%"
                                              "admin"))))

    (setuid-programs (append (list (setuid-program
                                   (program (file-append sudo "/bin/sudo"))))
                           %setuid-programs))

    (packages (append (list
                       ;; Slicer
                       ; slicer-5.8

                       ;; terminal emulator
                       xterm

                       ;; utils
                       git
                       curl
                       vim
                       sudo

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

                   ;; Services for xfce desktop environment
                   ;; (service xfce-desktop-service-type)
                   
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

                   ;; Include the channel file so that it can be used during installation
                   (extra-special-file "/etc/guix/channels.scm"
                                       serialise-channels)

                   ;; Symlink background artwork into the OS image
                   (extra-special-file
                     "/run/current-system/profile/share/backgrounds/systole/Systole_Magnet_base_1280_1024.png"
                     (local-file "../guix-systole-artwork/backgrounds/Systole_Magnet_base_1280_1024.png"))

                   )

             (modify-services %desktop-services
               (delete gdm-service-type)
               (guix-service-type config =>
                                  (guix-configuration (inherit config)
                                                      (guix (guix-for-channels
                                                             %channels))
                                                      (authorized-keys (cons*
                                                                        %signing-key
                                                                        %default-authorized-guix-keys))
                                                      (substitute-urls `(,@%default-substitute-urls
                                                                         "https://substitutes.nonguix.org"))
                                                      (channels %channels))))))))

;; ##########################################################
;;      Target(s) specified here: (Needs to be adapted to target(s))
;; ##########################################################

(list (machine
       (operating-system systoleos-brainlabmirror)      ; Specified OS definition.
       (environment managed-host-environment-type)
       (configuration (machine-ssh-configuration
                       (host-name "192.168.122.215")    ; Target IP address.
                       (system "x86_64-linux")          ; Target system.
                       (user "systole")                    ; Target User for SSH.
                       (identity "~/.ssh/id_rsa")       ; Host ssh path.
                       (port 22)))))                    ; Listening port.