package threads::emulate::Logger;

use Moose;
use Moose::Util::TypeConstraints;

our $single;
our %levels = (
               "debug"        => 5,
               "info"         => 4,
               "warn"         => 3,
               "error"        => 2,
               "fatal"        => 1,
              );

for my $level (keys %levels){
   eval qq|
           sub $level {
              my \$self = shift;
              return \$self->log(uc "[$level]", \@_) if $levels{$level} <= \$self->level;
              return
           }
          |;
   die $@ if $@;
   eval qq|
           sub ${level}_die {
              my \$self = shift;
              if($levels{$level} <= \$self->level){
                 \$self->log(uc "[$level]", \@_);
                 die "\@_";
              }
           }
          |;
   die $@ if $@;
}

subtype 'LogLevel'
   => as 'Int'
   => where { $_ >= 0 }
;
coerce 'LogLevel' 
   => from 'Str' => via {$levels{$_}}
;
has level    => (is => 'rw', isa => 'LogLevel', default => 0, coerce => 1);
has logFile  => (is => 'rw', isa => 'Str', default => undef);
has testFile => (is => 'rw', isa => 'Str', default => undef);
has testName => (is => 'rw', isa => 'Str', default => undef);

override new => sub {
   my $self = shift;
   my %par = @_;
   if(not defined $single){
      $single = super($self, %par);
   } else {
      $single->$_($par{$_}) for keys %par;
   }
   $single;
};
sub log {
   my $self = shift;
   my $ret;
   if($self->logFile){
      open my $LOGFILE, ">>", $self->logFile;
      $ret = print {$LOGFILE} scalar(localtime time), ": @_$/";
      close $LOGFILE;
   } else {
      $ret = print {*STDERR} scalar(localtime time), ": @_$/";
   }
   $ret
}

sub test {
   my $self     = shift;
   my $testName = shift;
   return unless $self->level >= 100 and defined $self->testName and $self->testName eq $testName;
   $self->debug("Runing test", $testName);
   my $ret;
   if(defined $self->testFile){
      open my $LOGFILE, ">>", $self->testFile;
      $ret = print {$LOGFILE} "@_$/";
      close $LOGFILE;
   } else {
      $ret = print {*STDERR} "@_$/";
   }
   $ret
}

42
