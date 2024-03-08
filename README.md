# Nextstrain Analysis Automation Wrapper Script
### Description
This repository features a wrapper script and utilities developed to automate as many steps as possible in analyzing RNA virus sequences using [Nextstrain](https://nextstrain.org/). Nextstrain is a bioinformatics platform for visualizing and analyzing pathogen transmission dynamics. It allows researchers to upload pathogen sequence data and metadata (e.g., collection date, location) and build interactive visualizations to understand how viruses spread geographically and evolve over time. The script aims to streamline the process and provide a user-friendly interface for executing a series of Nextstrain's [augur](https://docs.nextstrain.org/projects/augur/en/stable/#) commands, making it easier to use even for those with limited bioinformatics or Nextstrain experience. By offering an intuitive command-line interface and customizable options, the script facilitates getting started with Nextstrain's pathogen builds.


This script simplifies the Nextstrain analysis workflow by automating several steps, including:

- Indexing sequences
- Filtering sequences and metadata
- Aligning sequences
- Constructing phylogenies
- Inferring ancestral traits
- Exporting results for visualization in Nextstrain's Auspice visualization tool

### Prerequisites

- Python 3 is installed on your system.
- ```Nextstrain``` and its ```augur``` pipeline installed.
- Basic understanding of command-line operations.
