@echo off
REM     Build script for NASM assembly tutorials.
REM     Usage: build.bat [debug|release|clean] <project_name> [msvc|clang] [exe|dll] <additional_linker_arguments>
REM     e.g. build.bat debug hello_world                    will build hello_world.asm in debug mode
REM     e.g. build.bat release goodbye_nothing clang        will build goodbye_nothing.asm in release mode using clang
REM     e.g. build.bat release goodbye_nothing clang dll    will build goodbye_nothing.asm in release mode using clang as a dynamic link libray instead of an executable

echo Build script started executing at %time% ...

REM Process command line arguments. Default is to build in release configuration.
set BuildType=%1
if "%BuildType%"=="" (set BuildType=release)

set ProjectName=%2
if "%ProjectName%"=="" (set ProjectName=hello_world)

set Compiler=%3
if "%Compiler%"=="" (set Compiler=msvc)

set BuildExt=%4
if "%BuildExt%"=="" (set BuildExt=exe)

set AdditionalLinkerFlags=%5

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

set EntryPoint="%~dp0%ProjectName%.asm"

set IntermediateObj=%BuildDir%\%ProjectName%.obj
set OutBin=%BuildDir%\%ProjectName%.%BuildExt%

REM TODO: Figure out how to quote the path given to the include path here
set CommonCompilerFlags=-f win64 -I%~dp0 -l "%BuildDir%\%ProjectName%.lst"

if "%Compiler%"=="msvc" (
   set DebugCompilerFlags=-gcv8
) else (
   set DebugCompilerFlags=-g
)

REM For VS2015 onwards, need ``legacy_stdio_definitions.lib`` since printf is now inlined
REM Additionally, we link against both ``ucrt.lib`` and ``msvcrt.lib`` since some
REM of the C stdlib functions like ``malloc`` and ``rand`` are in the latter
REM ``Shell32.lib`` is for ``CommandLineToArgvW`` to parse cmdline args
if "%BuildExt%"=="exe" (
    set BinLinkerFlagsMSVC=/subsystem:console /entry:main
    set BinLinkerFlagsClang=-subsystem:console -entry:main
) else (
    set BinLinkerFlagsMSVC=/dll
    set BinLinkerFlagsClang=-dll

)
set CommonLinkerFlagsMSVC=%BinLinkerFlagsMSVC% /defaultlib:ucrt.lib /defaultlib:msvcrt.lib /defaultlib:legacy_stdio_definitions.lib /defaultlib:Kernel32.lib /defaultlib:Shell32.lib /nologo /incremental:no
set DebugLinkerFlagsMSVC=/opt:noref /debug /pdb:"%BuildDir%\%ProjectName%.pdb"
set ReleaseLinkerFlagsMSVC=/opt:ref


set CommonLinkerFlagsClang=-v -fuse-ld=lld-link -Wl,-machine:x64,-incremental:no,%BinLinkerFlagsClang%,%AdditionalLinkerFlags%
REM TODO: Adding ``-g`` causes linker error in lld-link. Something about the record needing to be aligned to 4 bytes.
set DebugLinkerFlagsClang=-O0
set ReleaseLinkerFlagsClang=-O3

if "%BuildType%"=="debug" (
    set CompileCommand=nasm %CommonCompilerFlags% %DebugCompilerFlags% -o "%IntermediateObj%" %EntryPoint%

    if "%Compiler%"=="msvc" (
        set LinkCommand=link "%IntermediateObj%" %CommonLinkerFlagsMSVC% %DebugLinkerFlagsMSVC% %AdditionalLinkerFlags% /out:"%OutBin%"
    ) else (
        set LinkCommand=clang %DebugLinkerFlagsClang% %CommonLinkerFlagsClang% -o "%OutBin%" "%IntermediateObj%"
    )
) else (
    set CompileCommand=nasm %CommonCompilerFlags% -o "%IntermediateObj%" %EntryPoint%

    if "%Compiler%"=="msvc" (
        set LinkCommand=link "%IntermediateObj%" %CommonLinkerFlagsMSVC%  %ReleaseLinkerFlagsMSVC% %AdditionalLinkerFlags% /out:"%OutBin%"
    ) else (
        set LinkCommand=clang %ReleaseLinkerFlagsClang% %CommonLinkerFlagsClang% -o "%OutBin%" "%IntermediateObj%"
    )
)

echo.
echo Compiling (command follows below)...
echo %CompileCommand%

%CompileCommand%

if %errorlevel% neq 0 goto error

echo.
echo Linking (command follows below)...
echo %LinkCommand%

%LinkCommand%

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
echo *    Build completed successfully!    *
echo ***************************************
goto end


:end
echo.
echo Build script finished execution at %time%.
popd
exit /b %errorlevel%
