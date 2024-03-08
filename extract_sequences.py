#!/usr/bin/env python3

import argparse
from Bio import SeqIO
import os  # Added for file size check


def parse_args():
    parser = argparse.ArgumentParser(
        description='Extract sequences from a FASTA file based on a list of IDs.',
        epilog='Example usage: ./extract_sequences.py --ids ids.txt --input input.fasta --output output.fasta'
    )
    parser.add_argument('--ids', required=True, help='File containing list of IDs, one per line.')
    parser.add_argument('--input', required=True, help='Input FASTA file.')
    parser.add_argument('--output', required=True, help='Output FASTA file for matched sequences.')

    return parser.parse_args()


def main():
    args = parse_args()

    # Check if input FASTA file exists and is not empty
    if not os.path.exists(args.input):
        print(f"Error: Input FASTA file '{args.input}' does not exist.")
        return

    if os.path.getsize(args.input) == 0:
        print(f"Error: Input FASTA file '{args.input}' is empty.")
        return

    # Read IDs into a set
    try:
        with open(args.ids, 'r') as id_handle:
            ids = set(line.strip() for line in id_handle.readlines())
    except FileNotFoundError:
        print(f"Error: ID list file '{args.ids}' not found.")
        return

    # Filter and write out matching sequences
    with open(args.output, 'w') as output_handle:
        for record in SeqIO.parse(args.input, 'fasta'):
            if record.id in ids:
                print(f"Found matching ID: {record.id}")  # Print matched ID for debugging
                SeqIO.write(record, output_handle, 'fasta')

if __name__ == '__main__':
    main()
