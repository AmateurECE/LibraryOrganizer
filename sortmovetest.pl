#!/usr/bin/perl -w
#
# NAME: sortmovetest.pl -- A test for the sortmove.pl script.
#       this test evaluates for which files did the script fail,
#       and then prints them to a file.
# AUTHOR: Ethan D. Twardy
# CREATED: 04/13/17
# LAST EDITED: 04/13/17

# ======================== MAIN SCRIPT ========================
use strict;
use warnings;
use File::Find;
use Math::BigFloat ':constant';

$main::numargs = $#ARGV + 1;
die "sortmovetest.pl: Not Enough Arguments. Given $main::numargs, Expected 2.\n" if $main::numargs < 2;
($main::dir, $main::output) = @ARGV;
$main::count = 0;
$main::fail = 0;
find(\&count, $main::dir);
$main::outfh = fh_init($main::output);
$main::date = `date +%d/%m/%y`;
chomp $main::date;
print $main::outfh "Failure Results for sortmusic performace: $main::date\n\n";
find(\&test, $main::dir);
$main::rate = (($main::count - $main::fail) / $main::count) * 100;
print $main::outfh "\nSuccess rate: $main::rate";
close $main::outfh;
# =============================================================

# FUNCTION: count -- counts the files (not directories) in $main::dir.
# PARAMETERS: none.
# RETURN: none.
sub count {
    my $file = $File::Find::name;
    return $main::count++ if !-d $file && $file =~ m/(mp3|m4a)/;
}

# FUNCTION: fh_init -- initializes the filehandle for the output file.
# PARAMETERS: $dir: String -- A directory to place the output file into.
# RETURN: $fh: Filehandle -- the filehandle for the successfully created output file.
sub fh_init {
    my $dir = $_[0];
    my $fh;
    my $date = `date +%d%m%y`;
    chomp $date;
    my $filename = $dir . "/ErrorTest_" . $date . ".txt";
    if (-e $filename) {
	my $i = 2;
	until (!-e $filename) {
	    $filename = $dir . "/ErrorTest" . $i . "_" . $date . ".txt";
	    $i++;
	}
    }
    open $fh, ">$filename" || die "Cannot open $filename: $!\n";
    return $fh;
}

# FUNCTION: test -- tests the directory that was provided to sortmove.pl to
#           see for which values it fails.
# PARAMETERS: $file: String -- the filename to test.
# RETURN: none.
sub test {
    my $file = $File::Find::name;
    return if -d $file || $file !~ m/(mp3|m4a)/;
    my $name = $file;
    $name =~ s#.*/##;
    my $dist = file_distance($file);
    if ($dist < 3) {
	print $main::outfh "Failed; distance = $dist at: $name\n";
	$main::fail++;
    }
    return;
}

# FUNCTION: file_distance -- determines the distance between a file and main directory.
#           i.e. Music/00 Song Name.mp3 has a distance of 1.
# PARAMETERS: _: String -- file to be checked.
# RETURN: count: Integer -- the distance between 1 and 3 between the file and main directory.
sub file_distance {
    $_ = $_[0];
    my $count = 0;
    until ($_ eq $main::dir) {
	s/[^\/]*$//;
	chop $_;
	$count++ if -e;
    }
    return $count;
}
