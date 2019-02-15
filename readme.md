# NASM Learning

## About

Various exercises to get familiar with programming for the x86-64 instruction set.

## Sample ``.dir-locals.el`` files

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
