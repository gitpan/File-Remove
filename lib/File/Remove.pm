package File::Remove;

=head1 NAME

B<File::Remove> - Remove files and directories

=head1 SYNOPSIS

    use File::Remove qw(remove);

    # removes several files and directories
    remove qw( file1 file2 directory1 );

    # removes (with recursion) several files
    remove \1, qw( file3 file4 directory5 );

    # removes only files, even if the filespec matches a directory
    remove "*.c","*.pl";

    # recurses into subdirectories and removes them all
    remove \1, "directory"; 

=head1 DESCRIPTION

B<File::Remove::remove> removes files and directories.  It acts like
B<rm>, for the most part.  Although unlink can be given a list of files,
it will not remove directories; this module remedies that.  It also
accepts wildcards, * and ?, as arguments for filenames.

=head1 METHODS

=over 4

=item X<remove>

Removes files and directories.  Directories are removed recursively like
in B<rm -rf> if the first argument is a reference to a scalar that
evaluates to true.  If the first arguemnt is a reference to a scalar
then it is used as the value of the recursive flag.  By default it's
false so only pass \1 to it.
In list context it returns a list of files/directories removed, in
scalar context it returns the number of files/directories removed.  The
list/number should match what was passed in if everything went well.

=item X<rm>

Just calls remove.  It's there for people who get tired of typing
'remove'.

=back

=head1 BUGS

See http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Remove for the
up-to-date bug listing.

=head1 AUTHOR

Taken over by Richard Soderberg, E<lt>perl@crystalflame.netE<gt>, so as
to port it to L<File::Spec>.

Original copyright: (c) 1998 by Gabor Egressy, E<lt>gabor@vmunix.comE<gt>.

All rights reserved.  All wrongs reversed.  This program is free software;
you can redistribute and/or modify it under the same terms as Perl itself.

=cut

use strict;
use vars qw(@EXPORT_OK @ISA $VERSION $debug);
@ISA = qw(Exporter);
# we export nothing by default :)
@EXPORT_OK = qw(remove rm);

use File::Spec qw(no_upwards catfile catdir);

$VERSION = '0.21_00';

sub _recurse_dir($);

sub _recurse_dir($)
{
    my $dir = shift;

    chmod 0777,$dir;
    opendir DIR,$dir
        or return 0;
    my @files = &no_upwards(readdir DIR)
        or return 0;
    closedir DIR;

    my $ret;
    for (@files) {
	my $file = &catfile($dir, $_);
	# TODO: this needs to be more aware of &catdir
        print "file: $file\n"
            if $debug;
        if(-f $file || -l _) {
            unlink $file
                or next;
            $ret = 1;
        } else {
	    my $path = &catdir($dir, $_);
            if(-d $path && ! -l _) {
                _recurse_dir $path;
                rmdir $path
                    or next;
            }
	}
    }
    $ret;
}

sub expand(@)
{
    my @args;

    for (@_) {
        push @args, glob;
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
        if(-f $_ || -l _) {
            unlink $_
                and push @removes,$_;
        }
        elsif(-d $_ && $$recursive) {
	    # XXX: this regex seems unnecessary, and may trigger bugs someday.
	    # TODO: but better to trim trailing slashes for now.
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
