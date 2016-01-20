#!/usr/bin/perl -w

use strict;
use warnings;

use Net::SMTP;
use List::Util qw( shuffle );

my @pool = ();

open my $input, '<', $ARGV[0] or die "nope";

while (my $line = <$input>) {
	# Skip commented out lines.
	if (substr($line, 0, 1) eq '#') {
		next;
	}

	chomp $line;
	my ( $n, $e ) = split /,/, $line;
	push @pool, { 'name' => $n, 'email' => $e };
}

@pool = shuffle @pool;

for my $i (0 .. scalar(@pool)-1) {
	# Form a directed cycle graph
	my $santa = $pool[$i];
	my $victim = $pool[($i+1) % scalar(@pool)];

	print "$santa->{'name'} -> $victim->{'name'}\n";
	unless (email( $santa, $victim )) {
		print STDERR "Not emailed: $santa->{'name'}\n";
	}
}

sub email {
	my ( $santa, $victim ) = @_;

	unless (defined $santa->{'email'}) {
		return 0;
	}

	my $from = "santa\@smoothwall.net";
	my $to =  $santa->{'email'};
	my $smtp = new Net::SMTP('sotonfs.soton.smoothwall.net') or die $!;
	my $message = "Hi $santa->{'name'},\n\n"
		. "Your secret santa victim this year is $victim->{'name'}.\n\n"
		. "Regards,\n"
		. "Santa\n";

	$smtp->mail($from);
	$smtp->to($to);
	$smtp->data();

	$smtp->datasend("From: \"Secret Santa\" <$from>\n");
	$smtp->datasend("To: $to\n");
	$smtp->datasend("Subject: Secret Santa\n");
	$smtp->datasend("\n");
	$smtp->datasend("$message\n");
	$smtp->dataend();
	$smtp->quit;

	return 1;
}
