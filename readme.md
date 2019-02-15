# Understanding Windows x64 Assembly code repository #

## About ##

This repository hosts the code samples for the [accompanying tutorial](https://sonictk.github.io/asm_tutorial/).

It also contains a whole host of other samples that I was playing with when going
through [Ray Seyfarth's books](http://rayseyfarth.com/) on the subject.

## Usage ##

Please refer to the instructions in the `build.bat` script for instructions on how t
to build the examples in this repository. Folders contain their own build scripts
for their own individual projects.

## Sample ``.dir-locals.el`` files

This is what I use for when I'm programming in Emacs.

### Windows
```
(
 (nil . ((tab-width . 4)))

 (nasm-mode . ((tab-width . 4)
               (indent-tabs-mode . nil)
               (nasm-after-mnemonic-whitespace . :space)
               (compile-command . "build.bat release")
               (cd-compile-directory . "C:\\Users\\sonictk\\Git\\experiments\\nasm_learning")
               ))

 (c++-mode . ((c-basic-offset . 4)
              (tab-width . 4)
              (indent-tabs-mode . t)
              (compile-command . "build.bat release")
              (cd-compile-directory . "C:\\Users\\sonictk\\Git\\experiments\\nasm_learning")
              (cc-search-directories . ("."))
              ))

 (c-mode . ((c-basic-offset . 4)
            (tab-width . 4)
            (indent-tabs-mode . t)
            (compile-command . "build.bat release")
            (cd-compile-directory . "C:\\Users\\sonictk\\Git\\experiments\\nasm_learning")
            (cc-search-directories . ("."))
            ))
 )
```
