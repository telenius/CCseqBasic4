#!/bin/bash

##########################################################################
# Copyright 2017, Jelena Telenius (jelena.telenius@imm.ox.ac.uk)         #
#                                                                        #
# This file is part of CCseqBasic4 .                                     #
#                                                                        #
# CCseqBasic4 is free software: you can redistribute it and/or modify    #
# it under the terms of the GNU General Public License as published by   #
# the Free Software Foundation, either version 3 of the License, or      #
# (at your option) any later version.                                    #
#                                                                        #
# CCseqBasic4 is distributed in the hope that it will be useful,         #
# but WITHOUT ANY WARRANTY; without even the implied warranty of         #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          #
# GNU General Public License for more details.                           #
#                                                                        #
# You should have received a copy of the GNU General Public License      #
# along with CCseqBasic4.  If not, see <http://www.gnu.org/licenses/>.   #
##########################################################################


setPathsForPipe(){

# #############################################################################

# This is the CONFIGURATION FILE to load in the needed toolkits ( conf/loadNeededTools.sh )

# #############################################################################

# Setting the needed programs to path.

# This can be done EITHER via module system, or via EXPORTING them to the path.
# If exporting to the path - the script does not check already existing conflicting programs (which may contain executable with same names as these)

# Change this to "0" if you want to use direct paths.
useModuleSystem=1
# useModuleSystem=1 : load via module system
# useModuleSystem=0 : load via direct paths


# PATHS_LOADED_VIA_MODULES

if [ "${useModuleSystem}" -eq 1 ]; then

module purge
# Removing all already-loaded modules to start from clean table

module load samtools/1.1
# Supports all samtools versions in 1.* series. Does not support samtools/0.* .

module load bowtie/1.1.2
# Supports all bowtie1 versions 1.* and 0.*
module load bowtie2/2.1.0
# Supports all bowtie2 versions

module load bedtools/2.17.0
# Supports bedtools versions 2.1* . Does not support bedtools versions 2.2*

module load ucsctools/1.0
# Supports ucsctools versions 1.* . Not known if supports also ucsctools versions 2.* (most probably not)

module load flash/1.2.8
# Not known if would support other flash versions. Most probably will support.

module load fastqc/0.10.1
# Will not support fastqc versions 0.11.* or newer.
# CCseqBasic3 includes a legacy version of fastqc ( fastqc_v0.10.1.zip ), which you can install if you don't have "old enough" fastqc.

module load trim_galore/0.3.1
# Not known if would support other trim_galore versions. Most probably will support.

# module load cutadapt/1.2.1
# If your trim_galore module does not automatically load the needed cutadapt,
# uncomment this line

# Not known if would support other cutadapt versions. Most probably will support.

module load blat/35
# Not known if would support other blat versions. Most probably will support.

module load perl/5.18.1
# Most probably will run with any perl

module load python/2.7.5
# Most probably will run with any Python

module list


# EXPORT_PATHS_WITHOUT_MODULE_SYSTEM

else
    
# Note !!!!!
# - the script does not check already existing conflicting programs within $PATH (which may contain executable with same names as these)

export PATH=$PATH:/package/samtools/1.1/bin/samtools
export PATH=$PATH:/package/bowtie/1.1.2/bin/bowtie

export PATH=$PATH:/package/bedtools/2.17.0/bin/bedtools
export PATH=$PATH:/package/ucsctools/1.0/bin
export PATH=$PATH:/package/flash/1.2.8/bin/flash
export PATH=$PATH:/package/fastqc/0.10.1/bin/fastqc
export PATH=$PATH:/package/trim_galore/0.3.1/bin/trim_galore
export PATH=$PATH:/package/cutadapt/1.2.1/bin/cutadapt
export PATH=$PATH:/package/perl/5.18.1/bin/perl

export PATH=$PATH:/package/blat/35/bin/blat
export PATH=$PATH:/package/python/2.7.5/bin/python

# See notes of SUPPORTED VERSIONS above !

echo $PATH

fi

}
