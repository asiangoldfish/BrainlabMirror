# SystoleOS Guix definition

This is a definition for SystoleOS, a 3D Slicer-centric operating system based on GNU Guix that provides a modularised version of 3D Slicer and comes preconfigured with the `guix-systole` Guix channel.

## Cloning the repository

This repository contains a git submodule. In order to clone it locally, run `git clone --recurse-submodules https://github.com/OUH-MESHLab/BrainlabMirror`. If you have already cloned the repository without the `--recurse-submodules` flag, run the following from within the repository: `git submodule update --init`.

## Generating a SystoleOS image

Guix needs to be setup on the system in order to use this definition.

For the time being, this definition needs the `guix-systole` repository to be cloned locally. Clone it with the command `git clone https://github.com/SystoleOS/guix-systole --branch dev` in a local path.

The image can then be generated by `cd`ing to this repository and executing the command `guix system image -L path/to/guix-systole/repo -t iso9660 systoleos/brainlabmirror.scm`. Guix will then provide the path to the generated image in the Store.

The `brainlabmirror` image provides a full image with adjustments meant to run on bare metal. If you only need an image for a VM, then replace `brainlabmirror.scm` with `base.scm`.

N.B.: to build the `brainlabmirror` image, the building machine needs to be configured to pull from the Nonguix channel. See how [here](https://gitlab.com/nonguix/nonguix/-/blob/master/README.org?ref_type=heads&plain=1#L43).

Other types of images can also be generated. For example, to generate an image to run with QEMU/KVM, use `-t qcow2`, then boot into the generated virtual disk with QEMU.

To find out which image types are available, run `guix system image --list-image-types`.

## Generating a VM

Guix can generate a VM out of an OS definition and provide a script to run the VM.

This feature depends on QEMU/KVM.

To do so, run `guix system vm systoleos/base.scm`. Guix will then provide the path to a Bash script in the Store.

This script can be run with arguments to pass directly to QEMU. For example, to enable networking and request 1GB of RAM (from the [Guix manual](https://guix.gnu.org/manual/en/html_node/Invoking-guix-system.html#index-virtual-machine)):

`/gnu/store/…-run-vm.sh -m 1024 -smp 2 -nic user,model=virtio-net-pci`

Refer to the [Guix manual](https://guix.gnu.org/manual/en/html_node/Invoking-guix-system.html) for more details.
