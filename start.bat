:: Environment setup file for Tiny Tapeout on Windows
:: Author: Sam Ellicott
:: Date: October 30, 2024

:: Path to location where PortableGit and oss-cad-suite are located
:: Defaults to the directory above the location of the git repo
@set TOOLS_PATH=%~dp0..

:: Location of PortableGit for Windows
@set GIT_PATH=%TOOLS_PATH%\PortableGit\cmd

:: Reset the command prompt path to the defaults for Windows 10
:: with the addition of PortableGit.
:: This is mostly so that I have a clean environment to test 
:: in without contamination from other tools I have installed 
@set PATH=%GIT_PATH%;%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%SYSTEMROOT%\System32\WindowsPowerShell\v1.0\;%SystemRoot%\System32\OpenSSH

:: Launch a new command prompt window with the oss-cad-suite environment
@cmd /k "%TOOLS_PATH%\oss-cad-suite\environment.bat"