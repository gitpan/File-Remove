# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl File-Remove.t'

#########################

# change 'tests => 2' to 'tests => last_test_to_print';

use Test::More qw(no_plan); # tests => 2;
BEGIN { use_ok('File::Remove' => qw(remove trash)) };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my @dirs = ("$0.tmp", map { "$0.tmp/$_" } qw(a a/b c c/d e e/f g));

for my $path (reverse @dirs) {
    if (-e $path) {
	ok rmdir($path),
	  "rmdir: $path";
	ok !-e $path,
	  "!-e: $path";
    }
}

for my $path (@dirs) {
    ok !-e $path,
      "!-e: $path";
    ok mkdir($path),
      "mkdir: $path";
    ok -e $path,
      "-e: $path";
}

for my $path (reverse @dirs) {
    ok -e $path,
      "-e: $path";
    ok rmdir($path),
      "rmdir: $path";
    ok !-e $path,
      "!-e: $path";
}

for my $path (@dirs) {
    ok !-e $path,
      "!-e: $path";
    ok mkdir($path),
      "mkdir: $path";
    ok -e $path,
      "-e: $path";
}

for my $path (reverse @dirs) {
    ok -e $path,
      "-e: $path";
    ok remove(\1, $path),
      "remove \\1: $path";
    ok !-e $path,
      "!-e: $path";
}

for my $path (@dirs) {
    ok !-e $path,
      "!-e: $path";
    ok mkdir($path),
      "mkdir: $path";
    ok -e $path,
      "-e: $path";
}

for my $path (reverse @dirs) {
    ok -e $path,
      "-e: $path";
    ok remove($path),
      "remove: $path";
    ok !-e $path,
      "!-e: $path";
}

for my $path (reverse @dirs) {
    ok !-e $path,
      "-e: $path";
    if (-e _) {
	ok rmdir($path),
	  "rmdir: $path";
	ok !-e $path,
	  "!-e: $path";
    }
}

{
    local $TODO;
    $TODO = "Undelete support not available for this platform" unless $^O =~ /(?:win32|darwin)/i;
    goto UNDELETE if defined $TODO;

    for my $path (@dirs) {
	ok !-e $path,
	  "!-e: $path";
	ok mkdir($path),
	  "mkdir: $path";
	ok -e $path,
	  "-e: $path";
    }

    for my $path (reverse @dirs) {
	ok -e $path,
	  "-e: $path";
	ok eval { trash($path) },
	  "trash: $path";
	ok !-e $path,
	  "!-e: $path";
    }

    for my $path (reverse @dirs) {
	ok !-e $path,
	  "-e: $path";
	if (-e _) {
	    ok rmdir($path),
	      "rmdir: $path";
	    ok !-e $path,
	      "!-e: $path";
	}
    }

    for my $path (@dirs) {
	ok !-e $path,
	  "!-e: $path";
	ok mkdir($path),
	  "mkdir: $path";
	ok -e $path,
	  "-e: $path";
    }

    for my $path (reverse @dirs) {
	ok -e $path,
	  "-e: $path";
	ok remove($path),
	  "remove: $path";
	ok !-e $path,
	  "!-e: $path";
    }

    for my $path (reverse @dirs) {
	ok !-e $path,
	  "-e: $path";
	if (-e _) {
	    ok rmdir($path),
	      "rmdir: $path";
	    ok !-e $path,
	      "!-e: $path";
	}
    }

    for my $path (@dirs) {
	ok !-e $path,
	  "!-e: $path";
	ok mkdir($path),
	  "mkdir: $path";
	ok -e $path,
	  "-e: $path";
    }

    for my $path (reverse @dirs) {
	ok -e $path,
	  "-e: $path";
	ok eval { trash({ 'rmdir' => sub { 1 }, 'unlink' => sub { 1 } }, $path) },
	  "trash: $path";
	ok -e $path,
	  "-e: $path";
	ok rmdir($path),
	  "rmdir: $path";
	ok !-e $path,
	  "!-e: $path";
    }

    UNDELETE: 1;
}

1;
