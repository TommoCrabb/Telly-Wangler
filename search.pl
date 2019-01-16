#!/usr/bin/env perl
use strict;
use warnings;
use v5.10;
use Term::ANSIColor qw(:constants);
use FindBin qw($RealBin);
$Term::ANSIColor::AUTORESET = 1;

### GLOBAL VARIABLES ###
my @index_files = <$RealBin/index/*.index> ;               ## A list containing index files to be searched.
my @vids = build_vid_list(@index_files) ;  ## A list containing all lines from all files in @index_files.
my $header = "" ;                          ## Text used for creating line-breaks. Needs to survive between function calls.

### BODY ###

msg("HELLO"); # Start-up message. Useful for testing if restart is working.

while (1) {
	my $input = get_input() ;
	for ( $input ) { # Parse user input
		if (/^-h$/) { # [-h] Print help
			print_manual() ;
		}
		elsif (/^-q$/) { # [-q] Quit
			msg("GOODBYE") ;
			exit ;
		}
		elsif (/^-r$/) { # [-r] Restart
			exec( "$0" ) ;
		}
		elsif (/^(| |[\.\+\*\?\^\$]*)$/) { # Searching for empty string, a single space, or nothing but meta characters is dumb
			msg("DOESN'T THAT SEEM LIKE A STUPID THING TO SEARCH FOR?") ;
		} 
		else { # Treat anything else as a regex and do search
			$header = $input ; 
			print_break(1) ;
			for (@vids) {
				if (/($input)/i) { # Doing this in multiple steps allows for coloured formatting.
					my $match = $1 ;
					$match =~ s/([\.\+\?\(\)\[\]\*\^\$\|\\])/\\$1/g ; # Sanitise special characters
					if (/^(.*\/)?(.*)($match)(.*)$/) {
						$1 and print BLUE $1 ;
						$2 and print RESET $2 ;
						$3 and print YELLOW $3 ;
						$4 and print RESET $4 ;
						print "\n" ;
					}
					else {
						msg("SOMETHING WENT WRONG WHILE SANITISING REGEX: $input => $match");
						last;
					}
				}
			}
			print_break(2) ;
		}
	}
}

### FUNCTIONS ###

sub print_manual ## Run this script through 0-print-comments.
{
	$header = "HELP";
	print_break(1) ;
	system( "0-print-comments", "$0" ) ;
	print_break(2) ;
}

sub msg ## Print some text using a predefined format.
{
	say BOLD MAGENTA @_ ;
}

sub print_break ## Takes a single numerical argument and uses the text stored in the variable $header to print a pretty line-break.
## (1) header: ===> header <===
## (2) footer: ================
{
	if ($_[0] == 1) {
		$header = "===> $header <===" ;
		say BOLD GREEN $header ;
	}
	elsif ($_[0] == 2) {
		say BOLD GREEN "=" x length $header ;
	}
}
	
sub get_input ## Asks the user for input, checks the input is a valid regexp, returns it if it is.
{
	$@ = 1 ;
	my $input ;

	while ($@) {

		# Get input from user.
		say BOLD YELLOW "-h", BOLD BLUE "(help) ", 
			BOLD YELLOW "-q", BOLD BLUE "(quit) ", 
			BOLD YELLOW "-r", BOLD BLUE "(restart) ",
			BOLD YELLOW "OR", BOLD BLUE " type a perl compliant regular expression to search:",
			;
		$input = <STDIN> ;
		chomp $input ;

		# Check that user input is a valid regex. Otherwise Perl will crash.
		eval { qr/$input/ } ;
		$@ and msg($@, "INVALID INPUT. PLEASE TRY AGAIN.") ;
	}
	return $input ;
}

sub build_vid_list ## Takes a list of filenames, reads all lines in all files into a single list, returns the list. 
{
	my @vids ;
	for my $index_file (@_) {
		open( my $fh, "<", $index_file ) or die "Couldn't open $index_file: $!" ;
		push @vids, <$fh> ;
		close $fh or die "Couldn't close $index_file: $!" ;
	}
	chomp @vids ;
	return @vids ;
}
