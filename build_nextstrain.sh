#!/bin/bash


# Script Name: Nextstrain Analysis Automation
# Description: This script automates RNA virus sequence analysis using Nextstrain, 
#             simplifying the process for researchers and public health personnel with limited bioinformatics capabilities.
# Author: Julien A. Nguinkal
# Contact: balogog87@gmail.com
# Date: 2024-02-26
# Version: 1.0


# Help message displayed when the script is run without arguments
usage() {
  echo "Usage: $0 [options]"
  echo ""
  echo "This script automates the Nextstrain analysis of RNA virus sequences."
  echo ""
  echo "Options:"
  echo "  -h, --help        Display this help message."
  echo "  -r, --results DIR   Specify the directory to store results (default: results)."
  echo "  -c, --configs DIR   Specify the directory containing Nextstrain configs (default: /path/to/configs)."
  echo "  -t, --threads INT   Specify the number of threads to use (default: 14)."
  echo "  -s, --sequences FILE Path to the FASTA file containing sequences (FASTA format)."
  echo "  -f, --reference FILE Path to the reference sequence file (FASTA or GenBank format)."
  echo "  -m, --metadata FILE Path to the file containing sequences metadata (TSV format)."
  echo "  -l, --lat-longs FILE Path to the Latitudes and longitudes (default: \$CONFIGS/lat_longs.tsv)"
  echo "  -g, --longitude FILE (Optional) Path to the TSV file containing longitude data."
  echo "  -e, --colors FILE   Path to Colors file (default: \$CONFIGS/colors.csv)."
  echo "  -n, --maintainers NAMES Analysis maintained by (e.g., 'Name <URL> Name2 <URL>')."
  echo "  -b, --build-url URL   Build URL/repository to be displayed by auspice."
  echo ""
  echo "Example: $0 -r my_results -c /path/to/configs -t 8 -s my_sequences.fasta -f reference.fasta -m metadata.csv"
  exit 1
}

# Parse command-line arguments
while getopts ":hr:c:t:s:f:m:l:g:e:n:b:" opt; do
  case $opt in
    h|\?)
      usage
      ;;
    r)
      results="$OPTARG"
      ;;
    c)
      configs="$OPTARG"
      ;;
    t)
      threads="$OPTARG"
      ;;
    s)
      sequences="$OPTARG"
      ;;
    f)
      reference="$OPTARG"
      ;;
    m)
      metadata="$OPTARG"
      ;;
    l)
      lat_longs="$OPTARG"
      ;;
    g)
      longitude="$OPTARG"
      ;;
    e)
      colors="$OPTARG"
      ;;
    n)
      maintainers="$OPTARG"
      ;;
    b)
      build_url="$OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      usage
      ;;
  esac
done

# Remove any remaining positional arguments
shift $((OPTIND-1))

# Check for required arguments
if [[ -z "$sequences" || -z "$reference" || -z "$metadata" ]]; then
  echo "Error: Missing required arguments: -s, -f, and -m are mandatory."
  exit 1
fi

# Check if required directories exist (optional)
if [[ ! -d "$results" ]]; then
  mkdir -p "$results"
fi

if [[ ! -d "$configs" ]]; then
  echo "Warning: Config directory '$configs' does not exist."
fi


### Strains to include

INC_STRAINS="/home/nguinkal/NEXTSTRAIN/data/included_strains.txt"

echo -e "\n\033[1m\033[92m ======= $(date +"%Y-%m-%d %T"): STEP 1: INDEXING SEQUENCES... ======= \033[0m\n"

# Index sequence file
augur index \
  --sequences "$sequences" \
  --output "$results/sequence_index.tsv" \
  --verbose || { echo "Failed to index sequence file."; exit 1; }
  
  
echo -e "\n\033[1m\033[92m ======= $(date +"%Y-%m-%d %T"): STEP 2: Filtering metadata and sequences... ======= \033[0m\n"
  
    
  # Filter sequences
augur filter \
  --metadata "$metadata" \
  --sequences "$sequences" \
  --sequence-index "$results/sequence_index.tsv" \
  --group-by country year month \
  --output "$results/filtered.fasta" \
  --output-metadata "$results/meta.tsv" \
  --output-strains "$results/strains.tsv" \
  --output-log "$results/output.log" \
  --include "$INC_STRAINS" \
  --include-where region=Africa \
  --sequences-per-group 2 || { echo "Failed to filter sequences."; exit 1; }
 
echo -e "\n\033[1m\033[92m ======= $(date +"%Y-%m-%d %T"): STEP 3: Aligning virus sequences from FASTA.... ======= \033[0m\n"
  
  ## Align sequences
augur align --sequences "$sequences" \
            --output "$results/aligned.fasta" \
			--nthreads "$threads" \
			--reference-sequence "$reference" || { echo "Failed to align sequences."; exit 1; }
			
echo -e "\n\033[1m\033[92m ======= $(date +"%Y-%m-%d %T"): STEP 4: Constructing the phylogeny.... ======= \033[0m\n"

## Construct the phylogeny

augur tree \
  --alignment "$results/aligned.fasta" \
  --output "$results/tree_raw.nwk" \
  --nthreads "$threads"
 
 
 			
echo -e "\n\033[1m\033[92m ======= $(date +"%Y-%m-%d %T"): STEP 4: Constructing the time resolved tree.... ======= \033[0m\n"
			
## Get time resolved tree

augur refine --alignment "$results/aligned.fasta" \
             --tree "$results/tree_raw.nwk" \
			 --metadata "$results/meta.tsv" \
			 --output-tree "$results/tree.nwk" \
			 --output-node-data "$results/branch_lengths.json" \
			 --timetree --coalescent opt \
			 --date-inference joint \
			 --stochastic-resolve \
			 --clock-std-dev 0.0002 \
			 --clock-rate 0.0008 \
			 --date-confidence || { echo "Failed to build the time resolved tree."; exit 1; }
			 	# --clock-filter-iqd 4 \
		

echo -e "\n\033[1m\033[92m ======= $(date +"%Y-%m-%d %T"): STEP 5: Constructing ancestral traits.... ======= \033[0m\n"

## Reconstruct ancestral traits
augur traits --tree "$results/tree.nwk"  \
             --metadata "$results/meta.tsv" \
			 --column country region host year \
			 --confidence  \
			 --output-node-data "$results/traits.json"
			 
			 

echo -e "\n\033[1m\033[92m ======= $(date +"%Y-%m-%d %T"): STEP 6: Infering ancestral traits.... ======= \033[0m\n"			 

## Infer ancestral sequences

augur ancestral --tree "$results/tree.nwk" \
                --alignment "$results/aligned.fasta" \
				--output-node-data "$results/nt_muts.json" 
							 

echo -e "\n\033[1m\033[92m ======= $(date +"%Y-%m-%d %T"): STEP 6: Exporting results to be visualized by auspice.... ======= \033[0m\n"	


## Export results
augur export v2 --auspice-config "$configs/auspice_config.json" \
                --title "West Nile Viruses Global Phylodynamics" \
				--maintainers "$maintainers" \
				--build-url "$build_url" \
				--node-data "$results/branch_lengths.json" "$results/traits.json" "$results/nt_muts.json" \
				--colors "$colors" \
				--lat-longs "$lat_longs" \
				--tree "$results/tree.nwk" \
				--output auspice/westnile.json \
				--color-by-metadata country region host 

			 
## Finla step : view the results with auspice

nextstrain view auspice/
