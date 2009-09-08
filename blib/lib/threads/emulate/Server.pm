package threads::emulate::Server;

use Moose;
use Moose::Util::TypeConstraints;
use threads::emulate::Logger;
use File::Temp;
use IO::Socket;

use strict;
use warnings;

subtype 'Logger' => as class_type('threads::emulate::Logger');
coerce 'Logger'
   => from 'Str' => via {threads::emulate::Logger->new(level => $_)}
   => from 'Int' => via {threads::emulate::Logger->new(level => $_)}
;
subtype 'IP'   => as 'Str' => where {m/^\d{1,3}(?:\.\d{1,3}){3}(?::d+)?$/};
subtype 'path' => as 'Str' => where {m{^[/\w.-]+$}};
subtype 'Socket' => as class_type('IO::Socket');
coerce 'Socket'
   => from 'IP'   => via {
                          my($ip, $port) = split /:/, $_;
                          IO::Socket::INET->new(
                                                Proto     => 'udp',    
                                                LocalAddr => $ip,
                                                LocalPort => $port,
                                                Listen    => 5,
                                                Reuse     => 1,
                                               ) or die "Can't bind : $@\n";
                         }
   => from 'Int'  => via {
                          IO::Socket::INET->new(
                                                Proto     => 'udp',    
                                                LocalPort => $_,
                                                Listen    => 5,
                                                Reuse     => 1,
                                               ) or die "Can't bind : $@\n";
                         }
   => from 'path' => via {
                          IO::Socket::UNIX->new(
                                                Type      => SOCK_STREAM,
                                                Local     => $_,
                                                Listen    => 5,
                                                Reuse     => 1,
                                               ) or die "Can't bind : $@\n";
                         }
;
has 'logger' => (
                 lazy    => 1,
                 is      => 'ro',
                 isa     => 'Logger',
                 coerce  => 1,
                 default => sub {threads::emulate::Logger->new(level => "warn")}
                );
has 'sock'   => (lazy => 1, is => 'rw', isa => 'Socket', coerce => 1, default => sub{shift()->create_socket});

sub create_socket {
   my $self = shift;
   require IO::Socket::UNIX;
   IO::Socket::UNIX->new(
                         Type      => SOCK_STREAM,
                         Local     => scalar tmpnam,
                         Listen    => 5,
                         Reuse     => 1,
                        ) or die "Can't bind : $@\n";
}

sub run {
   my $self = shift;
   local $SIG{USR1} = sub{$self->logger->test("just testing", "exiting"); exit};
   
   $self->logger->test("just testing", "executing run() with pid $$");
   $self->logger->info("Socket local path", $self->sock->hostpath);
   $self->logger->info("Socket listening", $self->sock->listen);
   while( my $client = $self->sock->accept() ) {
      $self->logger->debug("Dentro do while!!");
      my $str = read_line($client);
      $self->logger->debug($str);
      chomp $str;
      my ($cmd, $value) = split /:\s/, $str;
      undef $cmd unless $cmd =~ /^[A-Z_]+$/;
      my @value = split /\|/, $value if defined $value;
      my $ans;
      if(defined $cmd and $self->can($cmd)) {
         $self->logger->info("Command: $cmd(@value)");
         $ans = $self->$cmd(@value);
      } elsif(defined $cmd) {
         $self->logger->info("Commmand '$cmd' not found");
         $ans = $self->cmd_not_found($cmd);
      } else {
         $self->logger->info("No Command passed: $str");
         $ans = $self->no_cmd($str);
      }
      print ({$client} defined $ans ? $ans : "");
      #$client->free();
   }
}

sub cmd_not_found {
   my $self = shift;
   my $cmd  = shift;
   $self->logger->test("cmd not found", $cmd);
   return
}

sub no_cmd {
   my $self = shift;
   my $str  = shift;
   $self->logger->test("no cmd", $str);
   return
}

sub TESTCMD {
   my $self  = shift;
   my @value = @_;
   $self->logger->info("TESTCMD(@value)");
   $self->logger->test("just testing", "TESTCMD(@value)");
   return "TESTCMD: @value"
}

sub EXIT {
   my $self  = shift;
   $self->logger->info("exiting...");
   $self->logger->test("just testing", "exiting...");
   exit
}

sub DESTROY {
   my $self = shift;
   $self->logger->info("Destroing Server Obj");
   $self->sock->close;
}

sub read_line {
   my $sock = shift;
   local $\ = "\r\n";
   chomp(my $ans = <$sock>);
   $ans =~ s/\r\n?$//;
   $ans
}

42
