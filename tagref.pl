use strict;

my $refs = `egrep -rnHo "\@ref:[^\s]+\@"`;
chop $refs;

my $tags = `egrep -rnHo "\@tag:[^\s]+\@"`;
chop $tags;

my @errors = ();
sub parse_tags {
    my ($output) = @_;
    my %tags = ();
    foreach (split /\n/, $output) {
        my ($file, $full_label) = split /:\d+:/, $_;
        my ($tag_type,$tag) = split /:/, $full_label;
        chop $tag;
        $tag =~ s/^\s+|\s+$//g;
        $_ =~ /:(\d+):/;
        my $line = $1;
        if (exists $tags{$tag}) {
            my $other_file_location = $tags{$tag};
            push @errors, "Error: tag '$tag' is not unique, exists in $other_file_location and in $file on $line\n";
        } else {
            $tags{$tag} = $file . ' on line ' . $line;
        }
    }
    return %tags;
}

sub parse_refs {
    my ($output, %tags) = @_;
    foreach (split /\n/, $output) {
        my ($file, $full_label) = split /:\d+:/, $_;
        my ($ref_type,$ref) = split /:/, $full_label;
        chop $ref;
        $ref =~ s/^\s+|\s+$//g;
        if (!exists $tags{$ref}) {
            $_ =~ /:(\d+):/;
            my $line = $1;
            push @errors, "Error: tag '$ref' does not exist, referenced in $file on line $line\n";
        }
    }
}

my %parsed_tags = parse_tags $tags;
parse_refs $refs, %parsed_tags;
if (@errors) {
    foreach (@errors) {
        print "$_";
    }
    exit;
}