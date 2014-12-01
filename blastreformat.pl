#!/usr/bin/env perl

use strict;
use warnings;
use Bio::SearchIO; 
use Bio::Search::HSP::GenericHSP;
use Getopt::Long qw(:config no_ignore_case);

my $_VERSION = 'Revision: 0.1.03 2014-07-30';

my $header;
GetOptions( 'header|H' => \$header );

# Print header
print "query id\tsubject id\tpercent id\tlength\tmismatches\tgap\tquery start\tquery end\tsubject start\tsubject end\tE-value\tbit score\n" if ($header);

my $in = new Bio::SearchIO(-format => "blast", -file => "$ARGV[0]");
while( my $result = $in->next_result ) {
  while( my $hit = $result->next_hit ) {
    while( my $hsp = $hit->next_hsp ) {
#query id, database sequence (subject) id, percent identity, alignment length, number of mismatches, number of gap openings, query start, query end, subject start, subject end, Expect value, HSP bit score.
	printf "%s\t%s\t%.2f\t%d\t%d\t%d\t%d\t%d\t%d\t%d\t%s\t%0.1f\n",
		$result->query_name, $hit->name, $hsp->percent_identity, $hsp->length('total'),
		$hsp->length('total') - $hsp->gaps('total') - scalar($hsp->seq_inds('query','id')),
		scalar($hsp->seq_inds('query','gap', 1)) + scalar($hsp->seq_inds('hit','gap', 1)),
		$hsp->start('query'), $hsp->end('query'), $hsp->start('hit'), $hsp->end('hit'),
		$hsp->evalue, $hit->bits;
    }  
  }
}
