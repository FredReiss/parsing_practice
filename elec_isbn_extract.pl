#!/usr/bin/perl 

use XML::LibXML;

open(OUTFILE,">print_isbns.txt");
binmode OUTFILE, ":utf8";

#will be working with a pile of XML files with filename of oku_ldphys_new_{somenum}.xml
for ($i=1;$i<501;$i++) {
 $fileinput = "oku_ldphys_new_" . $i . ".xml";
 my $parser = XML::LibXML->new();
 if (-e $fileinput) {
  my $doc = $parser->parse_file($fileinput);

  foreach my $record ($doc->findnodes('/collection/record')) {
   foreach my $controlfield ($record->findnodes('./controlfield')) {
      my $ctag = $controlfield->findvalue('@tag');
      if ($ctag eq "001"){
         $mmsID = $controlfield->to_literal;
      }
   }
   $isbn = "";
   $libraryName = "";
   $badFlag = 0;
   $isbnFlag = 0;
   $libFlag = 0;
   $holdingFlag = 0;
   $recOutput = "";
   
   foreach my $marcTag ($record->findnodes('./datafield')) {
     my $dtag = $marcTag->findvalue('@tag');
     if ($dtag eq "020"){
       foreach my $marcSubfield ($marcTag->findnodes('./subfield')) {
         my $subfieldCode = $marcSubfield->findvalue('@code');
         if ($subfieldCode eq "a") {
           $dtagval = $marcSubfield->to_literal;
           $isbn = $dtagval;
           $isbn =~ s/-//g;
           $isbn =~ s/^\s+//;
           #some odd data exists in these fields, so will try splitti
           if ($isbn =~ /^\d/) {
             $isbn =~ s/[(.:;]/\s/g;
             if ($isbn =~ /\s/) {
               @isbnArray = split /\s/, $isbn;
               $isbn = $isbnArray[0];
             }
             if (length($isbn) == 10){
               $isbnFlag = 1;
               $recOutput = $recOutput . convISBN10toISBN13($isbn) . "\n";
             } elsif (length($isbn) == 13){
               $isbnFlag = 1;
               $recOutput = $recOutput . $isbn . "\n";
             }
             #need to add an ISBN check at some point to validate inbound 13-digit ISBNs 
           }
         }
       }
     }
     

     if (($dtag eq "852") && ($isbnFlag == 1)){
        foreach my $marcSubfield ($marcTag->findnodes('./subfield')) {
          my $subfieldCode = $marcSubfield->findvalue('@code');
          if ($subfieldCode eq "b") {
            $dtagval = $marcSubfield->to_literal;
            if (($dtagval =~ /SAMNOBLEMUSEUM/) || ($dtagval =~ /OTL/) || ($dtagval =~ /AOI/) || ($dtagval =~ /NWC/) || ($dtagval =~ /Dance/)){
              $libFlag = 0;
            } else {
              $libFlag = 1;
              $libraryName = $dtagval;
            }
          }
          if (($subfieldCode eq "c") && ($libFlag == 1)) {
            $dtagval = $marcSubfield->to_literal;
            if (($dtagval =~ /DISCARD/) || ($dtagval =~ /PDDA/)) {
              $badFlag = 1;
            } else {
              $holdingFlag = 1;
            }
          } 
        }
     }
   }
   if (($isbnFlag == 1) && ($holdingFlag == 1)) {
      print OUTFILE $recOutput;
   }
  }
 }
}

close(OUTFILE);

sub convISBN10toISBN13{
  my $input = shift;
  chomp($input);
  if ($input =~ /^(\d{9})(\d|[Xx])$/i){
    $input =~ s/(\d|[xX])$//i;
    $input = "978" . $input;

    my @splitInput = split(//, $input);

    my $sum = 0;

    for (my $i = 0; $i < scalar(@splitInput); $i++){
      my $multiplier = $i % 2 == 0 ? 1 : 3;
      $sum += $splitInput[$i] * $multiplier; 
    }
    my $checkDigit = 10 - ($sum % 10);
    if ($checkDigit == 10) {
      $checkDigit = 0;
    } 
    return $input . $checkDigit;
  }
  else{
    # bad pattern, so give back what you got 
    return $input;
  }
}
