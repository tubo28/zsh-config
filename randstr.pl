#!/usr/bin/env perl
use Getopt::Long;
use Pod::Usage;

my %t = (
  a => [0..9, 'a'..'z', 'A'..'Z'],
  d => [0..9],
  g => [0..9, 'a'..'z', 'A'..'Z', split //, '!@#$%^&*()-_+=~`{}[]|\:;"<>,.?/']
);
my $p = 'X' x 16;
my $s = $t{a};

GetOptions(
  'a|alnum' => sub { $s = $t{a} },
  'd|digit' => sub { $s = $t{d} },
  'g|graph' => sub { $s = $t{g} },
  'l|length=i' => sub { $p = 'X' x $_[1] },
  'p|pattern=s' => \$p,
  'h|help' => sub { pod2usage(-verbose => 99, -sections => "USAGE") }
) or pod2usage(2);

open my $fh, '<:raw', '/dev/urandom' or die "Can't open file: $!";
$p =~ s/X/ random_char($s, $fh) /ge;
close $fh;

print "$p\n";

sub random_char {
    my ($allowed_chars, $fh) = @_;
    my $char;
    read $fh, $char, 1 while !grep { $char eq $_ } @$allowed_chars;
    return $char;
}

__END__

=head1 NAME

randstr - Generate a random string 

=head1 USAGE

./randstr.pl [options]

Options:

  -a, --alnum          Digits + Latin alphabet (default)
  -d, --digit          Digits
  -g, --graph          Digits + Latin alphabet + symbols
  -l, --length=int     Length of output (default 16)
  -p, --pattern=string Pattern. Each X is replaced with a random character. (default "XXXXXXXXXXXXXXXX")
  -h, --help           Display this help message

=cut
