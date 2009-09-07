#!perl

use Test::More tests => 28;
use strict;
use warnings;
use File::Temp;
use Socket::Class;

BEGIN {
    use_ok( 'threads::emulate::Server' );
}

ok(ref (my $obj = threads::emulate::Server->new) eq "threads::emulate::Server");
ok(ref ($obj->logger) eq "threads::emulate::Logger");
ok(ref ($obj->sock) eq "Socket::Class");

$obj->logger->level(100);

$obj->logger->testName("just testing");
ok(-e $obj->sock->local_path, "does exist '" . $obj->sock->local_path . "'?");

$obj->logger->logFile(my $fname = tmpnam);

$obj->logger->testName("just testing");
is($obj->TESTCMD(qw/just testing/), "TESTCMD: just testing");
ok(-f $fname);
open my $fh, "<", $fname || die "File do not exists";
is(scalar <$fh>, "TESTCMD(just testing)$/");
close $fh;
unlink $fname;

$obj->logger->testName("no cmd");
is($obj->no_cmd(qw/testing no cmd/), undef);
ok(-f $fname);
open $fh, "<", $fname || die "File do not exists";
is(scalar <$fh>, "testing$/");
close $fh;
unlink $fname;

$obj->logger->testName("cmd not found");
is($obj->cmd_not_found(qw/testing cmd not found/), undef);
ok(-f $fname);
open $fh, "<", $fname || die "File do not exists";
is(scalar <$fh>, "testing$/");
close $fh;
unlink $fname;

$obj->logger->testName("just testing");
my $pid = fork();
if(not $pid){
   $obj->run;
}
sleep 1;
ok(-f $fname);
open $fh, "<", $fname || die "File do not exists";
ok(<$fh> =~ /executing run\(\) with pid (\d+)/);
my $master_pid = $1;
close $fh;
unlink $fname;
kill 10 => $master_pid;
sleep 1;
ok(-f $fname);
open $fh, "<", $fname || die "File do not exists";
is(scalar <$fh>, "exiting$/");
close $fh;
unlink $fname;

ok(ref ($obj = threads::emulate::Server->new) eq "threads::emulate::Server");
ok(ref ($obj->logger) eq "threads::emulate::Logger");
ok(ref ($obj->sock) eq "Socket::Class");

$obj->logger->level(100);

$obj->logger->testName("just testing");
ok(-e $obj->sock->local_path, "does exist '" . $obj->sock->local_path . "'?");

$obj->logger->logFile($fname = tmpnam);

$pid = fork();
if(not $pid){
   $obj->run;
}
sleep 1;
ok(-f $fname);
open $fh, "<", $fname || die "File do not exists";
ok(<$fh> =~ /executing run\(\) with pid (\d+)/);
$master_pid = $1;
close $fh;
unlink $fname;
my $sock = $obj->sock->local_path;
ok(defined $sock, "sock: $sock");
ok(-e $sock, "'$sock' exists");
my $c = Socket::Class->new(domain => "unix", remote_path => $sock) || die "$sock: " . Socket::Class->error;
$c->say("EXIT: ");
sleep 1;
ok(-f $fname);
open $fh, "<", $fname || die "File do not exists";
is(scalar <$fh>, "exiting...$/");
close $fh;
unlink $fname;

