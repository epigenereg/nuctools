#!/usr/bin/perl

=head1 NAME

extend_PE_reads.pl - Takes as input bed file with mapped paired-end reads (two lines per paired read) and reformat it by creating a smaller bed file with one line per nucleosome in the following format:
(1) chromosome, (2) nucleosome start, (3) nucleosome end, (4) nucleosome length

=head1 SYNOPSIS

perl -w extend_PE_reads.pl -in <in.bed> -out <out.bed> [--help] 

 Required arguments:
    --input | -in      path to directory with aggregate profiles
    --output | -out    output table file name

 Options:
    --gzip | -z        compress the output
	--help | h                 Help
	
 Example usage:
 
    perl -w extend_PE_reads.pl --input=in.bed.gz --output=out.bed.gz	
	
	OR
	
    perl -w extend_PE_reads.pl -in in.bed.gz -out out.bed.gz
    
=head1 DESCRIPTION
 
=head2 NucTools 1.0 package.

 NucTools is a software package for analysis of chromatin feature occupancy profiles from high-throughput sequencing data

=head2 average_replicates.pl

 extend_PE_reads.pl Takes as input bed file with mapped paired-end reads (two lines per paired read) and reformat it by creating a smaller bed file with one line per nucleosome in the following format:
(1) chromosome, (2) nucleosome start, (3) nucleosome end, (4) nucleosome length

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

use strict;
use Getopt::Long;
use Pod::Usage;

# optional gzip support if modules are installed
my ($ModuleGzipIsLoaded, $ModuleGunzipIsLoaded);
BEGIN { $ModuleGunzipIsLoaded = eval "require IO::Uncompress::Gunzip; 1"; }
BEGIN { $ModuleGzipIsLoaded = eval "require IO::Compress::Gzip; IO::Compress::Gzip->import( qw[gzip] );1"; }

my $infile;
my $outfile;

my $needsHelp;
my $useGZ;

my $options_okay = &Getopt::Long::GetOptions(
	'input|in=s' => \$infile,
	'output|out=s'   => \$outfile,
	'gzip|z' => \$useGZ,
	
	'help|h'      => \$needsHelp
);

# Check to make sure options are specified correctly and files exist
&check_opts();

# check if GZIP is loaded
if ( ((!$ModuleGzipIsLoaded) or (!$ModuleGunzipIsLoaded)) and ($useGZ) ) {
	print STDERR "Can't work with GZIP: IO::Compress::Gzip is not on PATH\n";
	exit;
}
elsif ( (($ModuleGzipIsLoaded) and ($ModuleGunzipIsLoaded)) and ($useGZ) ) {
	print STDERR "ZGIP support enabled\n";
}
else {
	print STDERR "ZGIP support disabled\n";
}

# open pipe to Gzip or open text file for writing
my ($gz_out_file,$out_file,$OUT_FHs);
$out_file = $outfile;
  if ($useGZ) {
	  $out_file =~ s/(.*)\.gz$/$1/;
	  $gz_out_file = $out_file.".gz";
	  $OUT_FHs = new IO::Compress::Gzip ($gz_out_file) or open ">$out_file" or die "Can't open $out_file for writing: $!\n";
  }
  else {
	  open $OUT_FHs, '>', $outfile or die "Can't open $outfile for writing; $!\n";
  }


# open occupancy file
my $inFH;
if ( $infile =~ (/.*\.gz$/) ) {
	$inFH = IO::Uncompress::Gunzip->new( $infile )
	or die "IO::Uncompress::Gunzip failed: $IO::Uncompress::Gunzip::GunzipError\n";
}
else { open( $inFH, "<", $infile ) or die "error: $infile cannot be opened:$!"; }

my $buffer = "";
my $sz_buffer = 0;
my $timer2 = time();
# counter for the markers we see
my $marker_count = 0;

my $filesize_in_bytes = -s $infile; #determine file size in bytes
my $size_counter_step=int($filesize_in_bytes/100);
my $filesize = int($filesize_in_bytes/1048576); # filesize in megabytes

print STDERR "Reading $infile file of $filesize MBs. Please wait...\n";
my $processed_memory_size = 0;
my $offset=0;
my $not_zero_counter=0;
my $string_counter=0;
my $BUFFER_SIZE = 1024;
my $old_coordinate=1;
my $last_line;
while ((my $n = read($inFH, $buffer, $BUFFER_SIZE)) !=0) {
    if (($n >= $BUFFER_SIZE) or (($n == $filesize_in_bytes))) {
        $buffer .= <$inFH>;
    }
    my @lines = split(/\n/, $buffer);    
    my $end_index=$#lines;
    for (my $i=0; $i<=$end_index; $i++) {
      	my ($line1,$line2);
	if($last_line) {
	  unshift(@lines, $last_line);
	  $end_index=$#lines;
	  undef $last_line;
	}
	if(($i==$end_index) && ($end_index % 2 == 0) && ($lines[$#lines] =~ /^chr.*/ )) 
	    { $last_line= $lines[$#lines]; last; }
	$line1=$lines[$i]; chomp($line1);
	$line2=$lines[$i+1]; chomp($line2);
	
	my @newline1=split(/\t/, $line1);
	my @newline2=split(/\t/, $line2);
	
	my $chr_name=$newline1[0];
	my $start_nuc=$newline1[1];
	my $end_nuc=$newline2[2];
	my $nuc_length=$end_nuc-$start_nuc;
	
	print $OUT_FHs join("\t", $chr_name, $start_nuc, $end_nuc, $nuc_length), "\n";
	
	$i++;
    }
    if($#lines % 2)  {
      undef $last_line;
    }
    
    $processed_memory_size += $n;
    $offset += $n;
    if(int($processed_memory_size/1048576)>= $filesize/100) {
        print STDERR "."; $processed_memory_size=0;
        }
    undef @lines;
    $buffer = "";
}
close($inFH);
close($OUT_FHs);
print STDERR "job finished! Bye!\n";
exit;

#--------------------------------------------------------------------------
# Check for problem with the options or if user requests help
sub check_opts {
	if ($needsHelp) {
		pod2usage( -verbose => 2 );
	}
	if ( !$options_okay ) {
		pod2usage(
			-exitval => 2,
			-verbose => 1,
			-message => "Error specifying options."
		);
	}
	if ( ! -e $infile ) {
		pod2usage(
			-exitval => 2,
			-verbose => 1,
			-message => "Cannot find input BED file $infile: $!\n"
		);
	}
	if (!$outfile ) {
		pod2usage(
			-exitval => 2,
			-verbose => 1,
			-message => "please specify output BED file name\n"
		);
	}

}
