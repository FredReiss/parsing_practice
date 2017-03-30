#!/usr/bin/perl 

$fileinput = shift(@ARGV);

if (length($fileinput) == 0) {
   die "** Usage: scriptname.pl filename\n";
}

use XML::LibXML;

open(OUTFILE,">test_output.tsv");

my $parser = XML::LibXML->new();
my $doc = $parser->parse_file($fileinput);
#in this scenario, we assume the file input contains XML with a structure of collection > record, and that the contents are MARC XML
#for output, I want the MMS ID (found in the 001 controlfield) and the title/subtitle (in the 245 datafield within subfields a & b ) 
foreach my $record ($doc->findnodes('/collection/record')) {
   foreach my $controlfield ($record->findnodes('./controlfield')) {
      my $ctag = $controlfield->findvalue('@tag');
      if ($ctag eq "001"){
         $mmsID = $controlfield->to_literal;
      }
   }
   #here, I'm initializing a flag variable for a future variable test
   $ddaFlag = 0;
   foreach my $marcTag ($record->findnodes('./datafield')) {
     my $dtag = $marcTag->findvalue('@tag');
     if ($dtag eq "245") {
       foreach my $marcSubfield ($marcTag->findnodes('./subfield')) {
          my $subfieldCode = $marcSubfield->findvalue('@code');              
          if ($subfieldCode eq "a") {
            $dtagval = $marcSubfield->to_literal;
            $title = $dtagval;
          }
          if ($subfieldCode eq "b") {                                        
            $dtagval = $marcSubfield->to_literal;
            $title = $title . " " . $dtagval;
          }
       }
	 }
     #I also want to test the 856 tag to see if it was an ebrary dda (that value is in the 856$x)
     if ($dtag eq "856") {
       foreach my $marcSubfield ($marcTag->findnodes('./subfield')) {
          my $subfieldCode = $marcSubfield->findvalue('@code');              
          if ($subfieldCode eq "x") {                                        
            $dtagval = $marcSubfield->to_literal;
            if ($dtagval =~ /ebrary dda/i) {
              $ddaFlag = 1;
            } 
          }
       }
     }
   }
   #if the ddaflag value increased from 0, then we print the data
   if ($ddaFlag > 0) {
     print OUTFILE "$mmsID\t$title\n";
   }
   
 }

close(OUTFILE);
