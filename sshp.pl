#!/usr/bin/env perl

use common::sense;
use File::Slurp;
use Data::Dumper;

my @ssh_file = read_file("$ENV{HOME}/.ssh/config");

my %defines = ();
my @output = ();

#support defines with params
#define xx(x, y) xx $x $y

#support templates (multiline defines with params) (start and stop?)

#conditional defines (should be depending on arguments to sshp like @home)

foreach (@ssh_file) {
	chomp;

	if (/^\#define\s+(\w+)\(([^\)]+)\)\s+(.*)/) {
		my $i = 0;
		my %args = ();
		my @defaults;

		foreach (split(/\s*,\s*/, $2)) {
			my ($arg, $default) = split(':', $_, 2);
			$args{$arg} = $i++;
			push @defaults, $default;
		}

		$defines{$1} = { template => $3, params => \%args, defaults => \@defaults };
	}
	elsif (/^\#define\s+(\w+)\s+(.*)/) {
		$defines{$1} = { template => $3 };
	}
	elsif (/\#(\w+)(?:\(([^\)]+)\))?/ && exists $defines{$1}) {
		my $define = $defines{$1};
		my $data = $define->{template};

		if (exists $define->{params}) {
			my $params = $define->{params};
			my $defaults = $define->{defaults};
			my @args = split(/\s*,\s*/, $2);

			my $regex = '\\$(' . join('|', keys %$params) . ')';
			$data =~ s!$regex!$args[$params->{$1}] || $defaults->[$params->{$1}]!e;
			warn $data;
		}

		push @output, $data;
	}
	else {
		push @output, $_;
	}
}

warn Dumper(\%defines);
#say join("\n", @output);
