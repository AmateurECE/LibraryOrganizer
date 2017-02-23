#!/usr/bin/perl
#
# vv.pl
#
# Attempt number two at the system thing. Oh well!

$file = "/Users/ethantwardy/Desktop/Perl/Music/Gojira/Magma/04 Stranded.mp3";
$file =~ s/(?<=[^\\])[ '\(\)]/\\$&/g;
$parent = $file;
$parent =~ s/[^\/]*$//; # Get the parent directory
$new_name = chop($parent);
$new_name =~ s/[^\/]*$//; # Get the parent directory
print "$parent\n"; 
# ==================== UNCOMMENT WHEN READY ====================
#use File::Find;
#$path = "/Users/ethantwardy/Desktop/Perl/Music";
#find(\&wanted, $path);
# ==============================================================
sub wanted {
    if (!-d && ($_ ne ".DS_Store") && m/(mp3|m4a)$/) {
	print "$_ \n";
	$filename = file_rename($File::Find::name);
	return;
    }
}

# The routine to determine what happens to the file
sub file_do {
}

sub file_rename {
    $file = $_[0]; # Get the file
    $file =~ s/(?<=[^\\])[ \'\(\)]/\\$&/g; # Replace and whitespaces with delimited whitespaces
    $result = `mdls -name kMDItemTitle $file`;
    @buffer = split(/"/, $result);
    $name = $buffer[1]; # Get the title of the song
    
    $result = `mdls -name kMDItemAudioTrackNumber $file`; # Get the track number 
    chomp($result);
    $result =~ s/\D*//; # Remove all non digit characters

    $ext = $file;
    $ext =~ s/.*(?=\.)//; # Get the extension

    if ($result < 10) { # Concatentate
	$name = "0" . $result . " " . $name . $ext;
    } else {
	$name = $result . " " . $name . $ext;
    }

    $new_name = $file;
    $new_name =~ s/[^\/]*$//;
    $new_name = $new_name . $name;
    $new_name =~ s/(?<=[^\\])[ \'\(\)]/\\$&/g;
#    print "$new_name\n";
#    print "$file\n";
    $result = `mv $file $new_name`;
    return $new_name;
}

# Subroutine to determine the distance between a file and a parent directory.
sub file_distance {
    $child = $_[0];
    $parent = $_[1];
    $parent =~ s/.*\///;
    @nodes = split("/", $child);
    $index = 0;
    foreach $i (@nodes) {
	if ($i eq $parent) {
	    $index = 0;
	}
	$index++;
    }
    $index -= 1;
    return;
}

# subroutine to move the file around in the tree
sub file_prepare {
    $file = $_[0];
    $dist = file_distance($file, $main::path);
    if (dist == 3) {

	$artist = `mdls -name kMDItemAuthors $file`; # Get the artist name...
	$artist =~ /\(([^\)]+)\)/;
	$artist = $1;
	$artist =~ s/[\n|\ ]//g; # ...Just the artist name

	$album = `mdls -name kMDItemAlbum $file`; # Get the album name...
	$album =~ s/.*"([^"]+)"/$1/;
	$album =~ s/[\n|\ ]//g; # ...Just the album name

	$parent = $file; # Music/Somedir/Anotherdir/Song.mp3
	$parent =~ s/[^\/]*$//; # Music/Somedir/Anotherdir/

	$new_name = chop($parent); # Music/Somedir/Anotherdir
	$new_name =~ s/[^\/]*$//; # Music/Somedir/
	$new_name = $new_name . $album; # Music/Somedir/Albumname
	system("mv $parent $new_name"); # Make sure that it is named after the album

	$parent =~ s/[^\/]*$//; # Music/Somedir/
	chop($parent);
	$parent =~ s/[^\/]*$//; # Music/
	$new_name = $parent;
	$new_name = $new_name . $artist;
	system("mv $parent $new_name"); # Make sure that it is named after the artist
	return;
    }
    elsif (dist == 2) {
	$parent = $file;
	$parent =~ s/[^\/]*$//; # Get the parent directory
	$new_name = chop($parent);
	$new_name =~ s/[^\/]*$//; # Get its parent directory

	$artist = `mdls -name kMDItemAuthors $file`; # Get the artist name...
	$artist =~ /\(([^\)]+)\)/;
	$artist = $1;
	$artist =~ s/[\n|\ ]//g; # ...Just the artist name

	$album = `mdls -name kMDItemAlbum $file`; # Get the album name...
	$album =~ s/.*"([^"]+)"/$1/;
	$album =~ s/[\n|\ ]//g; # ...Just the album name

	$new_name = $new_name . $artist;
	$parent = $parent . "/" . $album;
	if (system("mv $file $parent") != 0) {
	    system("mkdir $parent");
	    system("mv $file $parent");
	}
	return;
    }
    elsif (dist == 1) {
	
    }
    else {
	print "There was an error in file_prepare!: $file\n";
	return;
    }
}

# Things to do: Rename the file, Rename the folder,
