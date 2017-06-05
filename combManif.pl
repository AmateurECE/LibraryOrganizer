#!/usr/bin/perl -w
#
# NAME: combManif.pl - combine many smaller manifests into a larger manifest.
# AUTHOR: Ethan D. Twardy
# CREATED: 04/30/17
# LAST EDITED: 04/30/17


# =============== NOTE ===============
# As far as I'm concerned, you can't 
# pass a reference to a regular
# expression to a subroutine, but you
# can pass a reference to a function.
# use this information to combine the
# date-sorting algorithm down to a
# single, smaller subroutine.
# ====================================


# ========================================================================
# ============================= MAIN SCRIPT ==============================
# ========================================================================
use strict;
use warnings;
use Data::Dumper;

$main::numarg = $#ARGV + 1;
die "Not enough arguments to combManif.pl: Expected 2, received $main::numarg!\n" if $main::numarg != 2;
$main::path = $ARGV[0];
$main::check = $ARGV[1];
opendir $main::dh, $main::path || die "Cannot open directory $main::path: $!\n";
@main::files = grep {/BackupManif_\d+.\d+.\d+.txt/} readdir $main::dh;
closedir $main::dh;
my @lines;
my @dates;

# Populate @lines and @dates.
foreach my $i (@main::files) {
    retrievedata($i);
}

# Populate a hashmap with data in @lines.
%main::hash = %{fillhash(\@lines)};

# Sort @dates.
@main::sorted_dates = @{sortdates(\@dates)};

my $date = `date +%d.%m.%y`;
chomp $date;
my $outfh;
open($outfh, ">$main::path/BackupManifest(Master)_$date.txt") || die "Cannot open/create output file: $!\n";
print $outfh "Master Backup Manifest for dates $main::sorted_dates[0] - $main::sorted_dates[$#main::sorted_dates]\n\n";
print $outfh "=== MANIFESTS CONTAINED HEREIN ===\n";

foreach my $i (@main::sorted_dates) {
    print $outfh "$i\n";
}
print $outfh "\n";
foreach my $i (sort keys %main::hash) {
    my $s = join ", ", @{$main::hash{$i}};
    print $outfh "$i - $s\n";
}
close $outfh;
# ========================================================================
# ========================================================================

# FUNCTION: retrievedata -- opens the file which is passed to the function and
#           retrieves the date which it was created, and all manifest information
#           concerning files organized.
# PARAMETERS: $file: Scalar -- the filename to open
# RETURN: none
# SIDE EFFECTS: pushes all lines that match /-/ into @lines, and pushes $date into @dates.
sub retrievedata {
    my $file = $_[0];

    my $fh;
    open($fh, "<$main::path/$file") || die "Cannot open file $file: $!\n";
    my $date = getdate($fh);
    if ($date =~ m/\d+.\d+.\d+/) {
	push @dates, $date;
    }

    while (<$fh>) {
	if (m/-/) {
	    push(@lines, $_);
	}
    }

    close $fh;
}

# FUNCTION: getdate -- retrieves the date as the first operation after opening a
#           filehandle on a Backup Manifest file.
# PARAMETERS: $fh: Open Filehandle -- the filehandle corresponding to the file
# RETURN: date: Scalar -- the date of the manifest.
# SIDE EFFECTS: none.
sub getdate {
    my $fh = $_[0];
    my $line = <$fh>;
    if ($line =~ m/Backup Manifest for the Date of (.*)/) {
	my $date = $1;
	return $date;
    }
}

# FUNCTION: fillhash -- creates a hash and populates it with the information provided in @lines.
#           the format for this information is ($artist, @albums).
# PARAMETERS: lines: Array Reference -- the array of lines to populate data with.
# RETURN: Hash Reference -- the reference to the hashmap detailing the data in @lines.
# SIDE EFFECTS: none.
sub fillhash {
    my @lines = @{$_[0]};
    my %data;

    foreach (@lines) {
	m/([^-]*) - (.*)$/;
	my $artist = $1;
	my $album = $2;
	
	my @albums = split(", ", $album);
	my @remove;
	my $index = 0;
	foreach my $i (@albums) {
	    if (-f "$main::check/$artist/$i") {
		push @remove, $index;
	    }
	    $index++;
	}
	
	my $count = 0;
	foreach my $i (@remove) {
	    splice @albums, $i - $count, 1;
	    $count++;
	}
	
	# If there are no commas in either the artist or album names, or there
	# are no other issues...
	$index = 0;
	foreach my $i (@albums) {
	    $data{$artist}[$index] = $i;
	    $index++;
	}
    }
    return \%data;
}

# FUNCTION: sortdates -- recursive helper function to sort dates.
# PARAMETERS: dates: Array Reference -- reference to the array of dates to be sorted.
# RETURN: Array Reference -- reference to the array of sorted dates.
# SIDE EFFECTS: none.
sub sortdates {
    my $dates = $_[0];
    $dates = sortdateshelper($dates, \&getyear, 0);
    return $dates;
}


# Algorithm:
# start sorting by year: create an array of the scope of the parameter in question
# (years, months, days) covered, then sort. create a buffer array @sorted. foreach
# parameter in sorted scope: { if date has year, add to buffer. if case is 0, recurse
# with a reference to getmonth subroutine. If case is 1, recurse with pointer to
# get day subroutine. Add all dates in @sorted to @sorted_dates. }.
# return reference to array.
#
# FUNCTION: sortdateshelper -- recursive function to sort dates.
# PARAMETERS: dates: Array Reference -- the array of dates to be operated on.
#             func: Code Reference -- reference to subroutine to retrieve the parameter
#                   in question.
#             case: Scalar -- recursive parameter; suspends recursion when case is 2.
# RETURN: Array Reference -- reference to the array of sorted dates.
# SIDE EFFECTS: none.
sub sortdateshelper {
    my @dates = @{$_[0]};
    my $func = $_[1];
    my $case = $_[2];

    my @scope;
    foreach my $d (@dates) {
	my $n = &$func($d);
	if ($#scope == -1) {
	    push @scope, $n;
	}
	my $found = "0";
	foreach my $y (@scope) {
	    if ($y == $n) {
		$found = "1";
		last;
	    }
	}
	if ($found eq "0") {
	    push @scope, $n;
	}
    }

    # @scope now contains the scope of the dates.
    my @sorted_dates;
    foreach my $d (sort @scope) {
	my @sorted;
	my $index = 0;
	while ($index <= $#dates) {
	    $_ = $dates[$index];
	    my $n = &$func($_);
	    if ($n == $d) {
		push @sorted, $_;
	    }
	    $index++;
	}
	# @sorted now contains all dates pertaining to $d.
	if ($case == 0) {

	    @sorted = @{sortdateshelper(\@sorted, \&getmonth, ++$case)};

	} elsif ($case == 1) {

	    @sorted = @{sortdateshelper(\@sorted, \&getday, ++$case)};

	}
	foreach my $i (@sorted) {
	    push @sorted_dates, $i;
	}
	
    }
    
    return \@sorted_dates;
}

# FUNCTION: getyear -- gets the year from the date provided using regex.
# PARAMETERS: _: Scalar -- a date in the form of dd/mm/yy.
# RETURN: Scalar -- the year of the date.
# SIDE EFFECTS: none.
sub getyear {
    $_ = $_[0];
    m/\d+.\d+.(\d+)/;
    return $1;
}

# FUNCTION: getmonth -- gets the month from the date provided using regex.
# PARAMETERS: _: Scalar -- a date in the form of dd/mm/yy.
# RETURN: Scalar -- the month of the date.
# SIDE EFFECTS: none.
sub getmonth {
    $_ = $_[0];
    m/\d+.(\d+).\d+/;
    return $1;
}

# FUNCTION: getday -- gets the day from the date provided using regex.
# PARAMETERS: _: Scalar -- a date in the form of dd/mm/yy.
# RETURN: Scalar -- the day of the date.
# SIDE EFFECTS: none.
sub getday {
    $_ = $_[0];
    m/(\d+).\d+.\d+/;
    return $1;
}
