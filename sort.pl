#!/usr/bin/perl -w
#
# NAME: sort.pl -- Sorts all of the music in $main::home_path to the iTunes standard:
#            Artists in the main directory, albums in subdirectories, and songs
#            in sub-subdirectories. The formatting for song naming is:
#            00 Song Name.mp3
# AUTHOR: Ethan D. Twardy
# CREATED: A loooooong time ago.
# LAST EDITED: 04/17

# ========================= MAIN SCRIPT =========================
use strict;
use warnings;
use File::Find;
use File::Basename;
use File::Copy;
use Cwd;
die "Perl: Not Enough Arguments: Given $#ARGV, Expected 2" if ($#ARGV + 1 <  2);
$main::outputfile = $ARGV[1];
$main::home_path = $ARGV[0];
$main::home_name = $main::home_path;
$main::home_name =~ s#.*/##;
$main::songname = "";


print "Renaming and organizing songs...\n";
find(\&first, $main::home_path);
print "Renaming albums...\n";
find(\&album_rename, $main::home_path);
print "Renaming artists...\n";
find(\&artist_rename, $main::home_path);
print "Drafting Manifest...\n";
draft($main::home_path);
print "...Done.\n";
# ================================================================

# ================================================================
# ======================== MAIN FUNCTIONS ========================
# ================================================================

# FUNCTION: first -- callback from first call to File::Find::find(). Renames each file
#           and places it into the correct position on the directory tree.
# ARGUMENTS: none.
# RETURN: none.
sub first {
    if (!-d && ($_ ne ".DS_Store") && m/(mp3|m4a)$/) {
	print "$_ \n";
 	return if (file_check($File::Find::name) eq "");
	my $filename = file_rename($File::Find::name);
	file_prepare($filename);
	return;
    }
}

# FUNCTION: artist_rename -- traverses the directory tree and renames all top-level
#           directories (artists).
# PARAMETERS: none.
# RETURN: none.
sub artist_rename {
    my $file = $File::Find::name;
    if (!-d && -e && ($_ ne ".DS_Store") && m/(mp3|m4a)$/) {
	return if (file_check($file) eq "");
	my $artist = get_artist($file);

	my $old_artist = $file;
	$old_artist =~ s/[^\/]*$//; # Music/Gojira/Magma/
	chop($old_artist); # Music/Gojira/Magma
	$old_artist =~ s/[^\/]*$//; # Music/Gojira/
	chop($old_artist); # Music/Gojira
	
	my $new_artist = $old_artist;
	$new_artist =~ s/[^\/]*$//; # Music/
	$new_artist = $new_artist . $artist; # Music/Gojira

	my @old = split("/", $old_artist);
	my @new = split("/", $new_artist);
	if ($old_artist ne $new_artist && $#old == $#new) {
	    print "$artist\n";
	    move $old_artist, $new_artist;
	}
    }
    return;
}

# FUNCTION: album_rename -- traverses the directory tree and renames all low-level
#           directories (albums).
# PARAMETERS: none.
# RETURN: none.
sub album_rename {
    my $file = $File::Find::name;
    if (!-d && -e && ($_ ne ".DS_Store") && m/(mp3|m4a)$/) {
	return if (file_check($file) eq "");
	my $album = get_album($file);
	
	my $old_album = $file; # Music/Gojira/Magma/Stranded.mp3
	$old_album =~ s/[^\/]*$//; # Music/Gojira/Magma/
	chop($old_album); # Music/Gojira/Magma

	my $new_album = $old_album;
	$new_album =~ s/[^\/]*$//; # Music/Gojira/
	$new_album = $new_album . $album;
	
	my @old = split("/", $old_album); # Create an array just to make sure the paths are the same length
	my @new = split("/", $new_album); # "
	if ($old_album ne $new_album && $#old == $#new) {
	    print "$album\n";
	    move $old_album, $new_album;
	}
    }
    return;
}

# FUNCTION: file_rename -- renames the file to the iTunes naming scheme: 00 Song Name.mp3
# PARAMETERS: file: String -- the filename.
# RETURN: new_name: String -- the new name.
sub file_rename {
    my $file = $_[0]; # Get the file
    if (!-e $file) { die "File does not exist!"; }
    my $title = get_title($file);
    my $number = get_number($file);
    my $extension = get_extension($file);
    my $name = $number . " " . $title . $extension;
    
    $name =~ s/\//_/g; # convert any slashes in the title of the song to underscores. An experiment
    
    my $new_name = $file;
    $new_name =~ s/[^\/]*$//;
    $new_name = $new_name . $name;
    $main::songname = $new_name;
    if ($file ne $new_name) {
	move $file, $new_name;
    }
    return $new_name;
}

# FUNCTION: file_prepare -- moves the file around in the tree.
# PARAMETERS: file: String -- the filename.
# RETURN: none.
sub file_prepare {
    my $file = $_[0];
    my $dist = file_distance($file, $main::home_path);
    if ($dist == 3) {
    }
    elsif ($dist == 2) {
	my $album = get_album($file);
	my $target_dir = $file;
	$target_dir =~ s/[^\/]*$//;
	$target_dir = $target_dir . $album;
	
	if (-e $target_dir and -d $target_dir) {
	    move $file, $target_dir;
	} else {
	    my $old_artist = $file; # Music/Gojira/Stranded.mp3
	    $old_artist =~ s/[^\/]*$//; # Music/Gojira/
	    chop($old_artist); # Music/Gojira
	    
	    my $new_album = $old_artist . "/" . $album;
	    mkdir $new_album;
	    move $file, $new_album;
	}
    }
    elsif ($dist == 1) {
	my $artist = get_artist($file);
	my $album = get_album($file);
	my $target_dir = $main::home_path . "/" . $artist . "/" . $album;
	$target_dir = scriptosh($target_dir);
	if (-e $target_dir and -d $target_dir) {
	    move $file, $target_dir;
	} else {
	    my $home = $file; # Music/Stranded.mp3
	    $home =~ s/[^\/]*$//; # Music/
	    my $new_artist = $home . $artist; # Music/Gojira
	    my $new_album = $new_artist . "/" . $album; # Music/Gojira/Magma
	    mkdir $new_artist;
	    mkdir $new_album;
	    move $file, $new_album;
	}
    }
    else {
	print "There was an error in file_dist!: $dist $file\n";
    }
    return;
}

# FUNCTION: draft -- writes all artists and albums to the output destination
# PARAMETERS: path: String -- the path to search through
# RETURN: none.
sub draft {
    my $path = $_[0];
    my $date = `date +%d.%m.%y`;
    chomp $date;
    my $output = $main::outputfile . "/BackupManif_" . $date . ".txt";
    if (-e $output) {
	my $i = 2;
	until (!-e $output) {
	    $output = $main::outputfile . "/BackupManif" . $i . "_" . $date . ".txt";
	    $i++;
	}
    }
    my $outfh;
    open $outfh, ">$output" || die "$!\n";;
    my %list;

    my $DIR;
    opendir $DIR, $path or die "Cannot open dir $DIR: $!\n";
    my @artists = readdir $DIR;
    closedir $DIR;
    foreach my $i (@artists) {
	my $art = $path . "/" . $i;
	next if (!-d $art || $i eq ".." || $i eq "." || $i eq ".DS_Store");
	opendir my $DIR, $art or die "Cannot open dir $DIR: $!\n";
        my @albums = readdir $DIR;
	my $n = 0;
	foreach my $s (@albums) {
	    next if ($s eq "." || $s eq ".." || $s eq ".DS_Store");
	    $list{$i}[$n] = $s;
	    $n++;
	}
	closedir $DIR;
    }
    my @keys = sort keys %list;
    
    print $outfh "Backup Manifest for the Date of $date\n\n";
    foreach my $i (@keys) {
	my $str = join(", ", @{$list{$i}});
	print $outfh "$i - $str\n";
    }
    close $outfh;
    return;
}

# ================================================================================
# =========================== HELPER FUNCTIONS ===================================
# ================================================================================


# FUNCTION: scriptosh -- converts a file path name to a shell-friendly file path name;
#           delimits all special characters.
# PARAMETERS: file: String -- the file name to be manipulated
# RETURN: file: String -- the successfully mangled file path name.
sub scriptosh {
    my $file = $_[0];
    $file =~ s/(?<=[^\\])[\ \'\(\)&,:]/\\$&/g;
    return $file;
}

# FUNCTION: shtoscrip -- converts all shell-friendly file path names back to their original
#           names by un-delimiting all special characters.
# PARAMETERS: file: String -- the file path name to be manipulated.
# RETURN: file: String -- the successfully mangles file path name.
sub shtoscrip {
    my $file = $_[0];
    $file =~ s/[\\](?=[\ \'\(\)&,])//g;
    return $file;
}

# FUNCTION: file_check -- checks if the file has artist and album metadata.
# PARAMETERS: file: String -- the file path name to be checked.
# RETURN: "(null)" on failure, "\n" on success.
sub file_check {
    my $file = $_[0];
    my $artist = get_artist($file);
    my $album = get_album($file);
    if ($artist eq "(null)" || $album eq "(null)") { return ""; }
    else { return "\n"; }
    return;
}

# FUNCTION: file_distance -- determines the distance between a file and main directory.
#           i.e. Music/00 Song Name.mp3 has a distance of 1.
# PARAMETERS: _: String -- file to be checked.
# RETURN: count: Integer -- the distance between 1 and 3 between the file and main directory.
sub file_distance {
    $_ = $_[0];
    my $count = 0;
    until ($_ eq $main::home_path) {
	s/[^\/]*$//;
	chop $_;
	$count++ if -e;
    }
    return $count;
}

# FUNCTION: get_extension -- gets the extension of the file.
# PARAMETERS: extension: String -- the file to get the extension of.
# RETURN: extension: String -- the extension of the file (either .mp3 or .m4a)
sub get_extension {
    my $extension = $_[0];
    $extension =~ s/.*(?=\.)//; # Get the extension
    return $extension;
}
    

# FUNCTION: get_number -- gets the track number of the song (%2d)
# PARAMETERS: file: String -- the file to get the track number of.
# RETURN: number: Integer -- the track number of the song in two digit precision.
sub get_number {
    my $file = $_[0];
    $file = scriptosh($file);
    my $number = `mdls -name kMDItemAudioTrackNumber $file`; # Get the track number 
    chomp($number);
    $number =~ s/\D*//; # Remove all non digit characters
    if ($number < 10) {
	return "0" . $number;
    } else {
	return $number;
    }
}

# FUNCTION: get_title -- gets the title of the song from the metadata of the file.
# PARAMETERS: file: String -- the file to get the title of.
# RETURN: title: String -- the title of the song.
sub get_title {
    my $file = $_[0];
    $file = scriptosh($file);
    my $title = `mdls -name kMDItemTitle $file`;
    $title =~ /"([^"]*)"/;
    $title = $1;
    return $title;
}

# FUNCTION: get_artist -- gets the artist of the file from the metadata.
# PARAMETERS: file: String -- the file to get the artist of.
# RETURN: artist: String -- the artist of the file.
sub get_artist {
    my $file = $_[0];
    $file = scriptosh($file);
    my $artist = `mdls -name kMDItemAuthors $file`; # Get the artist name...
    if ($artist eq "kMDItemAuthors = (null)\n" || $artist !~ m/kMDItemAuthors/) {
	return "(null)";
    } else {
	$artist =~ /\(([^\)]+)\)/;
	$artist = $1;
	$artist =~ /"([^"]*)"/;
	$artist = $1;
	$artist =~ s/^\s+|\s+$//g;
	return $artist;
    }
}

# FUNCTION: get_album -- gets the album of the song from the metadata.
# PARAMETERS: file: String -- the file to get the album of.
# RETURN: album: String -- the album of the song.
sub get_album {
    my $file = $_[0];
    $file = scriptosh($file);
    my $album = `mdls -name kMDItemAlbum $file`; # Get the album name...
    if ($album eq "kMDItemAlbum = (null)\n" || $album !~ m/kMDItemAlbum/) {
	return "(null)";
    } else {
	$album =~ s/.*"([^"]+)"/$1/;
	$album =~ s/[\n]//g; # ...Just the album name
	return $album;
    }
}
