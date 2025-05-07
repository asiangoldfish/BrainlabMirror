;; This operating-system image definition can be built with:
;; `guix system image -L . -t iso9660 guix-systole/systoleos/systoleos.scm`

(define-module (systoleos brainlabmirror)
  #:use-module (systoleos base)
  #:use-module (guix channels)
  #:use-module (guix gexp)
  #:use-module (guix build utils)
  #:use-module (guix build-system trivial)
  #:use-module ((guix licenses)
                #:prefix license:)
  #:use-module (gnu packages version-control)
  #:use-module (gnu packages vim)
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
  #:use-module (gnu bootloader)
  #:use-module (gnu bootloader grub)
  #:use-module (gnu image)
  #:use-module (gnu packages)
  #:use-module (gnu home)
  #:use-module (gnu home services)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  #:use-module (guix-systole services dicomd-service)
  #:use-module (guix-systole packages slicer))

(define systoleos-configuration
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

systoleos-configuration
