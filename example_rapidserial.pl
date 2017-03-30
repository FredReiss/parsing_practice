#!/usr/bin/perl 

#$fileinput = shift(@ARGV);

#if (length($fileinput) == 0) {
#   die "** Usage: hathisomething.pl filename\n";
#}

use XML::LibXML;

open(OUTFILE,">oku_rapid_printserials.xml");
open(OUTFILE2,">noOCLC_serial.txt");
binmode OUTFILE, ":utf8";
#in this example, I know I have 10 XML files named "hathi_serial_[1-10].xml", and that I want to go through all the files to get data
for ($i=1;$i<11;$i++) {
 $fileinput = "hathi_serial_2016100714_8827194050002042_new_" . $i . ".xml";
 my $parser = XML::LibXML->new();
 my $doc = $parser->parse_file($fileinput);

 foreach my $record ($doc->findnodes('/collection/record')) {
   $oclcCounter = 0;
   foreach my $controlfield ($record->findnodes('./controlfield')) {
      my $ctag = $controlfield->findvalue('@tag');
      if ($ctag eq "001"){
         $mmsID = $controlfield->to_literal;
      }
   }
   #initializing variables to ensure no errant carryover of values
   $oclcNum = "";
   $issn = "";
   $libraryName = "";
   $callnumHolding = "";
   $lawFlag = 0;
   $lawCounter = 0;
   $issnCounter = 0;
   $holdingCounter = 0;
   $holdOutput = "";
   $recOutput = "<item type=\"physical\">\n  <Local_Key>" . $mmsID . "</Local_Key>\n";
   foreach my $marcTag ($record->findnodes('./datafield')) {
     my $dtag = $marcTag->findvalue('@tag');
     if ($dtag eq "022"){
       foreach my $marcSubfield ($marcTag->findnodes('./subfield')) {
         my $subfieldCode = $marcSubfield->findvalue('@code');
         if ($subfieldCode eq "a") {
           $dtagval = $marcSubfield->to_literal;
           $issn = $dtagval;
           $issnCounter = 1;
           $recOutput = $recOutput . "  <ISSN>" . $issn . "</ISSN>\n";
         }
       }
     } 
     if ($dtag eq "035"){
       foreach my $marcSubfield ($marcTag->findnodes('./subfield')) {
         my $subfieldCode = $marcSubfield->findvalue('@code');
         if ($subfieldCode eq "a") {
           $dtagval = $marcSubfield->to_literal;
           if ($dtagval =~ /(OCoLC)/)  {
             $oclcNum = $dtagval;
             $oclcCounter = 1;
             $recOutput = $recOutput . "  <OCLC>" . $oclcNum . "</OCLC>\n";
           }
         }
       }
     }
     if (($dtag eq "050") || ($dtag eq "090") || ($dtag eq "099")) {
       $callnum = "";
       foreach my $marcSubfield ($marcTag->findnodes('./subfield')) {
         my $subfieldCode = $marcSubfield->findvalue('@code');
         if ($subfieldCode eq "a") {
             $dtagval = $marcSubfield->to_literal;
             $callnum = $callnum . $dtagval . " ";
         }
         if ($subfieldCode eq "b") {
             $dtagval = $marcSubfield->to_literal;
             $callnum = $callnum . $dtagval . " ";
         }
       }
       $recOutput = $recOutput . "  <call_number>" . $callnum . "</call_number>\n";
     }

     if ($dtag eq "245") {
       foreach my $marcSubfield ($marcTag->findnodes('./subfield')) {
         my $subfieldCode = $marcSubfield->findvalue('@code');
         if ($subfieldCode eq "a") {
             $dtagval = $marcSubfield->to_literal;
             $title = $dtagval;
         }
         if (($subfieldCode eq "b") || ($subfieldCode eq "c") || ($subfieldCode eq "n") || ($subfieldCode eq "p")) {
             $dtagval = $marcSubfield->to_literal;
             $title = $title . " " . $dtagval;
         }
       }
       $recOutput = $recOutput . "  <title>$title</title>\n";
     }
     if ($dtag eq "852"){
        if ($holdingCounter > 0) {
           $holdOutput = $holdOutput . "  </holdings>\n";
           $holdingCounter = 0;
        }
        foreach my $marcSubfield ($marcTag->findnodes('./subfield')) {
          my $subfieldCode = $marcSubfield->findvalue('@code');
          if ($subfieldCode eq "b") {
            $dtagval = $marcSubfield->to_literal;
            if (($dtagval =~ /LAW/) || ($dtagval =~ /HISTSCI/)){
              $lawCounter = 1;
            } else {
              $holdingCounter = 1;
              $libraryName = $dtagval;
            }
          }
          if (($subfieldCode eq "c") && ($holdingCounter == 1)) {
            $dtagval = $marcSubfield->to_literal;
            if (($dtagval =~ /DISCARD/) || ($dtagval =~ /LOST/)) {
              $holdingCounter = 0;
            } else {
              $holdOutput = $holdOutput . "  <holdings location=\"$libraryName $dtagval\">\n";
            }
          }
          if (($subfieldCode eq "h") && ($holdingCounter == 1)) {
            $callnumHolding = $marcSubfield->to_literal;                            
          } 
        }
     }
     #add subroutine to get 863 specific data if holdingcounter is 1
     #add subroutine to get 866 general data if holdingcounter is 1
     if (($dtag eq "863") && ($holdingCounter == 1)) {
       $holdOutput = $holdOutput . "     <specific>\n";
       foreach my $marcSubfield ($marcTag->findnodes('./subfield')) {
          my $subfieldCode = $marcSubfield->findvalue('@code');              
          if ($subfieldCode eq "a") {
            $dtagval = $marcSubfield->to_literal;
            $holdOutput = $holdOutput . "      <vol>$dtagval</vol>\n";
          }
          if ($subfieldCode eq "b") {
            $dtagval = $marcSubfield->to_literal;
            $holdOutput = $holdOutput . "      <num>$dtagval</num>\n";
          }
          if ($subfieldCode eq "j") {
            $dtagval = $marcSubfield->to_literal;
            $holdOutput = $holdOutput . "      <month>$dtagval</month>\n";
          }
          if ($subfieldCode eq "i") {
            $dtagval = $marcSubfield->to_literal;
            $holdOutput = $holdOutput . "      <year>$dtagval</year>\n";
          }
       }
       $holdOutput = $holdOutput . "     </specific>\n";
     }
     if (($dtag eq "866") && ($holdingCounter == 1)){
       foreach my $marcSubfield ($marcTag->findnodes('./subfield')) {
          my $subfieldCode = $marcSubfield->findvalue('@code');
          if ($subfieldCode eq "a") {
            $dtagval = $marcSubfield->to_literal;
            $holdOutput = $holdOutput . "    <general>$dtagval</general>\n";
          }
       }
     }
   }
   if ((($oclcCounter > 0) || ($issn ne "")) && ($holdOutput ne "")) {
      print OUTFILE $recOutput . $holdOutput;
      if ($holdingCounter == 1) {
        print OUTFILE "  </holdings>\n</item>\n";
      } else {
        print OUTFILE "  </item>\n";
      }
   } else {
      print OUTFILE2 $recOutput . $holdOutput . "  </item>\n";
   }
 }
}

close(OUTFILE);
close(OUTFILE2);

