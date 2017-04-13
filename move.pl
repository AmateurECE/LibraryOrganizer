#!/usr/bin/perl -w
#
# NAME: move.pl -- moves all of the top-level directories in $main::source
#       to $main::dest (Post-sorting). If the directory already exists,
#       merges them.
# AUTHOR: Ethan D. Twardy
# CREATED: 04/11/17
# LAST EDITED: 04/11/17

# ======================== MAIN SCRIPT ========================
use strict;
use warnings;
use File::Copy;

$main::numargs = $#ARGV + 1;
die "Move.pl: Not Enough Arguments: Given $main::numargs, Expected 2.\n" if ($main::numargs < 2);
$main::source = $ARGV[0];
$main::dest = $ARGV[1];

opendir $main::glob, $main::source;
@main::entries = readdir $main::glob;
closedir $main::glob;

foreach my $entry (@main::entries) {
    next if !-d $main::source . "/" . $entry || $entry eq "." || $entry eq ".." || $entry eq ".DS_Store";
    print "$entry\n";
    move_dir($entry, $main::source . "/", $main::dest . "/");
}

# =============================================================

# FUNCTION: move_dir -- RECURSIVELY moves the entity given in entry to dest.
#           if the directory already exists in dest, merges the two.
# PARAMETERS: entry: String -- the name of a directory or file.
#             source: String -- the name of the source directory.
#             dest: String -- the name of the destination directory.
# RETURN: none.
sub move_dir {
    my($entry, $source, $dest) = @_;
    
    
    return move $source . $entry, $dest . $entry if !-e $dest . $entry;
    return if !-d $source . $entry;

    my $glob;
    opendir $glob, $source . $entry;
    my @subglob = readdir $glob;
    closedir $glob;

    foreach my $subentry (@subglob) {
	next if $subentry eq "." || $subentry eq ".." || $subentry eq ".DS_Store";
	move_dir($subentry, $source . $entry . "/", $dest . $entry . "/");
    }
    return;
}
