package File::Remove;
require 5.004; # just because I think you should upgrade :)

=head1 NAME

B<File::Remove> - Remove files and directories

=head1 SYNOPSIS

    use File::Remove qw(remove);

    remove \1,"file1","file2","directory1","file3","directory2","file4",
        "directory2","file5","directory3";

    # removes only files, even if the filespec matches a directory
    remove "*.c","*.pl";

    # recurses into subdirectories and removes them all
    remove \1, "directory"; 

=head1 DESCRIPTION

B<File::Remove::remove> removes files and directories.  It acts like
B<rm> for the most part.  Although unlink can be given a list of
files it will not remove directories.  This module remedies that.  It
also accepts wildcards, * and ?, as arguments for filenames.

=over 4

=item B<remove>

Removes files and directories.  Directories are removed recursively like
in B<rm -rf> if the first argument is a reference to a scalar that
evaluates to true.  If the first arguemnt is a reference to a scalar
then it is used as the value of the recursive flag.  By default it's
false so only pass \1 to it.
In list context it returns a list of files/directories removed, in
scalar context it returns the number of files/directories removed.  The
list/number should match what was passed in if everything went well.

=item B<rm>

Just calls remove.  It's there for people who get tired of typing
'remove'.

=back

=head1 EXAMPLE

See SYNOPSIS.

=head1 BUGS

Not that I know of. ;)

=head1 AUTHOR

Gabor Egressy B<gabor@vmunix.com>

Copyright (c) 1998 Gabor Egressy.  All rights reserved.  All wrongs
reversed.  This program is free software; you can redistribute and/or
modify it under the same terms as Perl itself.

=cut

use strict;
use vars qw(@EXPORT_OK @ISA $VERSION $debug);
@ISA = qw(Exporter);
# we export nothing by default :)
@EXPORT_OK = qw(remove rm);

$VERSION = '0.20';

sub _recurse_dir($);

sub _recurse_dir($)
{
    my $dir = shift;

    chmod 0777,$dir;
    opendir DIR,$dir
        or return 0;
    my @files = grep {! /^\.\.?$/} readdir DIR
        or return 0;
    closedir DIR;

    my $ret;
    for (@files) {
        print "$dir/$_\n"
            if $debug;
        if(-f "$dir/$_" || -l "$dir/$_") {
            unlink $dir . '/' . $_
                or next;
            $ret = 1;
        }
        elsif(-d "$dir/$_" && ! -l "$dir/$_") {
            _recurse_dir $dir . '/' . $_;
            rmdir $dir . '/' . $_
                or next;
        }
    }
    $ret;
}

sub expand(@)
{
    my @args;

    for (@_) {
        push @args,glob;
    }
    @args;
}

# acts like unlink would until given a directory as an argument, then
# it acts like rm -rf ;) unless the recursive arg is zero which it is by
# default
sub remove(@)
{
    my $recursive;
    if(ref $_[0] eq 'SCALAR') {
        $recursive = shift;
    }
    else {
        $recursive = \0;
    }
    my @files = expand @_;
    my @removes;

    my $ret;
    for (@files) {
        print "$_\n"
            if $debug;
        if(-f $_ || -l $_) {
            unlink $_
                and push @removes,$_;
        }
        elsif(-d $_ && $$recursive) {
            s/\/$//;
            my ($save_mode) = (stat $_)[2];
            $ret = _recurse_dir $_;
            chmod $save_mode & 0777,$_; # just in case we cannot remove it.
            rmdir $_
                and push @removes, $_;
        }
    }

    @removes;
}

sub rm(@)
{
    return remove @_;
}

1;
