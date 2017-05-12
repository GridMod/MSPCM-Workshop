#!/usr/bin/env r 

# Point to r libraries
# Commenting this out because using module R/3.2.2 works better
#.libPaths('/projects/PLEXOSMODEL/hpc-plexos/rlibrary')

# Load packages, install if necessary
library(rplexos)
library(methods)

soln <- list.files()
soln <- subset(soln,grepl("Solution",soln))

fil <- list.files(soln)
partition <- subset(fil,grepl("Solution.zip",fil))
print(sprintf("Processing solution %s",file.path(soln,partition)))
#process_solution(file.path(soln,partition))
process_folder(file.path(soln))
