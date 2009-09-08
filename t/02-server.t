#!perl

use Test::More tests => 48;
use strict;
use warnings;
use File::Temp;
use IO::Socket;

BEGIN {
    use_ok( 'threads::emulate::Server' );
}

unlink ".test.log" if -f ".test.log";

ok(ref (my $obj = threads::emulate::Server->new) eq "threads::emulate::Server");
ok(ref ($obj->logger) eq "threads::emulate::Logger");
ok(ref ($obj->sock) =~ m/^IO::Socket::(?:INET|UNIX)/);

$obj->logger->level(100);
$obj->logger->logFile(".test.log");

$obj->logger->testName("just testing");
ok(-e $obj->sock->hostpath, "does exist '" . $obj->sock->hostpath. "'?");

$obj->logger->testFile(my $fname = tmpnam);

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
ok(ref ($obj->sock) =~ m/^IO::Socket::(?:INET|UNIX)/);

$obj->logger->level(100);

$obj->logger->testName("just testing");
ok(-e $obj->sock->hostpath, "does exist '" . $obj->sock->hostpath . "'?");

$obj->logger->testFile($fname = tmpnam);

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
my $sock = $obj->sock->hostpath;
ok(defined $sock, "sock: $sock");
ok(-e $sock, "'$sock' exists");
#my $c = Socket::Class->new(domain => "unix", remote_path => $sock) || die "$sock: " . Socket::Class->error;
my $c = IO::Socket::UNIX->new(Type => SOCK_STREAM, Peer => $obj->sock->hostpath);
print({$c} "EXIT: \r\n");
sleep 1;
ok(-f $fname);
open $fh, "<", $fname || die "File do not exists";
is(scalar <$fh>, "exiting...$/");
close $fh;
unlink $fname;

ok(ref ($obj = threads::emulate::Server->new) eq "threads::emulate::Server");
ok(ref ($obj->logger) eq "threads::emulate::Logger");
ok(ref ($obj->sock) =~ m/^IO::Socket::(?:INET|UNIX)/);

$obj->logger->level(100);

$obj->logger->testName("just testing");
ok(-e $obj->sock->hostpath, "does exist '" . $obj->sock->hostpath . "'?");

$obj->logger->testFile($fname = tmpnam);

$pid = fork();
if(not $pid){
   $obj->run;
}
sleep 1;
ok(-f $fname, "did the run() made the test file");
open $fh, "<", $fname || die "File do not exists";
ok(<$fh> =~ /executing run\(\) with pid (\d+)/, "is the run() running?"); #33
$master_pid = $1;
close $fh;
unlink $fname;

for(1 .. 5){
   my $c = IO::Socket::UNIX->new(Type => SOCK_STREAM, Peer => $obj->sock->hostpath);
   ok(-e $obj->sock->hostpath, "trying the ${_}th loop");
   print {$c} "TESTCMD: $_\r\n";
   my $ans;
   {
      local $/ = "\r\n";
      chomp($ans = scalar <$c>);
   }
   $ans =~ s/\r\n?$//;
   ok($ans, "recived data ($ans) in the ${_}th loop");
   #sleep 1;
}

ok(-f $fname, "does the file exist?");
open $fh, "<", $fname || die "File do not exists";
is(scalar (grep {m/^TESTCMD/} <$fh>), 5, "is there 5 entryes in the log file?");
close $fh;
unlink $fname;

$c = IO::Socket::UNIX->new(Type => SOCK_STREAM, Peer => $obj->sock->hostpath);
$c->say("EXIT: ");
sleep 1;
ok(-f $fname, "Did the EXIT command realy exited?");
open $fh, "<", $fname || die "File do not exists";
is(scalar <$fh>, "exiting...$/");
close $fh;
unlink $fname;
#ok(not kill(0 => $master_pid), "is the process running?");


kill 10 => $master_pid;
