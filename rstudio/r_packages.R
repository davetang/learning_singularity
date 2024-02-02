#!/usr/bin/env Rscript

ncpus <- 4L

cran_packages <- c(
   'igraph',
   'sctransform',
   'Seurat',
   'tidyverse',
   'tidymodels',
   'devtools',
   'rmarkdown',
   'cowplot'
)

bioc_packages <- c(
   'DropletUtils'
)

github_packages <- c(
   'bnprks/BPCells',
   'thomasp85/patchwork',
   'mojaveazure/seurat-disk',
   'Moonerss/scrubletR'
)

install.packages(cran_packages, Ncpus=ncpus)
BiocManager::install(bioc_packages)
remotes::install_github(github_packages)
