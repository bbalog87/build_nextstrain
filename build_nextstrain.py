#!/usr/bin/env python3



"""
Script Name: Nextstrain Analysis Automation
Description: This script automates RNA virus sequence analysis using Nextstrain, 
             simplifying the process for researchers and public health personnel with limited bioinformatics capabilities.
Author: Julien A. Nguinkal
Contact: balogog87@gmail.com
Date: 2024-02-26
Version: 1.0

"""

import argparse
import subprocess
import os
import sys

def parse_args():
    parser = argparse.ArgumentParser(description="This script automates the Nextstrain analysis of RNA virus sequences.",
                                     formatter_class=argparse.RawTextHelpFormatter,
                                     epilog="Example usage:\n"
                                            "python3 script.py --results my_results --configs my_configs --threads 8 "
                                            "--sequences my_sequences.fasta --reference reference.fasta "
                                            "--metadata metadata.tsv --title \"My Analysis\"")
    parser.add_argument("-r", "--results", default="results", help="Specify the directory to store results (default: results).")
    parser.add_argument("-c", "--configs", default="configs", help="Specify the directory containing Nextstrain configs (default: configs).")
    parser.add_argument("-t", "--threads", type=int, default=8, help="Specify the number of threads to use (default: 8).")
    parser.add_argument("-s", "--sequences", required=True, help="Path to the FASTA file containing sequences.")
    parser.add_argument("-f", "--reference", required=True, help="Path to the reference sequence file (FASTA or GenBank format).")
    parser.add_argument("-m", "--metadata", required=True, help="Path to the file containing sequences metadata (TSV format).")
    parser.add_argument("-l", "--lat-longs", default="${configs}/lat_longs.tsv", help="Path to the Latitudes and longitudes file (default: ${configs}/lat_longs.tsv).")
    parser.add_argument("-e", "--colors", default="${configs}/colors.tsv", help="Path to the Colors file (default: ${configs}/colors.tsv).")
    parser.add_argument("-n", "--maintainers", help="Analysis maintained by (e.g., 'Name <URL>; Name2 <URL>').")
    parser.add_argument("-b", "--build-url", help="Build URL/repository to be displayed by auspice.")
    parser.add_argument("-w", "--include-where", help="Include samples with these values. ex: host=rat.")
    parser.add_argument("-i", "--include-strains", help="File(s) with list of strains to include regardless of priorities, subsampling, or absence of an entry in –sequences.")
    parser.add_argument("-T", "--title", default="Nextstrain Analysis", help="Custom title for the Nextstrain build (e.g., \"My Nextstrain Analysis\").")
    return parser.parse_args()

def run_command(command):
    try:
        subprocess.run(command, shell=True, check=True)
    except subprocess.CalledProcessError as e:
        print(f"Error executing command: {' '.join(e.cmd)}", file=sys.stderr)
        sys.exit(1)

def main():
    args = parse_args()
    
    # Ensure results directory exists
    os.makedirs(args.results, exist_ok=True)

    # Step 1: Index sequences
    print("\n ======= Indexing sequences... ======= \n")
    run_command(f"augur index --sequences {args.sequences} --output {args.results}/sequence_index.tsv")
    
    # Filter sequences
    print("\n ======= Filtering metadata and sequences... ======= \n")
    include_strains_option = f"--include {args.include_strains}" if args.include_strains else ""
    include_where_option = f"--include-where \"{args.include_where}\"" if args.include_where else ""
    run_command(f"augur filter --metadata {args.metadata} --sequences {args.sequences} "
                f"--sequence-index {args.results}/sequence_index.tsv --group-by country year month "
                f"--output {args.results}/filtered.fasta --output-metadata {args.results}/meta.tsv "
                f"--output-strains {args.results}/strains.tsv --output-log {args.results}/output.log "
                f"{include_strains_option} {include_where_option} "
                f"--sequences-per-group 2")
    
    # Align sequences
    print("\n ======= Aligning virus sequences from FASTA... ======= \n")
    run_command(f"augur align --sequences {args.sequences} --output {args.results}/aligned.fasta "
                f"--nthreads {args.threads} --reference-sequence {args.reference}")
    
    # Construct the phylogeny
    print("\n ======= Constructing the phylogeny... ======= \n")
    run_command(f"augur tree --alignment {args.results}/aligned.fasta --output {args.results}/tree_raw.nwk "
                f"--nthreads {args.threads}")
    
    # Construct the time resolved tree
    print("\n ======= Constructing the time resolved tree... ======= \n")
    run_command(f"augur refine --alignment {args.results}/aligned.fasta --tree {args.results}/tree_raw.nwk "
                f"--metadata {args.results}/meta.tsv --output-tree {args.results}/tree.nwk "
                f"--output-node-data {args.results}/branch_lengths.json --timetree --coalescent opt "
                f"--date-inference joint --stochastic-resolve --clock-std-dev 0.0002 --clock-rate 0.0008 "
                f"--date-confidence")
    
    # Construct ancestral traits
    print("\n ======= Constructing ancestral traits... ======= \n")
    run_command(f"augur traits --tree {args.results}/tree.nwk --metadata {args.results}/meta.tsv "
                f"--column country region host year --confidence --output-node-data {args.results}/traits.json")
    
    # Infer ancestral traits
    print("\n ======= Inferring ancestral traits... ======= \n")
    run_command(f"augur ancestral --tree {args.results}/tree.nwk --alignment {args.results}/aligned.fasta "
                f"--output-node-data {args.results}/nt_muts.json")
    
    # Export results for visualization by auspice
    print("\n ======= Exporting results to be visualized by auspice... ======= \n")
    run_command(f"augur export v2 --auspice-config {args.configs}/auspice_config.json "
                f"--title \"{args.title}\" --maintainers \"{args.maintainers}\" --build-url \"{args.build_url}\" "
                f"--node-data {args.results}/branch_lengths.json {args.results}/traits.json {args.results}/nt_muts.json "
                f"--colors {args.colors} --lat-longs \"{args.lat_longs}\" --tree {args.results}/tree.nwk "
                f"--output auspice/westnile.json --color-by-metadata country region host")
    
    # Viewing results with auspice
    print("\n ======= Viewing results with auspice... ======= \n")
    run_command("nextstrain view auspice/")

if __name__ == "__main__":
    main()
