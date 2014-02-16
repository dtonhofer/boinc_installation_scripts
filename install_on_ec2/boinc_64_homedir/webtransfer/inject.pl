#!/usr/bin/perl -w

use HTML::Entities;

$templateFile = $ARGV[0];
$dataFile     = $ARGV[1];
$headerText   = $ARGV[2];

die "Template not given"    unless $templateFile;
die "Data file not given"   unless $dataFile;
die "Header text not given" unless $headerText;

open(TEMPLATE,"<$templateFile") or die "Could not open template file '$templateFile': $!\n";
@template = <TEMPLATE>;
close(TEMPLATE);

open(DATA,"<$dataFile") or die "Could not open data file '$dataFile': $!\n";
@data = <DATA>;
close(DATA);

$safeHeaderText = encode_entities($headerText);

foreach $line (@template) {
   if ($line =~ /^(.*?)<!-- HEADER -->(.*)$/) {
      print "${1}<h1>${safeHeaderText}</h1>${2}\n";
   }
   elsif ($line =~ /^(.*?)<!-- DATA -->(.*)$/) {
      print "${1}\n<pre>\n";
      foreach $dataline (@data) {
         print encode_entities($dataline);
      }
      print "</pre>\n${2}";
   }
   else {
      print $line;
   }
}

