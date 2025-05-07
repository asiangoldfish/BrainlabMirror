(list (channel
        (name 'nonguix)
        (url "https://gitlab.com/nonguix/nonguix")
        (branch "master")
        (commit
          "6c497a883d8d517987071f91a8423c4a59d6f6ff")
        (introduction
          (make-channel-introduction
            "897c1a470da759236cc11798f4e0a5f7d4d59fbc"
            (openpgp-fingerprint
              "2A39 3FFF 68F4 EF7A 3D29  12AF 6F51 20A0 22FB B2D5"))))
      (channel
        (name 'guix)
        (url "https://codeberg.org/guix/guix-mirror.git")
        (branch "master")
        (commit
          "658dc3ff5efb3f17e66d4f692a45805fae007989")
        (introduction
          (make-channel-introduction
            "c91e27c60864faa229198f6f0caf620275c429a2"
            (openpgp-fingerprint
              "2841 9AC6 5038 7440 C7E9  2FFA 2208 D209 58C1 DEB0"))))
      (channel
        (name 'guix-systole)
        (url "https://github.com/SystoleOS/guix-systole")
        (branch
          "SCRUM-126-Define-package-for-SystoleOS-including-Slicer")
        (commit
          "c5d17e02d6daef9808297210b9d68078afe377b3")))
