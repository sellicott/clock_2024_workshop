:: Run Yosys to generate an elaborated netlist of a Verilog Module
:: JSON output is copied to clipboard for pasting into netlistsvg
:: Author: Sam Ellicott
:: Date: October 30, 2024
:: Useage: elaborate_json.bat <top level module> <input file>

:: Check parameters and generate useage message
@echo off
IF "%~1"=="" GOTO useage 
IF "%~2"=="" GOTO useage
GOTO run
:useage
@echo "Useage: <top level module> <input file>" 
GOTO end

:: 
:run
set top_module=%~1

:: put all other inputs into a single variable
shift
set file_list="%~1"
:loop
shift
if "%~1"=="" goto afterloop
set file_list=%file_list% "%~1"
goto loop
:afterloop

@echo %top_module%
@echo %file_list%

:: Run yosys and generate the json output file
yosys -p "prep -top "%top_module%"; write_json output.json" %file_list% 

:: copy JSON output to clipboard
type output.json | clip
@echo "JSON copied to clipboard"
:end