package threads::emulate::Server;

use Socket::Class qw/SOMAXCONN SO_KEEPALIVE/;
use Moose;
use Moose::Util::TypeConstraints;
use threads::emulate::Logger;
use File::Temp;

use strict;
use warnings;

subtype 'Logger' => as class_type('threads::emulate::Logger');
coerce 'Logger'
   => from 'Str' => via {threads::emulate::Logger->new(level => $_)}
   => from 'Int' => via {threads::emulate::Logger->new(level => $_)}
;
subtype 'IP'   => as 'Str' => where {m/^\d{1,3}(?:\.\d{1,3}){3}(?::d+)?$/};
subtype 'path' => as 'Str' => where {m{^[/\w.-]+$}};
subtype 'Socket' => as class_type('Socket::Class');
coerce 'Socket'
   => from 'IP'   => via {
                          my($ip, $port) = split /:/, $_;
                          Socket::Class->new(
                                             "listen"   => SOMAXCONN,
                                             local_addr => $ip,
                                             local_port => $port,
                                             'domain'   => "inet",
                                            )
                         }
   => from 'Int'  => via {
                          Socket::Class->new(
                                             "listen"   => SOMAXCONN,
                                             local_port => $_,
                                             'domain'   => "inet",
                                            )
                         }
   => from 'path' => via {
                          Socket::Class->new(
                                             "listen"   => SOMAXCONN,
                                             local_path => $_,
                                             'domain'   => "unix",
                                            )
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
   Socket::Class->new(
                      'domain'     => "unix",
                      'local_path' => scalar tmpnam,
                      'listen'     => SOMAXCONN,
                     ) or die Socket::Class->error
}

sub run {
   my $self = shift;
   local $SIG{USR1} = sub{$self->logger->test("just testing", "exiting"); exit};
   
   $self->logger->test("just testing", "executing run() with pid $$");
   $self->logger->info("Socket local path", $self->sock->local_path);
   $self->logger->info("Socket listening", $self->sock->listen);
   $self->sock->set_reuseaddr(1);
   while( my $client = $self->sock->accept() ) {
      $self->logger->debug("Dentro do while!!");
      my $str = $client->readline;
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
      $client->say(defined $ans ? $ans : "");
      $client->wait(100);
      $client->free();
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
   "TESTCMD: @value"
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

42
