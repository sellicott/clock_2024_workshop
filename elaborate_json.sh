#! /usr/bin/env bash
# Run Yosys to generate an elaborated netlist of a Verilog Module
# JSON output is copied to clipboard for pasting into netlistsvg
# Author: Sam Ellicott
# Date: October 30, 2024
# Useage: elaborate_json.bat <top level module> <input file>

# Check parameters and generate useage message
echo "Useage: <top level module> <input file>" 

# Run yosys and generate the json output file
yosys -p "prep -top $1; write_json output.json" ${@:2}

# copy JSON output to clipboard
xclip < output.json
echo "JSON copied to clipboard"
