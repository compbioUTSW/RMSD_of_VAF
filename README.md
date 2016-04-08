Description
-----------
This folder contains a script that can be used to calculate the root-mean-square deviation (RMSD) of variant-allele frequencies between two samples.  

For further questions please contact [@jiwoongbio](https://github.com/jiwoongbio).

Requirements
------------

Perl - http://www.perl.org

SAMtools - http://samtools.sourceforge.net

Example commands
----------------

```
# Generate pileup file from BAM file
samtools mpileup -q 1 -f reference.fasta input.bam | gzip > input.pileup.gz

# Calculate RMSD value from pileup file
perl pileup.rmsd.vaf.pl -d 10 input.pileup.gz > rmsd.txt
```
