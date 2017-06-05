#!/usr/bin/perl -w
################################################################################
# NAME: combManiftest.pl
# AUTHOR: Ethan D. Twardy
# DESCRIPTION: Tests to make sure that all of the data makes it into the master
#              file after combManif.pl is run.
# CREATED: 06/04/17
# LAST EDITED: 06/04/17
################################################################################

use strict;
use warnings;

my $dir;
my $glob_dir;
my @files;
my $fh;
my @lines;

$dir = "/Users/ethantwardy/Downloads/BackupManifests";
opendir $glob_dir, $dir || die "Could not open directory";
@files = readdir $glob_dir;
closedir $glob_dir;

foreach my $file (@files) {
    if (-d $file || $file !~ m/.txt/) { next; }
    
    my $line;
    my $tmp;

    open $tmp, "<$dir/$file" || die "Could not open file";
    $line = <$tmp>; # Read the first line of each file (Not used)
    $line = <$tmp>; # Read the second line of each file (Not used)

    while ($line = <$tmp>) {
	push @lines, $line;
    }
    close $tmp;
}

@lines = sort @lines; # Sort for convenience
open $fh, ">test.txt" || die "Could not open file";
foreach my $i (@lines) {
    print $fh "$i\n";
}
close $fh;
