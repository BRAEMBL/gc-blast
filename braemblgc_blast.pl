#!/usr/bin/env perl

=head1 NAME

braemblgc_blast.pl

=head1 DESCRIPTION

BRAEMBL Galaxy Connect: NCBI BLAST

<http://www.ebi.edu.au/tools/webservices/services/sss/ncbi_blast_rest>

=head1 VERSION

$Id: braemblgc_blast.pl Revision: 0.1.10 2014-08-18$

=cut

my $_VERSION = 'Revision: 0.1.10 2014-08-18';

use strict;
use warnings;
use English;
use LWP;
use XML::Simple;
use Getopt::Long qw(:config no_ignore_case bundling);
use File::Basename;

# Base URL for service
my $baseUrl = 'http://www.ebi.edu.au/tools/services/rest/ncbiblast';

# Set interval in seconds for checking status
my $checkInterval = 5;

# Output level
my $outputLevel = 1;

# Process command-line options {{{
# Can probably replace this whole section with hard coded parameter capturing?
my $numOpts = scalar(@ARGV);
my %params = ( 'multiIndex' => 1 );

# Default parameter values (should get these from the service)
my %tool_params = ();
GetOptions(
	# Tool specific options
	'program|p=s'    => \$tool_params{'program'},      # blastp, blastn, blastx, etc.
	'database|D=s'   => \$params{'database'},          # Database(s) to search
	'matrix|m=s'     => \$tool_params{'matrix'},       # Scoring martix to use
	'exp|E=f'        => \$tool_params{'exp'},          # E-value threshold
	'filter|f=s'     => \$tool_params{'filter'},       # Low complexity filter
	'align|A=i'      => \$tool_params{'align'},        # Pairwise alignment format
	'scores|s=i'     => \$tool_params{'scores'},       # Number of scores
	'alignments|n=i' => \$tool_params{'alignments'},   # Number of alignments
	'dropoff|d=i'    => \$tool_params{'dropoff'},      # Dropoff score
#	'match_scores=s' => \$tool_params{'match_scores'}, # Match/missmatch scores
	'match|u=i'      => \$params{'match'},             # Match score
	'mismatch|v=i'   => \$params{'mismatch'},          # Mismatch score
	'gapopen|o=i'    => \$tool_params{'gapopen'},      # Open gap penalty
	'gapext|x=i'     => \$tool_params{'gapext'},       # Gap extension penality
	'gapalign|g=s'   => \$tool_params{'gapalign'},     # Optimise gap alignments
	'stype=s'        => \$tool_params{'stype'},        # Sequence type
	'seqrange=s'     => \$tool_params{'seqrange'},     # Query subsequence
	'sequence=s'     => \$params{'sequence'},          # Query sequence
	'multifasta'     => \$params{'multifasta'},        # Multiple fasta input

	# Generic options
	'email=s'       => \$params{'email'},          # User e-mail address
	'outfile=s'     => \$params{'outfile'},        # Output file name
	'prefix=s'      => \$params{'prefix'},         # Output file name prefix
	'help|h'        => \$params{'help'},           # Usage help
	'baseUrl=s'     => \$baseUrl,                   # Base URL for service.
	'quiet|q'       => \$params{'quiet'}           # queit mode
);
if ( $params{'verbose'} ) { $outputLevel++ }
if ( $params{'quiet'} )  { $outputLevel-- }
#}}}

# LWP UserAgent for making HTTP calls (initialised when required).
my $ua;

# Print usage and exit if requested
if ( $params{'help'} || $numOpts == 0 ) { print "No input. Please run this within Galaxy\n"; exit(0); } 

# Multiple input sequence mode, assume fasta format.
if ( $params{'multifasta'} ) {
	multi_submit_job();
} else { # Default: single sequence/identifier.
	submit_job( load_data($ARGV[0]) );
}

=head1 FUNCTIONS

=cut

### Wrappers for REST resources ###{{{
=head2 rest_user_agent()

Get a LWP UserAgent to use to perform REST requests.

  my $ua = rest_user_agent();

=cut
sub rest_user_agent() { #{{{
	my $ua = LWP::UserAgent->new();
	$_VERSION =~ m/((?:\d+\.?)+)/; # insert the version of this script
	$ua->agent("BRAEMBL-GALAXY-CONNECT/$1 ($OSNAME) " . $ua->agent());
	$ua->env_proxy;
	return $ua;
} #}}}

=head2 rest_error()

Check a REST response for an error condition.

  rest_error($response, $content_data);

=cut
sub rest_error($$) { #{{{
	my ($response, $contentdata ) = @_;
	# Check for HTTP error codes
	if ( $response->is_error ) {
		my $error_message = '';
		# HTML response
		if( $contentdata =~ m/<h1>([^<]+)<\/h1>/ ) {
			$error_message = $1;
		}
		#  XML response
		elsif($contentdata =~ m/<description>([^<]+)<\/description>/) {
			$error_message = $1;
		}
		print STDERR 'http status: ' . $response->code . ' ' . $response->message . '  ' . $error_message and exit 6;
	}
} #}}}

=head2 rest_request()

Perform a REST request (HTTP GET).

  my $response_str = rest_request($url);

=cut
sub rest_request($) { #{{{
	my $requestUrl = shift;

	# Get an LWP UserAgent.
	$ua = rest_user_agent() unless defined($ua);
	# Checking for available HTTP compression methods.
	my $can_accept = HTTP::Message::decodable();
	
	# Perform the request with possible compression
	my $response = $ua->get($requestUrl,
		'Accept-Encoding' => $can_accept, # HTTP compression.
	);
	# Unpack possibly compressed response.
	my $retVal;
	if ( defined($can_accept) && $can_accept ne '') {
	    $retVal = $response->decoded_content();
	}
	# If unable to decode use orginal content.
	$retVal = $response->content() unless defined($retVal);
	# Check for an error.
	rest_error($response, $retVal);

	# Return the response data
	return $retVal;
} #}}}

=head2 rest_run()

Submit a job.

  my $job_id = rest_run($email, \%params );

=cut
sub rest_run { #{{{
	my $email  = shift;
	my $params = shift;

	# Get an LWP UserAgent.
	$ua = rest_user_agent() unless defined($ua);

	# Clean up parameters
	my (%tmp_params) = %{$params};
	$tmp_params{'email'} = $email;
	foreach my $param_name ( keys(%tmp_params) ) {
		if ( !defined( $tmp_params{$param_name} ) ) {
			delete $tmp_params{$param_name};
		}
	}

	# Submit the job as a POST
	my $url = $baseUrl . '/run';
	my $response = $ua->post( $url, \%tmp_params );

	# Check for an error.
	rest_error($response, $response->content());

	# The job id is returned
	my $job_id = $response->content();
	return $job_id;
} #}}}

=head2 rest_get_status()

Check the status of a job.

  my $status = rest_get_status($job_id);

=cut
sub rest_get_status { #{{{
	my $job_id = shift;
	my $status_str = 'UNKNOWN';
	my $url        = $baseUrl . '/status/' . $job_id;
	$status_str = rest_request($url);
	return $status_str;
} #}}}

=head2 rest_get_result_types()

Get list of result types for finished job.

  my (@result_types) = rest_get_result_types($job_id);

=cut
sub rest_get_result_types { #{{{
	my $job_id = shift;
	my (@resultTypes);
	my $url                      = $baseUrl . '/resulttypes/' . $job_id;
	my $result_type_list_xml_str = rest_request($url);
	my $result_type_list_xml     = XMLin($result_type_list_xml_str);
	(@resultTypes) = @{ $result_type_list_xml->{'type'} };
	return (@resultTypes);
} #}}}

=head2 rest_get_result()

Get result data of a specified type for a finished job.

  my $result = rest_get_result($job_id, $result_type);

=cut
sub rest_get_result { #{{{
	my $job_id = shift;
	my $type   = shift;
	my $url    = $baseUrl . '/result/' . $job_id . '/' . $type;
	my $result = rest_request($url);
	return $result;
} #}}}

#}}}
### Service actions and utility functions ###{{{
=head2 submit_job()

Submit a job to the service.

  submit_job($seq);

=cut
sub submit_job { #{{{
	# Set input sequence
	$tool_params{'sequence'} = shift;

	# Database(s) to search
	my (@dbList) = split /[ ,]/, $params{'database'};
	$tool_params{'database'} = \@dbList;

	# Match/missmatch
	if ( $params{'match'} && $params{'missmatch'} ) {
		$tool_params{'match_scores'} =
		  $params{'match'} . ',' . $params{'missmatch'};
	}

	# Submit the job
	my $jobid = rest_run( $params{'email'}, \%tool_params );

	print STDERR "JobId: $jobid\n" if ( $outputLevel > 0 );
	get_results($jobid);
} #}}}

=head2 multi_submit_job()

Submit multiple jobs assuming input is a collection of fasta formatted sequences.

  multi_submit_job();

=cut
sub multi_submit_job { #{{{
	my $jobIdForFilename = 1;
	$jobIdForFilename = 0 if ( defined( $params{'outfile'} ) );
	my (@filename_list) = ();

	# Query sequence
	if ( defined( $ARGV[0] ) ) { # Bare option
		if ( -f $ARGV[0] || $ARGV[0] eq '-' ) {    # File
			push( @filename_list, $ARGV[0] );
		}
		else { warn 'Warning: Input file "' . $ARGV[0] . '" does not exist' }
	}
	if ( $params{'sequence'} ) {                   # Via --sequence
		if ( -f $params{'sequence'} || $params{'sequence'} eq '-' ) {    # File
			push( @filename_list, $params{'sequence'} );
		}
		else { warn 'Warning: Input file "' . $params{'sequence'} . '" does not exist' }
	}

	$/ = '>';
	foreach my $filename (@filename_list) {
		my $INFILE;
		{ # File
		open( $INFILE, '<', $filename ) or (print STDERR 'Error: unable to open file ' . $filename . ' (' . $! . ')' && exit 1);
		}
		while (<$INFILE>) {
			my $seq = $_;
			$seq =~ s/>$//;
			if ( $seq =~ m/(\S+)/ ) {
				print STDERR "Submitting job for: $1\n"
				  if ( $outputLevel > 0 );
				$seq = '>' . $seq;
				submit_job($seq);
				$params{'outfile'} = undef if ( $jobIdForFilename == 1 );
				$params{'multiIndex'}++;
			}
		}
		close $INFILE;
	}
} #}}}

=head2 load_data()

Load sequence data from file or option specified on the command-line.

  load_data(\$ARGV[0]);

=cut
sub load_data { #{{{
	my $input = shift;
	my ($retSeq, $buffer);

	# Query sequence
	if ( -r $input ) {
		open( my $FILE, '<', $input );
		while ( sysread( $FILE, $buffer, 1024 ) ) { $retSeq .= $buffer; }
		close($FILE);
	#} else { die "Error: unable to open input file $input ($!)"; }
	} else { print STDERR "Error: unable to open input file $input ($!)" && exit 1; }
	return $retSeq;
} #}}}

=head2 get_results()

Get the results for a job identifier.

  get_results($job_id);

=cut
sub get_results { #{{{
	my $jobid = shift;

	# Verbose
	if ( $outputLevel > 1 ) { print 'Getting results for job ', $jobid, "\n"; }

	# Check status, and wait if not finished. Terminate if we get 3 errors
	my ($status, $errors) = ('RUNNING', 0);
	do {
		$status = rest_get_status($jobid);
		print STDERR "$status\n" if ( $outputLevel > 0 );

		if ($status eq 'ERROR') { $errors++; 
			print STDERR 'ERROR getting status from server. Please contact support@braembl.org.au'
				&& exit 3 if ($errors > 2);
		} elsif ( $status eq  'FAILURE'  ){
			print STDERR 'The job failed. Please contact support@braembl.org.au' && exit 4;
		} elsif ( $status eq 'NOT_FOUND' ){
			print STDERR 'Job not found. This should not happen! Please contact suppor@braembl.org.au' && exit 5;
		} elsif ($errors > 0) { $errors = 0; }

		if ($status ne 'FINISHED'){ sleep $checkInterval; } # Wait before polling again.
	} while ( $status ne 'FINISHED' );

	# Use prefix and JobId (and multifasta index if specified)
	if ( defined($params{'prefix'}) ){
		$params{'outfile'} = $params{'prefix'};
		$params{'outfile'} .= "-" . $params{'multiIndex'}; #if ($params{'multiIndex'});
		$params{'outfile'} .= "-" . $jobid;
	} elsif ( !defined($params{'outfile'}) ) { $params{'outfile'} = $jobid; }
	# Use JobId if output file name is not defined

	# Get list of data types
	my (@resultTypes) = rest_get_result_types($jobid);

	# Get the data and write it to a file for each output type
	for my $resultType (@resultTypes) {
		next if ( $resultType->{'fileSuffix'} =~ /^(svg|jpg)$/ );
		if ( $outputLevel > 1 ) {
			print STDERR 'Getting ', $resultType->{'identifier'}, "\n";
		}

		my $result = rest_get_result( $jobid, $resultType->{'identifier'} );

		my $filename = 
			$params{'outfile'} . '.' . $resultType->{'identifier'} . '.' . $resultType->{'fileSuffix'};
		if ( $outputLevel > 0 ) {
			print STDERR 'Creating result file: ' . $filename . "\n";
		}

		open( my $FILE, '>', $filename ) || (print "ERROR: unable to open output file $filename ($!)" and exit 2);
		syswrite( $FILE, $result );
		close($FILE);
	}
} #}}}
#}}}
#{{{ FEEDBACK/SUPPORT
=head1 FEEDBACK/SUPPORT

Please contact us at L<http://www.ebi.edu.au/support/> or L<support@braembl.org>
if you have any feedback, suggestions or issues with the service or this client.

=cut #}}}
#{{{ ERROR CODES
=head1 ERROR CODES

 +====+===============+======================================+
 |CODE|   ERROR NAME  | Explanation                          |
 +====+===============+======================================+
 |  1 |   INPUT error | Input file not accessible            |
 |  2 |  OUTPUT error | Output file not writable             |
 +====+===============+======================================+==================+
 |  3 |  STATUS error | Unable to retrieve the job status    : Please contact   ;
 |  4 | FAILURE error | Job failed                           : BRAEMBL support  ;
 |  5 |  NO JOB error | No such job. This should not happen  : with job details ;
 |  6 |  SERVER error | Error message included in output     : for these errors ; 
 +====+===============+======================================+==================+
 For errors 1 & 2, please check the permission of the input and output files as well as the job configuration.
 For errors 3 - 6, please contact support@braembl.org.au with the details of your job and error messages if available.

=cut #}}}
