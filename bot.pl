#!/usr/bin/perl
use strict;
use warnings;

use AnyEvent;
use AnyEvent::IRC::Client;
use Data::Dumper;
use DBI;
use Getopt::Long;
use LWP::UserAgent;

my %opt = (
    server  => 'irc.run.net',
    port    => 6667,
    nick    => "Triplegondastkneht",
    channel => '#0xff',
);

GetOptions(\%opt, 'server', 'port', 'nick', 'channel');

my $c = AnyEvent->condvar;
my $con = AnyEvent::IRC::Client->new;

$con->reg_cb(
	connect => sub {
		my ($con, $err) = @_;

		if(defined($err)) {
			warn "!! Connection error: $err\n";
			return;
		} else {
			print " * Connected\n";
		}
	},
	registered => sub {
		my ($con) = @_;

		print " * Registered\n";
	},
	channel_add => undef,
	channel_remove => undef,
	channel_change => undef,
	channel_nickmode_update => undef,
	channel_topic => sub {
		my ($con, $channel, $topic, $who) = @_;

		print " * Topic of $channel is $topic".($who ? " set by $who " : '')."\n";
	},
    join => sub {
        my ($con, $nick, $channel, $is_myself) = @_;

        if ($is_myself && $channel eq $opt{channel}) {
			print " * Joined to $channel\n";
        } else {
			print " * $nick joined to $channel\n";
		}
    },
    part => sub {
		my ($con, $nick, $channel, $is_myself, $msg) = @_;

		print " * $nick has left $channel\n"."$msg\n";
	},
    kick => sub {
        my ($con, $kicked, $channel, $is_myself, $msg, $kicker) = @_;

        print " * $kicked has kicked from $channel by $kicker\n"."$msg";
    },
    quit => sub {
		my ($con, $nick, $msg) = @_;

		print " * $nick has quit\n"."$msg\n";
	},
    nick_change => sub {
		my ($con, $old, $new, $is_myself) = @_;

		print " * $old has changed to $new\n";
	},
    publicmsg => sub {
        my ($con, $nick, $ircmsg) = @_;
    },
    privatemsg => sub {
		my ($con, $nick, $ircmsg) = @_;
	},
	ctcp => sub {
		my ($con, $sender, $target, $tag, $msg, $type) = @_;

		print " * $sender send CTCP $tag to $target by $type\n"."$msg\n";
	},
	error => sub {
		my ($con, $code, $message, $ircmsg) = @_;
		# rfc_code_to_name($code)
	}
);

$con->connect($opt{server}, $opt{port}, { nick => $opt{nick} });
$con->send_srv(JOIN => $opt{channel});

$c->wait;
$con->disconnect;
