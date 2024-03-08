#!/bin/bash

# Check if the correct number of arguments are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <fasta_file> <mapping_file> <output_file>"
    exit 1
fi

# Assign command-line arguments to variables
fasta_file=$1
mapping_file=$2
output_file=$3

# Rename the FASTA file headers based on the IDs in the mapping file 
awk 'NR==FNR{a[$1]=$2;next} /^>/{gsub(/^>/, "", $1); if(a[$1]) print ">"a[$1]; else print ">UNKNOWN_"$1; next} 1' "$mapping_file" "$fasta_file" > "$output_file"

echo "Renaming completed. Output saved to $output_file"
