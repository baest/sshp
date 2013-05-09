#!/usr/bin/env perl

use common::sense;
use File::Slurp;
use Data::Dumper;

my @ssh_file = read_file("$ENV{HOME}/.ssh/config");

my @define_stack = ();
my %defines = ();
my @output = ();

#support defines with params
#define xx(x, y) xx $x $y

#STOP (stop processing)

#local define (for port number or IP for block) (howto define block?)

#MISSING
#support templates (multiline defines with params) (start and stop?)

#conditional defines (should be depending on arguments to sshp like @home)

#define support as argument

foreach (@ssh_file) {
	chomp;

	$_ = replace_define($_);
	my $push = 0;

	if (/^\#(?<local>local_)?define\s+(?<name>\w+)(?:\((?<args>[^\)]+)\)\s+)?(?<template>.*)/) {
		my $i = 0;
		my %args = ();
		my @defaults;

		if ($+{local}) {
			push @define_stack, {%defines};
		}

		if ($+{args}) {
			foreach (split(/\s*,\s*/, $+{args})) {
				my ($arg, $default) = split(':', $_, 2);
				$args{$arg} = $i++;
				push @defaults, $default;
			}

			$defines{$+{name}} = { template => $+{template}, params => \%args, defaults => \@defaults };
		}
		else {
			$defines{$+{name}} = { template => $+{template} };
		}
	}
	elsif (/^\#STOP/) {
		last;
	}
	elsif (/^\s*$/) { #block end
		%defines = %{pop @define_stack} if @define_stack;
		$push = 1;
	}
	else {
		$push = 1;
	}
	push @output, $_ if $push;
}

sub replace_define {
	my ($line) = @_;

	return $line unless $line =~ /\#(\w+)(?:\(([^\)]+)\))?/ && exists $defines{$1};

	my $define = $defines{$1};
	my $data = $define->{template};

	if (exists $define->{params}) {
		my $params = $define->{params};
		my $defaults = $define->{defaults};
		my @args = map { replace_define($_) } split(/\s*,\s*/, $2);

		my $regex = '\\$(' . join('|', keys %$params) . ')';
		$data =~ s!$regex!$args[$params->{$1}] || $defaults->[$params->{$1}]!e;
	}

	return $data;
}

#warn Dumper(\%defines);
say join("\n", @output);
