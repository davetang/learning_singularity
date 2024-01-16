#!/usr/bin/env Rscript

args <- commandArgs(trailingOnly=TRUE)
stopifnot(length(args) > 0)

lib_dir <- args[1]

if (dir.exists(lib_dir)==FALSE){
   dir.create(lib_dir)
}

install.packages("beepr", lib=lib_dir)
