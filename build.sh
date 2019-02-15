#!/usr/bin/env bash

# This is the Linux build script for the NASM assembly tutorials.
# usage: ./build.sh [debug|release|clean] <project name>

StartTime=`date +%T`;
echo "Build script started executing at $StartTime...";

# Process command line arguments
BuildType=$1;
ProjectName=$2;

if [ "$BuildType" == "" ]; then
    BuildType=release;
fi;

if [ "$ProjectName" == "" ]; then
    ProjectName=hello_world;
fi;

echo "Building $ProjectName in $BuildType mode ...";

RED='\033[0;31m';
GREEN='\033[0;32m';
NC='\033[0m'; # No Color

# Create a build directory to store artifacts
BuildDir=$PWD/linuxbuild;

# If cleaning builds, just delete build artifacts and exit immediately
if [ "$BuildType" == "clean" ]; then
    echo "Cleaning build from directory: $BuildDir. Files will be deleted!";
    read -p "Continue? (Y/N)" ConfirmCleanBuild;
    if [ $ConfirmCleanBuild == [Yy] ]; then
       echo "Removing files in: $BuildDir...";
       rm -rf $BuildDir;
    fi;

    exit 0;
fi;


echo "Building in directory: $BuildDir";
if [ ! -d $BuildDir ]; then
   mkdir -p $BuildDir;
fi;

EntryPoint=$PWD/$ProjectName.asm;

IntermediateObj=$BuildDir/$ProjectName.o;
OutExe=$BuildDir/$ProjectName;


CommonCompilerFlags="-f elf64 -I$PWD -l $BuildDir/$ProjectName.lst";
DebugCompilerFlags="-g";

CommonLinkerFlags="-v -fuse-ld=lld -Wl,-e,main";
DebugLinkerFlags="-O2 -ggdb";
ReleaseLinkerFlags="-O3";

if [ "$BuildType" == "debug" ]; then
    CompileCommand="nasm $CommonCompilerFlags $DebugCompilerFlags -o $IntermediateObj $EntryPoint";
    LinkCommand="clang $CommonLinkerFlags $DebugLinkerFlags -o $OutExe $IntermediateObj";
else
    CompileCommand="nasm $CommonCompilerFlags -o $IntermediateObj $EntryPoint";
    LinkCommand="clang $CommonLinkerFlags $ReleaseLinkerFlags -o $OutExe $IntermediateObj";
fi;


echo "Compiling (command follows below)...";
echo "$CompileCommand";

$CompileCommand;
if [ $? -ne 0 ]; then
    echo -e "${RED}***************************************${NC}";
    echo -e "${RED}*      !!! An error occurred!!!       *${NC}";
    echo -e "${RED}***************************************${NC}";
    exit 1;
fi;


echo "Linking (command follows below)...";
echo "$LinkCommand";

$LinkCommand;
if [ $? -ne 0 ]; then
    echo -e "${RED}***************************************${NC}";
    echo -e "${RED}*      !!! An error occurred!!!       *${NC}";
    echo -e "${RED}***************************************${NC}";
    exit 2;
fi;


echo -e "${GREEN}***************************************${NC}";
echo -e "${GREEN}*    Build completed successfully!    *${NC}";
echo -e "${GREEN}***************************************${NC}";


EndTime=`date +%T`;
echo "Build script finished execution at $EndTime.";
