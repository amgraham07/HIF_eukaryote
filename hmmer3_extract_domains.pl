#!/usr/bin/perl -w
use strict;

# To use this script you need to have run HMMSEARCH or 
# HMMSCAN with this option
# --domtblout domains.out
# hmmsearch-3.0b3 --domtblout domains.out HMMFILE PROTEINFILE > PROTEIN-vs-HMMFILE.hmmsearch3
#
# hmmsearch-3.0b3 --domtblout Sugar_tr.crypto.domains.out Sugar_tr.hmm Cryptoproteins.pep > Cryptoproteins-vs-Sugar_tr.hmmsearch3

# the domtblout file is what you provide to this script!
# to run this you do
# perl hmmer3_extract_domains -i Sugar_tr.crypto.domains.out -db Cryptoproteins.pep 
# when it is done you will have a file called Sugar_tr.domains.out.Sugar_tr.domains.fa

use Getopt::Long;
use Bio::SeqIO;
use Bio::Seq;
use Bio::DB::Fasta;

my ($tablefile,$dir,$database);
my $evalue_cutoff = 1e-5;
my $cevalue_cutoff = 0.1;
my $border = 0;
$dir = '.';
GetOptions('i|input:s' => \$tablefile,
	   'db:s'      => \$database,
	   'd|dir:s'   => \$dir,
	   'e|evalue:s' => \$evalue_cutoff,
	   'c|cevalue:s' => \$cevalue_cutoff,
	   'b|border:i' => \$border,
	   );

$tablefile ||= shift @ARGV;
mkdir($dir) unless -d $dir;
my $dbh = Bio::DB::Fasta->new($database);
open(my $fh => $tablefile) || die $!;
my %seen;
while(<$fh>) {
    next if (/^\#/);
    chomp;
    my ($target,$tacc,$tlen,
	$query,$qacc,$qlen,
	$evalue,$score,$bias,
	$n, $total, $cevalue,$ievalue,
	$domscore,$dombias,
	$hmmstart, $hmmend,
	$targetstart,$targetend,
	$envstart,$envend,
	$acc, $description) = split(/\s+/,$_,23);
    next if $evalue > $evalue_cutoff;
    next if $cevalue> $cevalue_cutoff;
    my $domain = $dbh->seq($target,$envstart-$border,$envend+$border);
    push @{$seen{$query}}, Bio::Seq->new(-seq => $domain,
					 -id  => sprintf("%s.dom%d_%d",
							 $target,$n,$total),
					 -desc=> sprintf("%d..%d %s:%d..%d %s",
							 $envstart-$border,
							 $envend+$border,
							 $query,
							 $hmmstart,$hmmend,
							  $cevalue));
}
for my $q ( keys %seen ) {
    my $out = Bio::SeqIO->new(-format => 'fasta',
			      -file   => ">$dir/$tablefile.$q.domains.fa");
    $out->write_seq ( @{$seen{$q}} );
}
	
