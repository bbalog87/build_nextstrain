#!/usr/bin/env python3
import argparse
from Bio import Entrez, SeqIO

def download_sequences(accession_numbers, output_folder):
    # Set your email address for Entrez
    Entrez.email = "balogog87@gmail.com"
    
    for accession in accession_numbers:
        try:
            handle = Entrez.efetch(db="nucleotide", id=accession, rettype="fasta", retmode="text")
            record = SeqIO.read(handle, "fasta")
            filename = f"{output_folder}/{accession}.fasta"
            with open(filename, "w") as output_file:
                SeqIO.write(record, output_file, "fasta")
            print(f"Downloaded {accession} and saved to {filename}")
        except Exception as e:
            print(f"Error downloading {accession}: {e}")

def main():
    description = (
        "Download FASTA sequences from GenBank using accession numbers."
        " Requires a file with accession numbers and an output folder."
    )
    parser = argparse.ArgumentParser(description=description)
    
    parser.add_argument("--accession", "-acc", required=True, help="Path to the file containing accession numbers.")
    parser.add_argument("--output", "-out", required=True, help="Path to the output folder where FASTA files will be saved.")
    
    args = parser.parse_args()

    try:
        with open(args.accession) as accession_file:
            accession_numbers = [line.strip() for line in accession_file.readlines()]
    except FileNotFoundError:
        print(f"Error: Accession file '{args.accession}' not found.")
        return

    try:
        download_sequences(accession_numbers, args.output)
        print("All sequences downloaded successfully.")
    except Exception as e:
        print(f"An error occurred: {e}")

if __name__ == "__main__":
    main()
