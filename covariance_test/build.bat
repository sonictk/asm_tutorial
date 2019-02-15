@echo off
REM     Build script for the Covariance/correlation example.
REM     Usage: build.bat [debug|release|clean] <project_name> [msvc|clang] [exe|dll] <additional_linker_arguments>
REM     e.g. build.bat debug hello_world                    will build hello_world.asm in debug mode
REM     e.g. build.bat release goodbye_nothing clang        will build goodbye_nothing.asm in release mode using clang
REM     e.g. build.bat release goodbye_nothing clang dll    will build goodbye_nothing.asm in release mode using clang as a dynamic link libray instead of an executable

setlocal

echo Build script started executing at %time% ...
REM Process command line arguments. Default is to build in release configuration.
set BuildType=%1
if "%BuildType%"=="" (set BuildType=release)

set ProjectName=%2
if "%ProjectName%"=="" (set ProjectName=covariance_test)

set Compiler=%3
if "%Compiler%"=="" (set Compiler=msvc)

echo Building %ProjectName% in %BuildType% configuration using %Compiler% ...

if "%Compiler%"=="msvc" (
    REM    Set up the Visual Studio environment variables for calling the MSVC compiler;
    REM    we do this after the call to pushd so that the top directory on the stack
    REM    is saved correctly; the check for DevEnvDir is to make sure the vcvarsall.bat
    REM    is only called once per-session (since repeated invocations will screw up
    REM    the environment)
    if not defined DevEnvDir (
        call "%vs2017installdir%\VC\Auxiliary\Build\vcvarsall.bat" x64
        REM    Or maybe you're on VS 2015? Call this instead:
        REM call "C:\Program Files (x86)\Microsoft Visual Studio 14.0\VC\vcvarsall.bat" x64
    )
)

REM     Make a build directory to store artifacts; remember, %~dp0 is just a special
REM     FOR variable reference in Windows that specifies the current directory the
REM     batch script is being run in.
set BuildDir=%~dp0msbuild

if "%BuildType%"=="clean" (
    REM This allows execution of expressions at execution time instead of parse time, for user input
    setlocal EnableDelayedExpansion
    echo Cleaning build from directory: %BuildDir%. Files will be deleted^^!
    echo Continue ^(Y/N^)^?
    set /p ConfirmCleanBuild=
    if "!ConfirmCleanBuild!"=="Y" (
        echo Removing files in %BuildDir%...
        del /s /q %BuildDir%\*.*
    )
    goto end
)

echo Building in directory: %BuildDir% ...

if not exist %BuildDir% mkdir %BuildDir%
pushd %BuildDir%

set EntryPoint=%~dp0%ProjectName%_main.c

set OutBin=%BuildDir%\%ProjectName%.exe

set IncludePaths=%~dp0%..\thirdparty

set AsmDLL=%~dp0..\msbuild\covariance.obj

if "%Compiler%"=="msvc" (
    set CommonLinkerFlags=/subsystem:console /entry:main /incremental:no /machine:x64 /nologo
    set CommonLinkerFlags=%CommonLinkerFlags% /defaultlib:Kernel32.lib /defaultlib:User32.lib "%AsmDLL%"
    set DebugLinkerFlags=%CommonLinkerFlags% /opt:noref /debug /pdb:"%BuildDir%\%ProjectName%.pdb"
    set ReleaseLinkerFlags=%CommonLinkerFlags% /opt:ref

    set CommonCompilerFlags=/nologo /WX /I "%IncludePaths%"
    set CompilerFlagsDebug=%CommonCompilerFlags% /Od /Zi
    set CompilerFlagsRelease=%CommonCompilerFlags% /Ox /arch:AVX2

) else (
    set CommonLinkerFlags=-v -fuse-ld=lld-link -Wl,-machine:x64,-incremental:no,-subsystem:console,-entry:main,-nologo
    set CommonLinkerFlags=%CommonLinkerFlags%,-defaultlib:Kernel32.lib,-defaultlib:User32.lib "%AsmDLL%"
    set DebugLinkerFlags=%CommonLinkerFlags%,-opt:noref,-debug,-pdb:"%BuildDir%\%ProjectName%.pdb"
    set ReleaseLinkerFlags=%CommonLinkerFlags%,-opt:ref

    set CommonCompilerFlags=-Werror -pedantic-errors -I"%IncludePaths%"
    set CompilerFlagsDebug=%CommonCompilerFlags% -ggdb -O0
    set CompilerFlagsRelease=%CommonCompilerFlags% -g -O3
)


if "%BuildType%"=="debug" (
    if "%Compiler%"=="msvc" (
        set BuildCommand=cl %CommonCompilerFlags% %CompilerFlagsDebug% "%EntryPoint%" /Fe:"%OutBin%" /link %CommonLinkerFlags% %DebugLinkerFlags%
    ) else (
        set BuildCommand=clang %CommonCompilerFlags% %CompilerFlagsDebug% %DebugLinkerFlagsClang% %CommonLinkerFlagsClang% %EntryPoint% -o "%OutBin%"
    )
) else (
    if "%Compiler%"=="msvc" (
        set BuildCommand=cl %CommonCompilerFlags% %CompilerFlagsRelease% "%EntryPoint%" /Fe:"%OutBin%" /link %CommonLinkerFlags% %ReleaseLinkerFlags%
    ) else (
        set BuildCommand=clang %CommonCompilerFlags% %CompilerFlagsRelease% %ReleaseLinkerFlagsClang% %CommonLinkerFlagsClang% %EntryPoint% -o "%OutBin%"
    )
)


echo.
echo Compiling (command follows below)...
echo %BuildCommand%

%BuildCommand%

if %errorlevel% neq 0 goto error
if %errorlevel% == 0 goto success

:error
echo.
echo ***************************************
echo *      !!! An error occurred!!!       *
echo ***************************************
goto end


:success
echo.
echo ***************************************
echo *    Build completed successfully.    *
echo ***************************************
goto end


:end
echo.
echo Build script finished execution at %time%.
popd

endlocal

exit /b %errorlevel%
