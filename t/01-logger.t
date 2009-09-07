#!perl

use Test::More tests => 56;
use File::Temp qw/:POSIX/;
use strict;
use warnings;

BEGIN {
    use_ok( 'threads::emulate::Logger' );
}

ok(ref (my $log = threads::emulate::Logger->new) eq "threads::emulate::Logger");
ok($log->level == 0);
ok(ref ($log = threads::emulate::Logger->new(level => "debug")) eq "threads::emulate::Logger");
ok($log->level == 5);
ok(not defined $log->logFile);
ok($log eq threads::emulate::Logger->new);
ok($log->can("log"));
ok($log->log("debug test"));
ok($log->log(qw"debug test"));
ok($log->can("debug"));
ok($log->debug("debug test"));
ok($log->debug(qw"debug test"));
ok($log->can("info"));
ok($log->info("info test"));
ok($log->info(qw"info test"));
ok($log->can("warn"));
ok($log->warn("warn test"));
ok($log->warn(qw"warn test"));
ok($log->can("error"));
ok($log->error("error test"));
ok($log->error(qw"error test"));
ok($log->can("fatal"));
ok($log->fatal("fatal test"));
ok($log->fatal(qw"fatal test"));
ok(ref ($log = threads::emulate::Logger->new(level => "warn")) eq "threads::emulate::Logger");
ok($log->level == 3, "Change level to \"warn\" level");
ok(not($log->debug("debug test")), "Debug test in warn level");
ok(not($log->info("info test")), "Info test in warn level");
ok($log->warn("warn test"), "Warn test in warn level");
ok($log->error("error test"), "Error test in warn level");
ok($log->fatal("fatal test"), "Fatal test in warn level");
ok(ref ($log = threads::emulate::Logger->new(level => 30)) eq "threads::emulate::Logger");
ok($log->level == 30);

eval{$log->debug_die("debug test") };
ok($@ =~ /^debug test/, "Debug_die test in level 30");
eval{$log->info_die("info test")  };
ok($@ =~ /^info test/, "Info_die test in level 30");
eval{$log->warn_die("warn test")  };
ok($@ =~ /^warn test/, "Warn_die test in level 30");
eval{$log->error_die("error test")};
ok($@ =~ /^error test/, "Error_die test in level 30");
eval{$log->fatal_die("fatal test")};
ok($@ =~ /^fatal test/, "Fatal_die test in level 30");

my $tmpfile = tmpfile;

$log->level(10);
ok($log->level == 10);
my $fname = tmpnam;
$log->logFile($fname);
ok($log->log("test"));
open my $fh, "<", $fname;
my $text_log = <$fh>;
ok($text_log =~ /^\w{3} \w{3}\s+\d{1,2} \d{2}:\d{2}:\d{2} \d{4}: test\s*$/);

ok($log->debug("test debug"));
$text_log = <$fh>;
ok($text_log =~ /^\w{3} \w{3}\s+\d{1,2} \d{2}:\d{2}:\d{2} \d{4}: \[DEBUG\] test debug\s*$/);

close $fh;
unlink $fname;

$log->level(99);
$log->testName("lalala");
ok(not $log->test("testing the test", "Testing the test method"));
ok(not -f $fname);

$log->level(100);
$log->testName("lalala");
ok(not $log->test("testing the test", "Testing the test method"));
ok(not -f $fname);

$log->level(99);
$log->testName("testing the test");
ok(not $log->test("testing the test", "Testing the test method"));
ok(not -f $fname);

$log->level(100);
$log->testName("testing the test");
ok($log->test("testing the test", "Testing the test method"));
ok(-f $fname);
open $fh, "<", $fname;
ok(scalar <$fh> eq "Testing the test method$/");

close $fh;
unlink $fname;

$log->level(100);
$log->testName("testing the test");
ok($log->test("testing the test", qw/Testing the test method/));
ok(-f $fname);
open $fh, "<", $fname;
ok(scalar <$fh> eq "Testing the test method$/");

close $fh;
unlink $fname;

