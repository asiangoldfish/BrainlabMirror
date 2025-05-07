;; This operating-system image definition can be built with:
;; `guix system image -L . -t iso9660 guix-systole/systoleos/systoleos.scm`

(define-module (systoleos brainlabmirror)
  ; #:use-module (gnu packages linux)
  #:use-module (gnu system)
  ; #:use-module (gnu system image)
  ; #:use-module (gnu system install)
  #:use-module (gnu image)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:use-module (systoleos base))

(define systoleos-brainlabmirror
  (operating-system
    (inherit systoleos-base)

    ;; Use the full Linux kernel from Nonguix channel
    ;; so that the image can run on most commercial hardware
    (kernel linux)
    (initrd microcode-initrd)
    (firmware (list linux-firmware))

    ;; Add the 'net.ifnames' argument to prevent network interfaces
    ;; from having really long names.  This can cause an issue with
    ;; wpa_supplicant when you try to connect to a wifi network.
    (kernel-arguments '("quiet" "modprobe.blacklist=radeon,amdgpu" "net.ifnames=0"))))

systoleos-brainlabmirror
