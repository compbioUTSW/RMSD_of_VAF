# Author: Jiwoong Kim (jiwoongbio@gmail.com)
use strict;
use warnings;
use Getopt::Long;

GetOptions('h' => \(my $help = ''), 'd=i' => \(my $minimumDepth = 1));
if($help || scalar(@ARGV) == 0) {
	die <<EOF;

Usage:   perl pileup.rmsd.vaf.pl [options] input1.pileup|input1.pileup.gz [input2.pileup|input2.pileup.gz [...]] > rmsd.txt

Options: -h       display this help message
         -d INT   minimum read depth [1]

EOF
}
my (@pileupFileList) = @ARGV;
my ($number, @distanceMatrix) = (0);
foreach my $pileupFile (@pileupFileList) {
	open(my $reader, ($pileupFile =~ /\.gz$/) ? "gzip -dc $pileupFile |" : $pileupFile);
	LINE: while(my $line = <$reader>) {
		chomp($line);
		my $length = scalar(my @tokenList = split(/\t/, $line, -1));
		for(my $index = 3; $index < $length; $index += 3) {
			my ($readDepth, $readBases, $baseQualities) = @tokenList[$index .. $index + 2];
			next LINE if($readDepth < $minimumDepth);
		}
		my @variantBaseRatioList = ();
		for(my $index = 3; $index < $length; $index += 3) {
			my ($readDepth, $readBases, $baseQualities) = @tokenList[$index .. $index + 2];
			s/^\^.//, s/\$$// foreach(my @readBaseList = getReadBaseList($readBases));
			$readDepth = scalar(@readBaseList = grep {$_ !~ /^[><]/ && $_ ne '*'} @readBaseList);
			next LINE if($readDepth < $minimumDepth);
			push(@variantBaseRatioList, scalar(grep {$_ ne '.' && $_ ne ','} @readBaseList) / $readDepth);
		}
		$number += 1;
		foreach my $index1 (0 .. $#variantBaseRatioList) {
			foreach my $index2 (0 .. $#variantBaseRatioList) {
				if($index1 > $index2) {
					$distanceMatrix[$index1]->[$index2] += ($variantBaseRatioList[$index1] - $variantBaseRatioList[$index2])**2;
				}
			}
		}
		foreach my $index (0 .. $#variantBaseRatioList) {
			$distanceMatrix[scalar(@variantBaseRatioList)]->[$index] += $variantBaseRatioList[$index]**2;
		}
	}
	close($reader);
}
foreach my $index1 (0 .. $#distanceMatrix) {
	foreach my $index2 (0 .. $#distanceMatrix) {
		if($index1 > $index2) {
			$distanceMatrix[$index1]->[$index2] = sqrt($distanceMatrix[$index1]->[$index2] / $number);
			$distanceMatrix[$index2]->[$index1] = $distanceMatrix[$index1]->[$index2];
		}
	}
}
foreach my $index (0 .. $#distanceMatrix) {
	$distanceMatrix[$index]->[$index] = 0;
	print join("\t", @{$distanceMatrix[$index]}), "\n";
}

sub getReadBaseList {
	my ($readBases) = @_;
	my @readBaseList = ();
	while($readBases ne '') {
		my $readBase = '';
		$readBase .= $1 if($readBases =~ s/^(\^.)//);
		$readBases =~ s/^([.ACGTN>,acgtn<*])//;
		$readBase .= $1;
		if($readBases =~ s/^([+-])([0-9]+)//) {
			$readBase .= "$1$2";
			$readBases =~ s/^([ACGTNacgtn]{$2})//;
			$readBase .= $1;
		}
		$readBase .= $1 if($readBases =~ s/^(\$)//);
		push(@readBaseList, $readBase);
	}
	return @readBaseList;
}
