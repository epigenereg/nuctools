#!/usr/bin/perl

=head1 NAME

calc_fragment_length.pl -  Calculates frequency of nucleosome-nucleosome distances to determine the nucleosome repeat length

=head1 SYNOPSIS
perl -w calc_fragment_length.pl --input=<in.bed> --output=<filtered.txt> 
 [--delta=<N> --apply_filter --filtering_threshold=<N> --pile=<N> --fix_pile_size ] 
 [--chromosome_col=<column Nr.> --start_col=<column Nr.> --end_col=<column Nr.> --strand_col=<column Nr.> --help]


 Required arguments:
    --input | -in      path to input BED or BED.GZ file
    --output | -out    output table file name
	
 Options:
 
  define column numbers in the input BED file (Nr. of the very first column is 0):
    --start_col | -sC            read start column Nr. (default: -s 1)
    --end_col | -eC              read end column Nr. (default: -e 2)
    --strand_col | -str          strand column Nr. (default: -str 3)
    --chromosome_col | -chrC     chromosome column Nr. (default: -chr 0)

   parameters with default values:
    --delta | -d                  maximum distance from start of the origin nucleosome to the last in calculations (default: 400)
    --filtering_threshold | -t    remove nucleosome piles above threshold (default: 20)
    --pile | -p                   define minimal pile size (default: 1)
    --pile_delta | -dP            maximum distance between adjacent nucleosome starts to consider as one pile (default: 0)
	--MaxNr | -m                  set maximum number adjacent reads to analyze (default: 1000000 )
   
   flags:
    --apply_filter | -f           apply --filtering_threshold to the data
    --fix_pile_size | -s          only consider nucleosomes in piles of the defined size (requires -p parameter)

	--help | h                 Help
	
 Example usage:
 
    perl -w calc_fragment_length.pl --input=in.bed.gz --output=filtered.txt.gz --delta=1000 	
	
	OR
	
    perl -w calc_fragment_length.pl -in in.bed.gz -out out.bed.gz -d 100 	
    
=head1 DESCRIPTION
 
=head2 NucTools 1.0 package.

 NucTools is a software package for analysis of chromatin feature occupancy profiles from high-throughput sequencing data

=head2 calc_fragment_length.pl

 calc_fragment_length.pl -  Estimates mean fragment length for a single-emd sequencing

=head1 AUTHORS

=over

=item 
 Yevhen Vainshtein <yevhen.vainshtein@igb.fraunhofer.de>
 
=item 
 Vladimir Teif
 
=back

=head2 Last modified

 18 October 2016
 
=head1 LICENSE

 Copyright (C) 2012-2016 Yevhen Vainshtein, Vladimir Teif

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

=cut

use strict 'vars';
use Getopt::Long;
use Pod::Usage;
#use List::MoreUtils qw/pairwise/;

# optional gzip support if modules are installed
my ($ModuleGzipIsLoaded, $ModuleGunzipIsLoaded);
BEGIN { $ModuleGunzipIsLoaded = eval "require IO::Uncompress::Gunzip; 1"; }
BEGIN { $ModuleGzipIsLoaded = eval "require IO::Compress::Gzip; IO::Compress::Gzip->import( qw[gzip] );1"; }

use strict "vars";
use Config;
use Time::localtime;
use Time::Local;
use List::Util qw(first);

# Default parametrs
my $delta = 400;
my $pile_delta = 0;
my $pile = 1;
my $in_file; 
my $out_path1; 
#  Time count Initialisation
my $timer1=time();
my $tm = localtime;
my $start_sec = $tm -> [0];
my $start_min = $tm ->[1];
my $start_hour = $tm ->[2];
my $start_time = time();

my $apply_filter_flag;
my $piles_filtering_threshold=20;
my $fix_pile_size;
my $MaxNr=1000000;
# default BED file columns
my $start_col=1;
my $end_col=2;
my $strand_col=3;
my $chromosome_col=0;

my $needsHelp;

#read arguments from command line
my $options_okay = &Getopt::Long::GetOptions(
	'input|in=s' => \$in_file,
	'output|out=s'   => \$out_path1,
	
	'delta|d=i' => \$delta,
	'pile|p=i'   => \$pile,
	'filtering_threshold|t=i'   => \$piles_filtering_threshold,
	'pile_delta|dP=i'   => \$pile_delta,
	
	'start_col|sC=i' => \$start_col,
	'end_col|eC=i'   => \$end_col,
	'strand_col|str=i' => \$strand_col,
	'chromosome_col|chr=i'   => \$chromosome_col,
	'MaxNr|m=i' => \$MaxNr,

	'fix_pile_size|s' => \$fix_pile_size,
	'apply_filter|f'   => \$apply_filter_flag,
	'help|h'      => \$needsHelp
);

# Check to make sure options are specified correctly and files exist
&check_opts();

# check if GZIP is loaded
if ((!$ModuleGzipIsLoaded) or (!$ModuleGunzipIsLoaded))  {
	print STDERR "Can't work with GZIP: IO::Compress::Gzip is not on PATH\n";
	exit;
}
elsif (($ModuleGzipIsLoaded) and ($ModuleGunzipIsLoaded) ) {
	print STDERR "ZGIP support enabled\n";
}
else {
	print STDERR "ZGIP support disabled\n";
}

# perl -w new_nuc-nuc_distance_filter.pl -input="chr9.bed" -output="nuc-nuc_ch9_filtered.txt" -delta=3000 -filtering_threshold=20 -apply_filter

# Display input parametrs
print STDERR "======================================\n";
print STDERR "Started:\t$start_hour:$start_min:$start_sec\n";
print STDERR "======================================\n";
print STDERR "in file:",$in_file, "\n";
print STDERR "out file:",$out_path1, "\n";
print STDERR "delta: ",$delta, "\n";
print STDERR "pile: $pile - ";
if ( defined $fix_pile_size) { print STDERR "select only nucleosomes in piles of fixed size\n"; }
else { print STDERR "use arbitrary pile size\n"; }
print STDERR "pile delta: ",$pile_delta, "\n";

print STDERR "filtering threshold: $piles_filtering_threshold - ";
if ( defined $apply_filter_flag) { print STDERR "filter the data: remove all piles above $piles_filtering_threshold\n"; }
else { print STDERR "do not apply upper filtering threshold\n"; }
print STDERR "limit number of reads to process to $MaxNr\n";

print STDERR "======================================\n";


my @occ_array=();

#read first file with occupanicies
#read file with by 4kb chanks

print STDERR " -reading $in_file file...\n";

@occ_array=();
my $BUFFER_SIZE = 1024*4;

# open occupancy file
my $inFH;
if ( $in_file =~ (/.*\.gz$/) ) {
	$inFH = IO::Uncompress::Gunzip->new( $in_file )
	or die "IO::Uncompress::Gunzip failed: $IO::Uncompress::Gunzip::GunzipError\n";
}
else { open( $inFH, "<", $in_file ) or die "error: $in_file cannot be opened:$!"; }

my $buffer = "";
my $sz_buffer = 0;
my $timer2 = time();
# counter for the markers we see
my $marker_count = 0;

my $regex_split_tab='\t';
my $regex_split_newline='\n';

my $filesize = -s $in_file; #determine file size in bytes
my $size_counter_step=int($filesize/100);
$filesize = int($filesize/1048576); # filesize in megabytes

print STDERR "- reading nucleosome start position column from $in_file ($filesize MBs).\nPlease wait...";

my $processed_memory_size = 0;
my $offset=0;
my $not_zero_counter=0;
my $string_counter=0;
my $chr_start;  #first read start
my $chr_end;    # last read end
my $cancel_load;
my (%hash);
while ((my $n = read($inFH, $buffer, $BUFFER_SIZE)) !=0) {
    if ($n >= $BUFFER_SIZE) {
    $buffer .= <$inFH>;
    }
    my @lines = split(/$regex_split_newline/o, $buffer);
    # process each line in zone file
    foreach my $line (@lines) {
		chomp($line);
        my @newline1=split(/\t/, $line);
        my $start_nuc=$newline1[$start_col];
        my $end_nuc=$newline1[$end_col];
		my $strand = $newline1[$strand_col] eq '+' ? 'plus' : 'minus' ;
		$hash{$string_counter}{$strand}{start}=$start_nuc;
		$hash{$string_counter}{$strand}{end}=$end_nuc;

        $string_counter++;
		if ($start_nuc>0) {$not_zero_counter++;}
		if ( $string_counter == $MaxNr ) {
			print STDERR "reach read number limit $MaxNr. Proceeding to the next steps...\n";
			$cancel_load="yes";
			last;
		}
    }
	$processed_memory_size += $n;
	$offset += $n;
	if(int($processed_memory_size/1048576)>= $filesize/10) {
		print STDERR "."; $processed_memory_size=0;
		}
	undef @lines;
	$buffer = "";
	if($cancel_load) {last;}
}

close($inFH) or die $!; 
print STDERR $filesize, " Mbs processed in ", time()-$timer2, " seconds.\n$not_zero_counter non zero counts\n\n";

# sort nucleosome positions according to a start_nuc
$timer2= time();
print STDERR "- sorting...";

# Flatten
my @flat_array = hash_crawler(\%hash);
my @sorted_array = sort { $a->[3] <=> $b->[3] or $a->[2] cmp $b->[2] } @flat_array;
print STDERR "done in ", time()-$timer2, " seconds.\n";

my (@sorted_plus_starts, @sorted_minus_starts, @sorted_plus_ends, @sorted_minus_ends);
for my $entry (@sorted_array) {
   #print join ", ", @$entry;
    #print "\n";
	if ( (@$entry[1] eq "plus" ) and ( @$entry[2] eq "start" ) ) {
		push (@sorted_plus_starts, @$entry[3]);
	}
	elsif ( (@$entry[1] eq "plus" ) and ( @$entry[2] eq "end" ) ) {
		push (@sorted_plus_ends, @$entry[3]);
	}
	elsif ( (@$entry[1] eq "minus" ) and ( @$entry[2] eq "start" ) ) {
		push (@sorted_minus_starts, @$entry[3]);
	}
	elsif ( (@$entry[1] eq "minus" ) and ( @$entry[2] eq "end" ) ) {
		push (@sorted_minus_ends, @$entry[3]);
	}
	
}

print STDERR join("\t", "plus starts: $#sorted_plus_starts",  "plus ends: $#sorted_plus_ends",
				  "minus starts: $#sorted_minus_starts",  "minus ends: $#sorted_minus_ends"),"\n";

for (my $i=0; $i<=10; $i++) {
	print STDERR join("\t", $sorted_plus_starts[$i],  $sorted_plus_ends[$i], 
				  $sorted_minus_starts[$i], $sorted_minus_ends[$i]),"\n";
}

print STDERR "done in ", time()-$timer2, " seconds.\n";
$timer2= time();

# remove nucleosomoes without repeat ($pile>1)
if ($pile>1) {
	print STDERR "remove nucleosomoes without repeat\n";
	my @temp = remove_unpiled($pile, $fix_pile_size, $pile_delta, @sorted_plus_starts);
	@sorted_plus_starts = @temp;
	@temp = remove_unpiled($pile, $fix_pile_size, $pile_delta, @sorted_minus_starts);
	@sorted_minus_starts = @temp;
	undef @temp;
}

if ($apply_filter_flag) {
	print STDERR "remove piles above $piles_filtering_threshold\n";
	my @temp = filter_by_threshold($piles_filtering_threshold, $pile_delta, @sorted_plus_starts);
	@sorted_plus_starts = @temp;
	@temp = filter_by_threshold($piles_filtering_threshold, $pile_delta, @sorted_minus_starts);
	@sorted_minus_starts = @temp;
	undef @temp;
}

if ($fix_pile_size ) {
	print STDERR "select only piles of size $pile\n";
	my @temp = local_pile_filter($pile, $pile_delta, @sorted_plus_starts);
	@sorted_plus_starts = @temp;
	@temp = local_pile_filter($pile, $pile_delta, @sorted_minus_starts);
	@sorted_minus_starts = @temp;
	undef @temp;
}

my @DiffStrandsEnrichment_plus_minus=distogram(\@sorted_plus_starts, \@sorted_minus_starts, $delta);
my @DiffStrandsEnrichment_minus_plus=distogram(\@sorted_minus_starts, \@sorted_plus_starts, $delta);
#my @DiffStrandsEnrichment = pairwise { $a + $b } @DiffStrandsEnrichment_plus_minus, @DiffStrandsEnrichment_minus_plus;
my @DiffStrandsEnrichment = sum_arrays_by_row (\@DiffStrandsEnrichment_plus_minus, \@DiffStrandsEnrichment_minus_plus);

my @SameStrandsEnrichment_plus=distogram(\@sorted_plus_starts, \@sorted_plus_starts, $delta);
my @SameStrandsEnrichment_minus=distogram(\@sorted_minus_starts, \@sorted_minus_starts, $delta);
#my @SameStrandsEnrichment = pairwise { $a + $b } @SameStrandsEnrichment_plus, @SameStrandsEnrichment_minus;
my @SameStrandsEnrichment = sum_arrays_by_row (\@SameStrandsEnrichment_plus, \@SameStrandsEnrichment_minus);


print STDERR "- saving resuts to $out_path1...";

# open pipe to Gzip or open text file for writing
open my $OUT_FHs, '>', $out_path1 or die "Can't open $out_path1 for writing; $!\n";
for (my $i=0; $i<=$#DiffStrandsEnrichment; $i++ ) {
	print $OUT_FHs $DiffStrandsEnrichment[$i],"\t", $SameStrandsEnrichment[$i], "\n";
}
close ($OUT_FHs);
print STDERR "done\n\n";
my $fragment_length_estimate = first { $DiffStrandsEnrichment[$_] == max(@DiffStrandsEnrichment) } 0..$#DiffStrandsEnrichment -
first { $SameStrandsEnrichment[$_] == max(@SameStrandsEnrichment) } 0..$#SameStrandsEnrichment;
print STDERR "Estimated fragment length is $fragment_length_estimate \n\n";


$tm = localtime;
my $stop_sec = $tm -> [0];
my $stop_min = $tm ->[1];
my $stop_hour = $tm ->[2];
my $message;

my $duration = time()-$start_time;
print STDERR "======================================\n";
$message = "\nFinished:\t$stop_hour:$stop_min:$stop_sec\nduration:\t$duration sec.\n\n";
print STDERR "$message\nBye!\n";

undef @DiffStrandsEnrichment_plus_minus;
undef @DiffStrandsEnrichment_minus_plus;
undef @DiffStrandsEnrichment;
undef @SameStrandsEnrichment_plus;
undef @SameStrandsEnrichment_minus;
undef @SameStrandsEnrichment;
exit;



#============================================================================
sub sum_arrays_by_row {
	my @arrays = @_;
	
	my $length = $#{ $arrays[0] };
	my @out;
	for my $i (0 .. $length) {
	  my $accumulator = 0;
	  for my $array (@arrays) {
	    $accumulator += $array->[$i];
	  }
	  push @out, $accumulator;
	}
	return(@out);
}
#--------------- clean line endings ----------------------------
sub clean {

my $text = shift;

$text =~ s/\r//g;
$text =~ s/\n//g;
return $text;
}

#-------------- determine maxsimum value from the array ---------
sub max {
  my $max = $_[0];
  for ( @_[ 1..$#_ ] ) { $max = $_ if $_ > $max; }
  return($max);
}

#-------------- determine maxsimum value from the array ---------
sub min {
  my $min = $_[0];
  for ( @_[ 1..$#_ ] ) { $min = $_ if $_ < $min; }
  return($min);
}

#===========================================================#
sub median {
	my $median;
	my @data = sort {$a <=> $b } @_;
	if (even_odd($#data+1) eq "ODD") {
	$median = $data[$#data/2];
	}
	else {
	$median = Average($data[$#data/2],$data[($#data/2)+1]);
	}
	return($median);
}
#===========================================================#
sub even_odd {
	if (int($_[0]/2) == $_[0]/2) { return "EVEN"; }
	else {return "ODD";}
}

#--------------------------------------------------------------------------
# Check for problem with the options or if user requests help
sub check_opts {
	if ($needsHelp) {
		pod2usage( -exitval => 1,
			  -verbose => 2 );
	}
	if ( !$options_okay ) {
		pod2usage(
			-exitval => 2,
			-verbose => 1,
			-message => "Error specifying options."
		);
	}
	if ( ! -e $in_file ) {
		if ( ! -e "$in_file.gz" ) {
			pod2usage(
				-exitval => 2,
				-verbose => 2,
				-message => "Cannot find input BED file $in_file or $in_file.gz: $!\n"
			);
		}
	}
	if (!$out_path1 ) {
		pod2usage(
			-exitval => 2,
			-verbose => 1,
			-message => "please specify output file name\n"
		);
	}

}

sub hash_crawler {
    my ($value, @prefix_array) = @_;
    my @results = ();
    if (ref $value) {
        for (keys %$value) {
            push @results, hash_crawler($value->{$_},@prefix_array,$_);
        }
    } else {
        push @results, [@prefix_array, $value];
    }
    return @results;
}

sub remove_unpiled {
	my ($pile, $fix_pile_size, $pile_delta, @sorted_coords) = @_;
	my @only_piled = ();
	my @temp;

	$timer2= time();
	if($fix_pile_size) {
	print STDERR "- select only pile=$pile...";
	}
	else {
	print STDERR "- removing un-piled nucleosomes...";
	}
	
	my $pile_counter=1;

	for (my $i=1; $i<=$#sorted_coords; $i++) {
		if (!@temp) { push(@temp,$sorted_coords[$i-1]); }
		if ( ($sorted_coords[$i] >= $sorted_coords[$i-1] ) && ($sorted_coords[$i] <= $sorted_coords[$i-1] + $pile_delta) ) {
			push(@temp,$sorted_coords[$i]);
			$pile_counter++;
		}
		elsif ($pile_counter < $pile) {
			undef @temp;
			$pile_counter=0;
		}
		elsif ( not ( ($sorted_coords[$i] >= $sorted_coords[$i-1] ) && ($sorted_coords[$i] <= $sorted_coords[$i-1] + $pile_delta)) && ($#temp>0) ) {
			if(($fix_pile_size) && ($#temp != $pile)) { undef @temp; }
			else {
				push @only_piled, @temp;
				undef @temp;
			}
			$pile_counter=0;
		}

	}
	my @results = grep /\S/, @only_piled;
	print STDERR "done in ", time()-$timer2, " seconds. ",$#results+1," strings left\n";
	return(@results);
	
}

sub filter_by_threshold {
	my ($piles_filtering_threshold, $pile_delta, @sorted_coords) = @_;
	print STDERR "- apply local pile filter: removing reads in the pile above $piles_filtering_threshold ...";
	my @piled_under_threshold;
	my $pile_counter=0;
	my @temp;
	
	for (my $i=1; $i<=$#sorted_coords; $i++) {
		if (!@temp) { push(@temp,$sorted_coords[$i-1]); }
		if ( ($sorted_coords[$i] >= $sorted_coords[$i-1] ) && ($sorted_coords[$i] <= $sorted_coords[$i-1] + $pile_delta) ) {
			push(@temp,$sorted_coords[$i]);
			$pile_counter++;
		} elsif ($pile_counter >= $piles_filtering_threshold) {
			push @piled_under_threshold, @temp[0..$piles_filtering_threshold];
			undef @temp;
			$pile_counter=0;
		} elsif ($#temp>0) {
			push @piled_under_threshold, @temp;
			undef @temp;
			$pile_counter=0;
		}
	
	}
	my @results = grep /\S/, @piled_under_threshold;
	print STDERR "done in ", time()-$timer2, " seconds. ",$#results+1," strings left\n";
	return(@results);
}

sub local_pile_filter {
	my ($piles_filtering_threshold, $pile_delta, @sorted_coords) = @_;
	my @only_piled = ();
	my @temp;

	print STDERR "- apply local pile filter: removing reads in the pile above $piles_filtering_threshold ...";
	my @piled_under_threshold;
	my $pile_counter=0;
	
	for (my $i=1; $i<=$#sorted_coords; $i++) {
		if (!@temp) { push(@temp,$sorted_coords[$i-1]); }
		if ( ($sorted_coords[$i] >= $sorted_coords[$i-1] ) && ($sorted_coords[$i] <= $sorted_coords[$i-1] + $pile_delta) ) {
			push(@temp,$sorted_coords[$i]);
			$pile_counter++;
		} elsif ($pile_counter >= $piles_filtering_threshold) {
			push @piled_under_threshold, @temp[0..$piles_filtering_threshold];
			undef @temp;
			$pile_counter=0;
		} elsif ($#temp>0) {
			push @piled_under_threshold, @temp;
			undef @temp;
			$pile_counter=0;
		}
	
	}
	my @results = grep /\S/, @piled_under_threshold;
	print STDERR "done in ", time()-$timer2, " seconds. ",$#results+1," strings left\n";
	return(@results);

}


sub distogram {
	my ($sorted_starts_ref, $sorted_ends_ref, $delta) = @_;
	
	my @output_array = (0) x ($delta+1); #initialize array of 0 of $delta+1 size
	my $first_itteration=0;
	my @sorted_starts = @{ $sorted_starts_ref };
	my @ends = @{ $sorted_ends_ref };

	my $counter_step=int($#sorted_starts/100);
	my $progress_counter=$counter_step;

	print STDERR "- calculating distances between adjacent nucleosomes (in the region from up to $delta bases away from the origin)...\n";
	
	#print STDERR join("\t", "SIndx", "EIndx", "summ", "nuc_start", "nuc_end", "delta", "total starts", "total ends"), "\n";

	for (my $i=0; $i<$#sorted_starts; $i++) {
		#read read start
		my $nuc_start=$sorted_starts[$i];
		# calcualte maximum index shift
		my $max_delta_index=5*$delta;
		# check if incremented index exceeds reads array length and correct it if necessary
		if ($i+$max_delta_index>=$#sorted_starts) { $max_delta_index = $#sorted_starts-$i; }
		my @sorted_ends=@ends[$i..($i+$max_delta_index)];

		for (my $n=0; $n<=$max_delta_index ; $n++) {
			if (!$sorted_starts[$i+$n]) { last; }
			# remove ends 
			for (my $j=0; $j<=$#sorted_ends; $j++) { 
				if ( $sorted_ends[0] > $nuc_start ) { last; }
				else { shift @sorted_ends; }
			}
			my $nuc_plus_end=$sorted_ends[$n];
			my $delta_nuc_starts = $nuc_plus_end-$nuc_start;
			if (($delta_nuc_starts>$delta) or ($delta_nuc_starts<0)) {
				#print STDERR join("\t", "- $i", $n, $i+$n, $nuc_start, $nuc_plus_end, $delta_nuc_starts, $#sorted_starts, $#sorted_ends), "\n";
				last;
			}
			else {
				$output_array[$delta_nuc_starts]++;
				#print STDERR join("\t", $i, $n, $i+$n, $nuc_start, $nuc_plus_end, $delta_nuc_starts, $#sorted_starts, $#sorted_ends), "\n";
			}
		}
		undef @sorted_ends;
		#increment counter to display work progress
		if ( $progress_counter == $i ) {
			print STDERR ".";
			$progress_counter+=$counter_step;
			last; # for testing
		}
	}
	my @results = grep /\S/, @output_array;
	print STDERR "done in ", time()-$timer2, " seconds. ",$#results+1," strings left\n";
	return(@results);
}
