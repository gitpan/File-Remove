package File::Remove;

=head1 NAME

B<File::Remove> - Remove files and directories

=head1 SYNOPSIS

    use File::Remove qw(remove);

    # removes (without recursion) several files
    remove qw( *.c *.pl );

    # removes (with recursion) several directories
    remove \1, qw( directory1 directory2 ); 

    # removes (with recursion) several files and directories
    remove \1, qw( file1 file2 directory1 *~ );

    # removes (with support for undeleting later) several files
    undelete qw( *~ );

=head1 DESCRIPTION

B<File::Remove::remove> removes files and directories.  It acts like
B</bin/rm>, for the most part.  Although unlink can be given a list
of files, it will not remove directories; this module remedies that.
It also accepts wildcards, * and ?, as arguments for filenames.

B<File::Remove::undelete> accepts the same arguments as B<remove>.

=head1 METHODS

=over 4

=item remove

Removes files and directories.  Directories are removed recursively like
in B<rm -rf> if the first argument is a reference to a scalar that
evaluates to true.  If the first arguemnt is a reference to a scalar
then it is used as the value of the recursive flag.  By default it's
false so only pass \1 to it.

In list context it returns a list of files/directories removed, in
scalar context it returns the number of files/directories removed.  The
list/number should match what was passed in if everything went well.

=item rm

Just calls remove.  It's there for people who get tired of typing
'remove'.

=item undelete

Removes files and directories, with support for undeleting later.
Arguments are passed unmodified to B<remove>.

=over 4

=item Win32

Requires L<Win32::FileOp>.

=item OS X

Requires L<Mac::Glue>.

=item Other platforms

Not supported at this time.

=back

=back

=head1 BUGS

See http://rt.cpan.org/NoAuth/Bugs.html?Dist=File-Remove for the
up-to-date bug listing.

=head1 AUTHOR

Taken over by Richard Soderberg, E<lt>perl@crystalflame.netE<gt>, so as
to port it to L<File::Spec> and add tests.

Original copyright: (c) 1998 by Gabor Egressy, E<lt>gabor@vmunix.comE<gt>.

All rights reserved.  All wrongs reversed.  This program is free software;
you can redistribute and/or modify it under the same terms as Perl itself.

=cut

use strict;
use vars qw(@EXPORT_OK @ISA $VERSION $debug $unlink $rmdir);
@ISA = qw(Exporter);
# we export nothing by default :)
@EXPORT_OK = qw(remove rm undelete);

$debug++;

use File::Spec;

$VERSION = '0.24';

sub _recurse_dir($);

sub _recurse_dir($)
{
    my $dir = shift;

    chmod 0777,$dir;
    opendir DIR,$dir
        or return 0;
    my @files = File::Spec->no_upwards(readdir DIR)
        or return 0;
    closedir DIR;

    my $ret;
    for (@files) {
	my $file = File::Spec->catfile($dir, $_);
	# TODO: this needs to be more aware of catdir
        print "file: $file\n"
            if $debug;
        if(-f $file || -l $file) {
            $unlink->($file)
                or next;
            $ret = 1;
        } elsif (-d $file && ! -l $file) {
	    _recurse_dir $file;
	    $rmdir->($file)
	        or next;
	}
    }
    $ret;
}

sub expand (@)
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
sub remove (@)
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
        print "file: $_\n" if $debug;
        if(-f $_ || -l $_) {
            print "file unlink: $_\n" if $debug;
	    my $result = $unlink ? $unlink->($_) : unlink($_);
	    push(@removes, $_) if $result;
        }
        elsif(-d $_) {
	    print "dir: $_\n" if $debug;
	    # XXX: this regex seems unnecessary, and may trigger bugs someday.
	    # TODO: but better to trim trailing slashes for now.
	    s/\/$//;
	    my ($save_mode) = (stat $_)[2];
	    if ($$recursive) {
		$ret = _recurse_dir $_;
	    }
	    chmod $save_mode & 0777,$_; # just in case we cannot remove it.
	    my $result = $rmdir ? $rmdir->($_) : rmdir($_);
	    push(@removes, $_) if $result;
        } else {
	    print "???: $_\n" if $debug;
	}
    }

    @removes;
}

sub rm (@) { goto &remove }

sub undelete (@) {
    our $unlink;
    our $rmdir;
    if ($^O =~ /win32/i) {
	eval 'use Win32::FileOp ();';
	die "Can't load Win32::FileOp to support the Recycle Bin: \$@ = $@" if length $@;
	$unlink = \&Win32::FileOp::Recycle;
	$rmdir = \&Win32::FileOp::Recycle;
    } elsif ($^O =~ /darwin/i) {
	our $f;
	eval 'use Mac::Glue ();';
	die "Can't load Mac::Glue::Finder to support the Trash Can: \$@ = $@" if length $@;
	my $code = sub {
	    my $f = Mac::Glue->new("Finder");
	    my @files = map { s{^:}{}; $_ } map { s{/}{:}g; $_ } map { File::Spec->rel2abs($_) } @_;
	    $f->delete(@files);
	};
	$unlink = $code;
	$rmdir = $code;
    } else {
	die "Support for undelete on platform '$^O' not available at this time.\n";
    }
    goto &remove;
}

1;
