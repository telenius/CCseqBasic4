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

# This is James Davies' script psl_parser.pl
# Modified to fit pipeline use by Jelena Telenius - sep 2015

# This script takes the output from Coord_Blast (which blats the Proximity exclusion coords to the genome).
# It takes the dpnII digested genome file in and the coordinate file in.
# It then outputs a file in the format: gene_name\t chr:start-stop of the off target mapping.

use strict;
use Data::Dumper;
use Getopt::Long;


my $version="VS103";
my $email='jelena.telenius@gmail.com';

my %inhash;
my %all_data;
my %counters;
my $nocolumns =0;
my @column_names;
my %column_names;

#####

# Input-files..

#my $REcoordsfile="/hts/data2/jdavies/07mm9_dpn/mm9_dpnII_coordinates.txt";
#my $oligofilename ="/hts/data6/telenius/developmentAndTesting/captureVS1_VS2comparison_030915/VS2_forLikeOrig_3rdtry/TEMP_Hba-1_oligocoordinate.txt";
#my $alloligofilename ="/hts/data2/jdavies/19CapC_analysis/Coordinate_files/30g_coordinates.txt";

my $REcoordsfile="UNDEFINED";
my $oligofilename ="UNDEFINED";
my $alloligofilename ="UNDEFINED";

# psl-inputfile
my $filename="UNDEFINED";

# The GetOptions from the command line
&GetOptions
(
	"f=s"=>\ $filename, 		# -f		Input filename 
	"r=s"=>\ $REcoordsfile,	# -r		Restriction coordinates filename 
	"o=s"=>\ $oligofilename,			# -o		Oligonucleotide position filename
	"a=s"=>\ $alloligofilename,			# -o		Oligonucleotide position filename
);

# Printing out the parameters in the beginning of run - Jelena added this 220515

print STDOUT "\n" ;
print STDOUT "James Davies' script psl_parser.pl - piped by Jelena Telenius, version $version !\n" ;

print STDOUT "Developer email $email\n" ;
print STDOUT "\n" ;

print STDOUT "Starting run with parameters :\n" ;
print STDOUT "\n" ;

print STDOUT "file_name $filename\n";
print STDOUT "oligo_filename $oligofilename\n";
print STDOUT "alloligo_filename $alloligofilename\n";
print STDOUT "restriction_enzyme_coords_file $REcoordsfile \n";

##############################

unless ($filename =~ /(.*)\.(.*)/) {die"filename does not match format"};
my $file_name=$1;
my $file_path="";

if ($file_name =~ /(.*\/)(\V++).psl/) {$file_path = $1; $file_name = $2};
my $outfilename= $file_name."_blat_filter.gfc";
my $logfilename= $file_name."_blat_filter_excluded.list";

print STDOUT "output file name $outfilename\n";
print STDOUT "run log file name $logfilename\n";

print STDOUT "\n";

open(PSLFH, $filename) or die "Cannot open file $filename $!\n";
open(FHOUT, ">$outfilename") or die "Cannot open file $outfilename $!\n";
open(LOGOUT, ">$logfilename") or die "Cannot open file $logfilename $!\n";


# Opens the file of dpnII fragment coordinates and puts them into the hash of arrays %dpn_data, which is of the format dpn_data{chr}[fragment_start1....]
# The dpnII coordinates are generated by the script dpngenome2.pl.  This file is in the format chr:start-stop
# NB. The start and stop sequences are in the middle of the restriction enzyme fragments (the binary search function will need to be altered if you change to a 6 cutter)

my %dpn_data;
open(DPNFH, "$REcoordsfile") or die "Cannot find restriction enzyme data file:$REcoordsfile $!";
print STDOUT "Reading RE coordinates file $REcoordsfile ..\n";

while (my $line = <DPNFH>)
{
  if ($line =~ /(.*):(\d++)-(\d++)/)
  {
    push @{$dpn_data{$1}}, $2;  #generates a hash of arrays in the format dpn_data{chr}[all dpn II frag start positions in ascending order]
    $counters{"01b Restriction enzyme fragments loaded:"}++
  }
  else {$counters{"01c lines from Restriction enzyme data failing to load:"}++;}
};

# Sorts the restriction enzyme coordinates in ascending numerical order 
my @chr_index = keys %dpn_data;
foreach my $chr(@chr_index) {@{$dpn_data{$chr}} = sort {$a <=> $b} @{$dpn_data{$chr}};}

# Uploads coordinates of capture oligos and exclusion regions into the array @oligo_data
# 0=name; 1=capture chr; 2 = capture start; 3 = capture end; 4= exclusion chr; 5 = exclusion start; 6 = exclusion end; 7 = snp position; 8 = SNP sequence
my %oligo_data;
open(OLIGOFH, $oligofilename) or die "Cannot open oligo file $oligofilename $!\n";
print STDOUT "Reading oligo file $oligofilename ..\n";
my @line_labels = qw(name cap_chr cap_start cap_end pe_chr pe_start pe_end snp_coord snp_base);

while ( <OLIGOFH> )
{
  chomp;
  my @line = split /\s++/;
  my $gene_name = $line[0];
  chomp $gene_name;
  
  $counters{"02 Oligo coordinates loaded:"}++;
  
  for (my$i=1; ($i <scalar (@line) and $i < scalar (@line_labels)); $i++)
    {
    $oligo_data{$gene_name}{$line_labels[$i]} = $line[$i];
    };
};

# Upload ALL COORDINATES in the experiment - as well !
my %alloligo_data;
open(ALLOLIGOFH, $alloligofilename) or die "Cannot open oligo file $alloligofilename $!\n";
print STDOUT "Reading coordinates for all capture oligos from file $alloligofilename .. \n";
print LOGOUT "Excluded PSL fragments closer than 1E6 bases from the capture site.\n\n";
print LOGOUT "1st column : cap site 1E6 nearby zone chr:start-stop, 2nd column : PSL file chr:start-stop\n\n";

while ( <ALLOLIGOFH> )
{
  chomp;
  my @line = split /\s++/;
  my $gene_name = $line[0];
  chomp $gene_name;
  
  $counters{"02b Oligo coordinates loaded from whole capture experiment file :"}++;
  
  for (my$i=1; ($i <scalar (@line) and $i < scalar (@line_labels)); $i++)
    {
    $alloligo_data{$gene_name}{$line_labels[$i]} = $line[$i];
    };
};



print STDOUT "Reading input PSL file $filename ..\n";

while (my $line = <PSLFH>)
{
    chomp $line;
    #print $line."\n";
    my @data = split(/\t/, $line);
    my $match = $data[0];
  if ($line =~ /(.*\t){15,}/)
  {
    if($data[9] =~ /hr(.*):(\d++)-(\d++)/)
    {
        my $search_chr = $1;
        my $search_start = $2;
        my $search_end = $3;
        
        my $chr = $data[13];
        if ($chr =~ /hr(.*)/){$chr = $1};
        
        my $start = $data[15];
        my $end = $data[16];
        my $block_sizes =$data[18];
        my $block_starts = $data[20];
        my $flag =0;

        
        #foreach my $gene_name(keys %alloligo_data) # Removes sequences that blat to inside one of the capture sites (e.g. HbA1 to HbA2)
        #{
        #    if (($chr eq $alloligo_data{$gene_name}{"cap_chr"}) and ($midpoint > $alloligo_data{$gene_name}{"cap_start"}) and  ($midpoint < $alloligo_data{$gene_name}{"cap_end"}))
        #    {$flag++;
        #     print STDOUT "Excluded PSL line overlapping $gene_name capture ..\n";
        #     $counters{"04 PSL lines discarded as they map into one of the capture sites:"}++;
        #     }
        #}
    
        if ($flag==0)
        {
            my $dpn_array_value_start = binary_search_single(\@{$dpn_data{$chr}}, $start, \%counters);
            my $dpn_array_value_end = binary_search_single(\@{$dpn_data{$chr}}, $end, \%counters);
            
            unless (($dpn_array_value_start eq "error") or ($dpn_array_value_end eq "error"))
            {
                for (my $i=$dpn_array_value_start; $i<=$dpn_array_value_end; $i++)
                {
                
                # Overwrite existing values..
                $start = $dpn_data{$chr}[$i];
                $end = $dpn_data{$chr}[$i+1]-1;
                
                
                # The excluding of line would be here.
                
                my $midpoint = $start + ($end-$start)/2;
                
                if (($chr eq $search_chr) and ($midpoint > $search_start-1000000) and  ($midpoint < $search_end+1000000))
                {$flag++;
                # print LOGOUT "Excluded PSL fragment closer than 1E6 bases from the capture site ($search_chr:$search_start-$search_end)\n";
                # print LOGOUT "- the excluded PSL line had coordinates : chr$chr:$start-$end\n";
                print LOGOUT "$search_chr:$search_start-$search_end)\tchr$chr:$start-$end\n";
                $counters{"03 PSL lines discarded as they closer than 1E6 bases to the capture site chr$search_chr:$search_start-$search_end :"}++;
                } 
                
                if ($flag==0)
                {
                $counters{"06 PSL regions parsed from PSL lines and printed to output:"}++;
                print FHOUT "chr".$chr.":".$start."-".$end."\n";
                }
                
                }
            }
        }
    }
  }
}

output_hash(\%counters, \*STDOUT);

#This ouputs a 2column hash to a file
sub output_hash
{
    my ($hashref, $filehandleout_ref) = @_;
    foreach my $value (sort keys %$hashref)
    {
    print $filehandleout_ref "$value\t".$$hashref{$value}."\n";
    }        
}




# This performs a binary search of a sorted array returning the position of the array on which the details of the fragment containing the input position can be found
sub binary_search_single
{
    my ($arrayref, $value, $counter_ref) = @_;
    
    my $array_position_min = 0;
    my $array_position_max = scalar @$arrayref-1; #needs to be -1 for the last element in the array
    my $counter =0;
    if (($value < $$arrayref[$array_position_min]) or ($value > $$arrayref[$array_position_max])){$$counter_ref{"00 Binary search error - search outside range of restriction enzyme coords:"}++; return "error"}
    
    for (my $i=0; $i<99; $i++)
    {
    my $mid_search = int(($array_position_min+$array_position_max)/2);
    
    if ($$arrayref[$mid_search]>$$arrayref[$mid_search+1]){$$counter_ref{"00 Binary search error - restriction enzyme array coordinates not in ascending order:"}++; return "error"}
    elsif (($$arrayref[$mid_search] <= $value) and  ($$arrayref[$mid_search+1] > $value)){return $mid_search;}
    elsif ($$arrayref[$mid_search] > $value){$array_position_max = $mid_search-1}    
    elsif ($$arrayref[$mid_search] < $value){$array_position_min = $mid_search+1}
    else {$$counter_ref{"00 Binary search error - end of loop reached:"}++}
    }
    $$counter_ref{"00 Binary search error - couldn't map read to fragments:"}++;
    return "error"
}