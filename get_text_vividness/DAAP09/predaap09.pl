=cut
This is the predaap09.pl for use wiwth DAAP09.6.pl, the current Discourse Attributes Analysis Program for use with
multiple speakers.

Copyright (C) 2014 Bernard Maskit, Wilma Bucci and Sean Murphy


This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see http://www.gnu.org/licenses/.
    
    Contact Information:    Bernard Maskit: daap@optonline.net
                            Wilma Bucci: wbucci@optonline.net
                            Sean Murphy: smurphy1@gmail.com

=cut
use strict;
#use warnings;
my $MTTNum = 50; #This sets the interval for markers in the Marked text.

my @ListL10 = qw/i you we they/; #Used for like: if preceding in list 1, and subsequent not equal to preceding, then likev
my @ListL8; #verbs in separate file; if preceding like, then likec; also if prepreceding like, and preceding not in List19; also likec to like if following likec
my @ListW2; #verbs in separate file; if preceding well, then wella;
my @ListL9 = qw/get/; #used for like
my @ListL14 = qw/this that/; #for use with list 25 concerning like
my @ListY1 = qw/this that what who where when which how/; #succeeds you know as opposed to youknow
my @ListL4 = qw/how that what/; #used for like
my @ListW1 = qw/awfully feeling into really definitely particularly very somewhat doing quite perfectly/; #makes wella if preceding well
my @ListY2 = qw/should would can shall will do if/; #if precedes you know, then stet
my @ListK2 = qw/likex ah mm uhm um er hm hmm youknow welld/;#If preceding well, changes to welld, if following form of like, change to like; also kind
my @ListL6 = qw/can shouldn shan wouldn don didn won/; # if precedes t before form of like, change to likev
my @ListL5 = qw/would should could shall will can do does d ll/; #if before like, change to  likev
my @ListW3 = qw/in on by and near far to of now before then think say said says well welld like liked/; #if precedes well, change to welld
my @ListW5 = qw/i we if and or but well why where who what how/; # if follows well, change to welld 
my @ListL7 = qw/can could do might should would will/;# if followed by not and then like, change like to likev
my @ListL12 = qw/i it he she you they/; #used for like
my @ListL11;# if like is followed by to: if preceded by list21, then likec, otherwise likev
my @ListK1 = qw/some any this that/; #of List23 kind
my @ListL15 = qw/found saw heard/; # For like, used with list 3
my @ListL2; #MM words used for like
my @ListL3 = qw/act acted acting acts/; # if follows likec then like
my @ListL1 = qw/feel feeling feels felt look looked looking looks seem seemed seeming seems sound sounded sounding sounds/; #used for like
my @ListL13 = qw/her him i me them us/; #used for like
my @ListH1 = qw/um-hmm uh-huh uh-oh ah-ha un-hum mm-hmm/;#used for hyphenation
my @ListH2 = qw/anti co ex mid non pro re self/;#used for hyphenation
my @ListM1 = qw/aah ah ahh eh ehm hm hmm hmmm mmm uh uhh uhhh uhm uhmm um umm ummm unh/; #to be replaced by mm
open (ListL8,"ListL8.txt") or die ("Can't read ListL8\n"); 
while (<ListL8>){
    chomp;
    push @ListL8,$_;
}
open (ListW2,"ListW2.txt") or die ("Can't read ListW2a\n");
while (<ListW2>){
    chomp;
    push @ListW2,$_;
}
open (ListL11,"ListL11.txt") or die ("Can't read ListL11\n");
while (<ListL11>){
    chomp;
    push @ListL11,$_;
}
open (ListL2,"ListL2.txt") or die ("Can't read ListL2\n");
while (<ListL2>){
    chomp;
    push @ListL2,$_;
}


sub MPrep{
    my $Word = $_[0];
    if($Word =~ /(.*)▓(.*)/){
        $Word = "$1.\'.$2";
    }
    if($Word =~/\bwellc\b/ || $Word =~ /\bwella\b/){
        $Word = "well";
    }elsif($Word =~/\bwelld\b/ || $Word =~ /\bwellw\b/){
        $Word = "well";
    }elsif($Word =~ /\blikec\b/ || $Word =~ /\blikev\b/){
        $Word = "like";
    }elsif($Word =~ /\bkindf\b/){
        $Word = "kind";
    }elsif($Word =~ /\bmeanf\b/){
        $Word = "mean";
    }
    if($Word =~ /\bkindas\b/){
        $Word = "kind\@of";
    }
    if($Word =~ /\byouknow\b/){
        $Word = "you\@know";
    }    
    if($Word =~ /\bimean\b/){
        $Word = "I\@mean";
    }
    
    return $Word;
}
sub Process1{ #to .c file for daap processing
    my $LocLogWarn = 0;
    my $Stream1 = $_[0];
    my $GWordN = $_[1];
    my @Prelim;
    
    my @PSplit = split /([\(\)\[\]])/,$Stream1;
    my @ParenStuff;
    my @ParensN;
    my @ParenHold;
    my $LocParen;
    my $NWordN = 0;
    my $Paren = 0;
    my @NS;
    my $ParenCheck = 0;
    my $LocWordN = 0;
    for my $j(0..$#PSplit){
        
        if($PSplit[$j] eq '(' || $PSplit[$j] eq '['){
            if($ParenCheck == 0){
                for my $q(0..$#ParenHold){
                    pop @ParenHold;
                }
            }
            $Paren++;
            push @ParenHold,$PSplit[$j];
            $ParenCheck++;
        }elsif($PSplit[$j] eq ')' or $PSplit[$j] eq ']'){
            $Paren--;
            
            push @ParenHold,$PSplit[$j];
            $ParenCheck--;
            if($ParenCheck == 0){
               $LocParen = join "",@ParenHold;
                push @ParenStuff,$LocParen;
                my $Marker = "parenth$#ParenStuff";
            }

        }
        if($Paren > 0){
            push @ParenHold,$PSplit[$j];

        }elsif($Paren < 0){
            my @FinList = (0,"ERROR1");
            return @FinList; 
        }elsif($Paren == 0){
            my @Words = split /\s+/,$PSplit[$j];
            for my $k(0..$#Words){
                if($Words[$k] =~ /\w+/){
                    push @Prelim,$Words[$k];
                }
            }
        }
    }
    
    for my $i(0..$#Prelim){
        $Prelim[$i] =lc $Prelim[$i];
        if($Prelim[$i] =~ /(.*)▓(.*)/){
            $Prelim[$i] = "$1.\'.$2";
        }
        if($Prelim[$i] =~ /^o'clock(.*)/){
            $Prelim[$i] = "oclock$1";
        }
        if($Prelim[$i] =~/^'em(.*)/){
            $Prelim[$i] = "them";
        }

        if($Prelim[$i] =~ /^\d+'s$/){
            $Prelim[$i] = "nums";
        }
    }

    for my $i(0..$#Prelim){
        if($Prelim[$i] =~ /(.*)-{2,5}(\w+)(.*)/){
            print LogFile "Removed hyphens from $Prelim[$i]\n";
            $LocLogWarn++;
            my $Begin = $1;
            my $End = $2.$3;
            if($Begin =~ /\w+/){
                my @Temp;
                for my $q($i + 1..$#Prelim){
                    push @Temp,$Prelim[$q];
                }
                $Prelim[$i] = $Begin;
                $Prelim[$i + 1] = $End;
                print LogFile "Prelim[$i] changed to $Prelim[$i] $Prelim[$i + 1]\n";
                for my $q(0..$#Temp){
                    $Prelim[$i + 2 + $q] = $Temp[$q];
                }    
            }else{
                $Prelim[$i] = $End;
            }
        }

        my $Hyph = 0;
        if($Prelim[$i] =~ /\w+-\w+/){
            $Hyph++;
            
            
            while ($Hyph > 0){
                
                if($Prelim[$i] =~ /(.*)(\w+)-(\w+)(.*)/){
                    $Prelim[$i] = "$1$2_$3$4";
                    
                    if($Prelim[$i] =~ /-\w+/){
                        
                        $Hyph++;
                    }else{
                        $Hyph = 0;
                     }
                }
            }
        }
  
       
        if($Prelim[$i] =~ /(.*)(\w+)я(\w+)(.*)/){
            print LogFile "Removed mdash from $Prelim[$i]\n";
            $LocLogWarn++;
            my @Temp;
            for my $j($i + 1..$#Prelim){
                push @Temp,$Prelim[$j];
            }
            $Prelim[$i] = $1.$2;
            $Prelim[$i + 1] = $3.$4;
            for my $k($i + 2..2+$i+$#Temp){
                $Prelim[$k] = $Temp[$k - $i - 2];
            }
        }
        
        if($Prelim[$i] =~/(.*)(\w+)_{1,}(\w+)(.*)/){
            if($3 != "m"){
                if($2 != "a" && $2 != "p"){
                    my $NewWord = $1.$2.$3.$4;
                    $Prelim[$i] = $NewWord;
                }
            }
        }elsif($Prelim[$i] =~ /(.*)(\w+)_\W/){
            my $NewWord = $1.$2;
            print LogFile "1. $Prelim[$i] changed to $NewWord\n";
            $Prelim[$i] = $NewWord;
        }                 
    }

    

    my @Sents;
    
    my $BigSent = join "@",@Prelim;
    @Sents = split /([\.,\ср"р"'у`;:\?])/,$BigSent;
    my @SentsC;
    my @SentsM;     
    for my $i(0..$#Sents){
        if($Sents[$i] =~ /\w/){
            if($Sents[$i] =~ /^@(.*)$/){
                $Sents[$i] = $1;
            }

            my @Words1 = split "@",$Sents[$i];
            for my $j(0..$#Words1){
                $Words1[$j] = lc ($Words1[$j]);
 
            }
            for my $j(0..$#Words1){
                if($Words1[$j] =~ /^[!\*\+]?(\w+)[!\*\+]?$/){
                    $Words1[$j] = $1;
                }
            }
            
            for my $j(0..$#Words1){
          
                if($Words1[$j] =~ /\b1\b/){
                    $Words1[$j] = "one";
                }
                if($Words1[$j] =~ /\b2\b/){
                    $Words1[$j] = "two";
                }
                if($Words1[$j] =~ /\b3\b/){
                    $Words1[$j] = "three";
                }
                if($Words1[$j] =~ /\b4\b/){
                    $Words1[$j] = "four";
                }
                if($Words1[$j] =~ /\b5\b/){
                    $Words1[$j] = "five";
                }
                if($Words1[$j] =~ /\b6\b/){
                    $Words1[$j] = "six";
                }
                if($Words1[$j] =~ /\b7\b/){
                    $Words1[$j] = "seven";
                }
                if($Words1[$j] =~ /\b8\b/){
                    $Words1[$j] = "eight";
                }
                if($Words1[$j] =~ /\b9\b/){
                    $Words1[$j] = "nine";
                }
                if($Words1[$j] =~ /\b10\b/){
                    $Words1[$j] = "ten";
                }

                if($Words1[$j] =~ /\b\d+s\b/){
                    $Words1[$j] = "nums";
                }
                if($Words1[$j] =~ /\b\d+\b/){
                    $Words1[$j] = "num";
                }
                if($Words1[$j] =~/\b\d+:\d+\b/){
                    $Words1[$j] = "num";
                }
                if($Words1[$j] =~ /\bok\b/){
                    $Words1[$j] = "okay";
                }
            }
            for my $m(0..$#Words1){
                for my $j(0..$#ListM1){
                    if($Words1[$m] eq $ListM1[$j]){
                        $Words1[$m] = "mm";
                    }
                }
            }
            for my $m(0..$#Words1){
                if($Words1[$m] =~ /\bkindaff\b/){
                    $Words1[$m] = "kind";
                }
                if($Words1[$m] =~ /\bknowd\b/){
                    $Words1[$m] = "know";
                }
                if($Words1[$m] =~ /\blikec\b/){
                    $Words1[$m] = "like";
                }
                if($Words1[$m] =~ /\blikev\b/){
                    $Words1[$m] = "like";
                }
                if($Words1[$m] =~/\bmeanaff\b/){
                    $Words1[$m] = "mean";
                }
                if($Words1[$m] =~ /\bwella\b/){
                    $Words1[$m] = "well";
                }
                if($Words1[$m] =~ /\bwellc\b/){
                    $Words1[$m] = "well";
                }
            }
            if($Words1[0] =~ /\blike\b/){
                $Words1[0] = "likex";
            }

            if($Words1[0] =~ /\byou\b/ && $Words1[1] =~ /\bknow\b/){
                if($#Words1 == 1){
                    $Words1[0] = "you";
                    $Words1[1] = "knowD";
                    
                }elsif($#Words1 > 1){
                    my $Hit = 0;
                    for my $m(0..$#ListY1){
                        if ($Words1[2] eq $ListY1[$m]){
                            $Hit++;
                            last;
                        }
                    }
                    if($Hit == 0){
                        $Words1[0] = "you";
                        $Words1[1] = "knowD";
                        
                    }
                }
            }

            for my $k(0..$#Words1){
                if($Words1[$k] =~ /\bkind\b/){
                    if($Words1[$k + 1] =~ /\bof\b/){
                    }else{
                        my $Hit = 0;
                        for my $q(0..$#ListK1){
                            if($Words1[$k - 1]  eq $ListK1[$q]){
                                $Hit++;
                                last;
                            }
                        }
                        if($Hit > 0){
                            if ($Words1[$k - 2] =~ /\bof\b/){
                                $Words1[$k] = "kind";
                            }else{
                                $Words1[$k] = "kindf";
                            }
                        }
                    }
                }
            }

            for my $k(0..$#Words1){
                 if($Words1[$k] =~ /\bmean\b/ && $Words1[$k - 1] =~ /\bi\b/){
                    $Words1[$k - 1] = "i";
                    $Words1[$k] = "mean";
                    
                }
            }

            for my $k(0..$#Words1){
                if($Words1[$k] =~ /\blike\b/){ 
                    for my $q(0..$#ListL1){ 
                        if($Words1[$k - 1] eq $ListL1[$q]){
                            $Words1[$k] = "likec";
                            last;
                        }
                    }
                }
               
                if($Words1[$k] =~ /\blike\b/){
                    if($k == $#Words1 && $#Words1 < 6){
                        $Words1[$k] = "likex";
                    }
                }
                
                if($Words1[$k] =~ /\blike\b/){
                    for my $q(0..$#ListL2){
                        if($Words1[$k - 1] eq $ListL2[$q]){
                            $Words1[$k] = "likex";
                            last;
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/ && $Words1[$k - 1] =~ /\bwas\b/){
                    $Words1[$k] = "likex";
                }
                if($Words1[$k] =~ /\blike\b/ && $Words1[$k - 1] =~ /\bis\b/){
                    $Words1[$k] = "likex";
                }
                if($Words1[$k] =~ /\blike\b/ && $Words1[$k - 1] =~ /\bs\b/){
                    $Words1[$k] = "likex";
                }
                if($Words1[$k] =~ /\blike\b/ && $Words1[$k - 1] =~ /\bnot\b/ && $Words1[$k - 2] =~ /\bs\b/){
                    $Words1[$k] = "likex";
                }
                if($Words1[$k] =~ /\blike\b/){
                    if($Words1[$k + 1] =~ /\bi\b/){
                        for my  $q(0..$#ListL3){
                            if($Words1[$k - 1] eq $ListL3[$q]){  
                                $Words1[$k] = "likec";
                                last;
                            }
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/){
                    for my $q(0..$#ListL1){
                        if($Words1[$k + 1] eq $ListL1[$q]){
                            $Words1[$k] = "likex";
                            last;
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/ && $Words1[$k + 1] =~ /\bi\b/ && $Words1[$k + 2] =~ /\bdon\b/){
                    $Words1[$k] = "likex";
                }
                if($Words1[$k] =~ /\blike\b/ && $Words1[$k + 1] =~ /\byou/){
                    $Words1[$k] = "likex";
                }

                if($Words1[$k] =~ /\blike\b/){
                    if($Words1[$k - 1] =~ /\bs\b/ && $Words1[$k - 2] =~ /\bit\b/){
                        my $Hit = 0;
                        for my $q(0..$#ListL4){
                            if($Words1[$k - 3] eq $ListL4[$q]){ 
                                $Words1[$k] = "likec";
                                $Hit++;
                                last;
                            }
                            if($Hit == 0){ 
                               $Words1[$k] = "likex"; 
                            }
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/){
                    for my $m(0..$#ListL5){ 
                        if($Words1[$k - 1] eq $ListL5[$m]){  
                            $Words1[$k] = "likev"; 
                            last;
                        }    
                    }
                }
                
                if($Words1[$k] =~ /\blike\b/){
                    if($Words1[$k - 1] =~ /\bt\b/){
                        for my $m(0..$#ListL6){
                            if($Words1[$k - 2] eq $ListL6[$m]){
                                $Words1[$k] = "likev";
                                last;
                            }
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/){
                    if($Words1[$k - 1] =~ /\bnot\b/){
                        my $Hit = 0;
                        for my $m(0..$#ListL7){
                            if($Words1[$k - 2] eq $ListL7[$m]){
                                $Words1[$k] = "likev";
                                $Hit++;
                                last;
                            }
                        }

                    }
                }
                
                if($Words1[$k] =~ /\blike\b/){
                    for my $m(0..$#ListL8){
                        if($Words1[$k - 1] eq $ListL8[$m]){
                            my $Hit = 0;
                            for my $q(0..$#ListL9){
                                if($Words1[$k - 1] eq $ListL9[$q]){
                                    for my $r(0..$#ListL10){
                                        if($Words1[$k + 1] eq $ListL10[$r]){
                                            $Words1[$k] = "likex";
                                            $Hit++;
                                        }
                                    }
                                }
                            }

                            if($Hit == 0){
                                $Words1[$k] = "likec";
                            }
                            last;
                        }
                    }
                }

                if($Words1[$k] =~ /\blike\b/ && $Words1[$k - 1] =~ /\bto\b/){
                    for my $q(0..$#ListL8){
                        if ($Words1[$k + 1] eq $ListL8[$q]){
                            $Words1[$k] = "likex";
                            last
                        }
                    }
                }

                if($Words1[$k] =~ /\blike\b/){
                    if($k < $#Words1 - 1 && $Words1[$k + 1] =~ /\bto\b/){
                        my $Hit = 0;
                        for my $m(0..$#ListL11){
                            if($Words1[$k - 1] eq $ListL11[$m]){
                                $Hit++;
                                last;
                            } 
                        }
                        if($Hit == 0){
                            $Words1[$k] = "likev";
                        }else{
                            $Words1[$k] = "likec";
                        }
                    }
                }

                if($Words1[$k] =~ /\blike\b/){
                    if($k > 0 && $k < $#Words1){
                        for my $m(0..$#ListL10){
                            if($Words1[$k - 1] eq $ListL10[$m] && $Words1[$k - 1] ne $Words1[$k + 1]){ 
                                $Words1[$k] = "likev";
                                last;
                            }
                        }
                    }
                }
                
                if($Words1[$k] =~ /\blike\b/){
                    if($k > 0 && $k < $#Words1){
                        for my $m(0..$#ListL12){   
                            if($Words1[$k + 1] eq $ListL12[$m]){ 
                                $Words1[$k] = "likec";
                                last;
                            }
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/){
                    for my $m(0..$#ListL13){   
                        if($Words1[$k + 1] eq $ListL13[$m]){
                            $Words1[$k] = "likev";
                            last;
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/){
                    if($k > 0 && $k < $#Words1){
                        for my$m(0..$#ListL14){
                            if($Words1[$k + 1] eq $ListL14[$m]){
                                my $Hit1 = 0;
                                for my $q(0..$#ListL15){
                                    if($Words1[$k - 1] eq $ListL15[$q]){
                                        $Hit1++;
                                        last;
                                    }
                                }
                                if($Hit1 == 0){
                                    $Words1[$k] = "likec";
                                    last;
                                }else{
                                    $Words1[$k] = "likex";
                                }
                            }
                        }
                    }
                }
            }

            for my $k(0..$#Words1){
                if($Words1[$k] =~ /\bknow\b/ && $Words1[$k - 1] =~ /\byou\b/){
                    my $Hit = 0;
                    for my $m(0..$#ListY1){
                        if($Words1[$k + 1] eq $ListY1[$m]){
                            $Hit++;
                            last;
                        }
                    }
                    for my $m(0..$#ListY2){
                        if($Words1[$k - 2] eq $ListY2[$m]){
                            $Hit++;
                            last;
                        }
                    }
                    if($Hit == 0){
                        $Words1[$k - 1] = "you";
                        $Words1[$k] = "know";
                        
                    }
                }
            }

            for my $x(0..$#Words1){

                if($Words1[$x] =~ /\bwell\b/ && $Words1[$x - 1] =~ /\bas\b/){
                    $Words1[$x] = "wellc";
                    next;
                }
            }
            for my $x(0..$#Words1){

                
                if($Words1[$x] =~ /\bwell\b/){
                    my $Hit = 0;
                    for my $m(0..$#ListW1){
                        if($Words1[$x - 1] eq $ListW1[$m]){
                            $Hit++;
                            last;
                        }
                    }
                    for my $q(0..$#ListW2){
                        if($Words1[$x - 1] eq $ListW2[$q]){
                            $Hit++;
                            last;
                        }
                    }
                    if($Hit > 0){
                        $Words1[$x] = "wella";    
                    }
                }
            }
            for my $x(0..$#Words1){

                
                if($Words1[$x] =~ /\bwell\b/){
                    my $Hit = 0;
                    for my $m(0..$#ListW3){
                        if($Words1[$x - 1] eq $ListW3[$m]){
                            $Hit++;
                            last;
                        }
                    } 
                    if($Hit > 0){
                        $Words1[$x] = "welld";
                    }
                }
                if($Words1[$x] =~ /\bwell\b/){
                    my $Hit = 0;
                    for my $m(0..$#ListK2){
                        if($Words1[$x - 1] eq $ListK2[$m]){
                            $Hit++;
                            last;
                        }
                    } 
                    if($Hit > 0){
                        $Words1[$x] = "welld";
                    }
                }
                if($Words1[$x] =~ /\bwell\b/){
                    my $Hit = 0;
                    for my $m(0..$#ListW5){
                        if ($Words1[$x + 1] eq $ListW5[$m]){
                            $Hit++;
                            last;
                        }
                    }
                    if($Hit > 0){
                        $Words1[$x] = "welld";
                    }
                }
                if($Words1[$x] =~/\bwell\b/ && $Words1[$x + 1] =~ /\bof\b/){
                    $Words1[$x] = "wellw";
                }
  
                if($Words1[$x] =~ /\bkind\b/ && $Words1[$x + 1] =~ /\bof\b/){
                    for my $q(0..$#ListK2){
                        if($Words1[$x + 2] eq $ListK2[$q]){
                           my @TempC;
                            for my $n($x+2..$#Words1){
                            push @TempC, $Words1[$n];
                            }
                            $Words1[$x] = "kind";
                            $Words1[$x + 1] = "of";
                            
                        }
                    }
                }
            }

            for my $k(0..$#Words1){
                if($Words1[$k] =~ /\bkind\b/ && $Words1[$k + 1] =~ /\bof\b/){
                    for my $q(0..$#ListK2){
                        if($Words1[$k + 2] eq $ListK2[$q]){
                           my @TempC;
                            for my $n($k+2..$#Words1){
                                push @TempC, $Words1[$n];
                            }
                            $Words1[$k] = "kind";
                            $Words1[$k + 1] = "of";
                            
                        }
                    }
                }
            }
            for my $k(0..$#Words1){
                if($Words1[$k] =~ /\bkind\b/ && $Words1[$k + 1] =~ /\bof\b/){
                    for my $q(0..$#ListK2){
                        if($Words1[$k + 2] eq $ListK2[$q]){
                           my @TempC;
                           for my $n($k+2..$#Words1){
                                push @TempC, $Words1[$n];
                            }
                            $Words1[$k] = "kind";
                            $Words1[$k + 1] = "of";
                            
                        }
                    }
                }

            }
            for my $k(0..$#Words1){
                if($Words1[$#Words1] =~ /\bknow\b/ && $Words1[$#Words1 - 1] =~ /\byou\b/){
                    $Words1[$#Words1 - 1] = "you";
                    $Words1[$#Words1] = "knowD";
                }
                
            }
            for (my $k = 1; $k <= $#Words1;$k++){ # start third pass
                if($Words1[$k] =~ /\blike/){
                    if($Words1[$k + 1] =~/\bwelld\b/){
                        $Words1[$k] = "likex";
                    }
                }
                if($Words1[$k] =~ /\blike/){
                    if($Words1[$k + 1] =~/\bmean\b/){
                        $Words1[$k] = "likex";
                    }
                }
            }
            for my $k(0..$#Words1){#Fourth pass
                if($Words1[$k] =~ /\bwell\b/){
                    $Words1[$k] = "welld";
                }
                
                if($Words1[$k] =~ /\blikex\b/){
                    $Words1[$k] = "like";
                }
            }
            if($Words1[0] =~ /\blikec\b/ || $Words1[0] =~/\blikev\b/){
                $Words1[0] = "like";
            }
            
            for my $k(0..$#Words1){
                push @{$SentsC[$i]},$Words1[$k];

            }
        }
    }
    my @OutputC;

    for my $i(0..$#Sents){
        if($Sents[$i] =~ /\w+/){

            if($i < $#Sents && $Sents[$i + 1] =~ /\w+/){
                print LogFile "Problem with splits at $Sents[$i] \n $Sents[$i + 1]\n";
                $LocLogWarn++;
            }elsif($i < $#Sents){

                for my $k(0..$#{$SentsC[$i]} - 1){
                    if($SentsC[$i][$k] ne /parenth(\d+)/){
                        push @OutputC,$SentsC[$i][$k];
                        $GWordN++;
                       
                    }
                }
                if($SentsC[$i][$#{$SentsC[$i]}] ne /parenth(\d+)/){
                    push @OutputC,$SentsC[$i][$#{$SentsC[$i]}];
                    $GWordN++;

                }
               
            }elsif($i == $#Sents){
                for my $k(0..$#{$SentsC[$i]}){
                    if($SentsC[$i][$k] ne /parenth(\d+)/){
                        push @OutputC,$SentsC[$i][$k];
                        $GWordN++;
                    }
                }
            }
        }
    }
    my @Results;
    $Results[0] = $GWordN;
    $Results[1] = $LocLogWarn;
    $Results[2] = $#OutputC;
    for my $i(0..$#OutputC){
        push @Results, $OutputC[$i];
    }
    
    return @Results;
}


sub Process2{ #to MTTFile
    my $LocLogWarn = 0;
    my $Stream1 = $_[0];
    my $GWordN = $_[1];
    my @Prelim;
    
    my @PSplit = split /([\(\)\[\]])/,$Stream1;
    my @ParenStuff;
    my @ParensN;
    my @ParenHold;
    my $LocParen;
    my $NWordN = 0;
    my $Paren = 0;
    my @NS;
    my $ParenCheck = 0;
    my $LocWordN = 0;
    for my $j(0..$#PSplit){
        
        if($PSplit[$j] eq '(' || $PSplit[$j] eq '['){
            if($ParenCheck == 0){
                for my $q(0..$#ParenHold){
                    pop @ParenHold;
                }
            }
            $Paren++;
            push @ParenHold,$PSplit[$j];
            $ParenCheck++;
        }elsif($PSplit[$j] eq ')' or $PSplit[$j] eq ']'){
            $Paren--;
            
            push @ParenHold,$PSplit[$j];
            $ParenCheck--;
            if($ParenCheck == 0){
               $LocParen = join "",@ParenHold;
                push @ParenStuff,$LocParen;
                my $Marker = "parenth$#ParenStuff";
                push @Prelim,$Marker;
            }

        }elsif($Paren > 0){
            push @ParenHold,$PSplit[$j];

        }elsif($Paren < 0){
            my @FinList = (0,"ERROR1");
            return @FinList; 
        }elsif($Paren == 0){
            my @Words = split /\s+/,$PSplit[$j];
            for my $k(0..$#Words){
                if($Words[$k] =~ /\w+/){
                    push @Prelim,$Words[$k];
                }
            }
        }
    }
    
    for my $i(0..$#Prelim){
        $Prelim[$i] =lc $Prelim[$i];
        if($Prelim[$i] =~ /(.*)▓(.*)/){
            $Prelim[$i] = "$1.\'.$2";
        }
        if($Prelim[$i] =~ /^o'clock(.*)/){
            $Prelim[$i] = "oclock$1";
        }
        if($Prelim[$i] =~/^'em(.*)/){
            $Prelim[$i] = "them ('em)";
        }

    }

    for my $i(0..$#Prelim){
        if($Prelim[$i] =~ /(.*)-{2,5}(\w+)(.*)/){
            print LogFile "Removed hyphens from $Prelim[$i]\n";
            $LocLogWarn++;
            my $Begin = $1;
            my $End = $2.$3;
            if($Begin =~ /\w+/){
                my @Temp;
                for my $q($i + 1..$#Prelim){
                    push @Temp,$Prelim[$q];
                }
                $Prelim[$i] = $Begin;
                $Prelim[$i + 1] = $End;
                print LogFile "Prelim[$i] changed to $Prelim[$i] $Prelim[$i + 1]\n";
                for my $q(0..$#Temp){
                    $Prelim[$i + 2 + $q] = $Temp[$q];
                }    
            }else{
                $Prelim[$i] = $End;
            }
        }
        my $Hyph = 0;
        if($Prelim[$i] =~ /\w+-\w+/){
            $Hyph++;
            
            
            while ($Hyph > 0){
                
                if($Prelim[$i] =~ /(.*)(\w+)-(\w+)(.*)/){
                    $Prelim[$i] = "$1$2_$3$4";
                    
                   
                    if($Prelim[$i] =~ /-\w+/){
                       
                        $Hyph++;
                    }else{
                        $Hyph = 0;
                       
 
                    }
                }
            }
        }
        
        if($Prelim[$i] =~ /(.*)(\w+)я(\w+)(.*)/){
            print LogFile "Removed mdash from $Prelim[$i]\n";
            $LocLogWarn++;
            my @Temp;
            for my $j($i + 1..$#Prelim){
                push @Temp,$Prelim[$j];
            }
            $Prelim[$i] = $1.$2;
            $Prelim[$i + 1] = $3.$4;
            for my $k($i + 2..2+$i+$#Temp){
                $Prelim[$k] = $Temp[$k - $i - 2];
            }
        }
        
        if($Prelim[$i] =~/(.*)(\w+)_{1,}(\w+)(.*)/){
            if($3 != "m"){
                if($2 != "a" && $2 != "p"){
                    my $NewWord = $1.$2.$3.$4;
                    $Prelim[$i] = $NewWord;
                }
            }
        }elsif($Prelim[$i] =~ /(.*)(\w+)_\W/){
            my $NewWord = $1.$2;
            print LogFile "$Prelim[$i] changed to $NewWord\n";
            $Prelim[$i] = $NewWord;
        }                 
    }

    my @Sents;
    my $BigSent = join "@",@Prelim;
    @Sents = split /([\.,\ср"р"'у`;:\?])/,$BigSent;
    my @SentsC;
    my @SentsM;     
    for my $i(0..$#Sents){
        if($Sents[$i] =~ /\w/){
            if($Sents[$i] =~ /^@(.*)$/){
                $Sents[$i] = $1;
            }
 
            my @Words1 = split "@",$Sents[$i];
            for my $j(0..$#Words1){
                $Words1[$j] = lc ($Words1[$j]);
            }
            for my $j(0..$#Words1){
                if($Words1[$j] =~ /^[!\*\+]?(\w+)[!\*\+]?$/){
                    $Words1[$j] = $1;
                }
            }
            

            for my $m(0..$#Words1){
                for my $j(0..$#ListM1){
                    if($Words1[$m] eq $ListM1[$j]){
                        $Words1[$m] = "MM ($ListM1[$j])";
                    }
                }
            }
            for my $m(0..$#Words1){
                if($Words1[$m] =~ /\bkindaff\b/){
                    $Words1[$m] = "kind";
                }
                if($Words1[$m] =~ /\bknowd\b/){
                    $Words1[$m] = "know";
                }
                if($Words1[$m] =~ /\blikec\b/){
                    $Words1[$m] = "like";
                }
                if($Words1[$m] =~ /\blikev\b/){
                    $Words1[$m] = "like";
                }
                if($Words1[$m] =~/\bmeanaff\b/){
                    $Words1[$m] = "mean";
                }
                if($Words1[$m] =~ /\bwella\b/){
                    $Words1[$m] = "well";
                }
                if($Words1[$m] =~ /\bwellc\b/){
                    $Words1[$m] = "well";
                }
            }
            if($Words1[0] =~ /\blike\b/){
                $Words1[0] = "likex";
            }

            if($Words1[0] =~ /\byou\b/ && $Words1[1] =~ /\bknow\b/){
                if($#Words1 == 1){
                    $Words1[1] = "knowD";
                    
                }elsif($#Words1 > 1){
                    my $Hit = 0;
                    for my $m(0..$#ListY1){
                        if ($Words1[2] eq $ListY1[$m]){
                            $Hit++;
                            last;
                        }
                    }
                    if($Hit == 0){
                        $Words1[1] = "knowD";
                       
                    }
                }
            }

            for my $k(0..$#Words1){
                if($Words1[$k] =~ /\bkind\b/){
                    if($Words1[$k + 1] != /\bof\b/){
                        my $Hit = 0;
                        for my $q(0..$#ListK1){
                            if($Words1[$k - 1]  eq $ListK1[$q]){
                                $Hit++;
                                last;
                            }
                        }
                        if($Hit > 0){
                            if ($Words1[$k - 2] =~ /\bof\b/){
                                $Words1[$k] = "kind";
                            }else{
                                $Words1[$k] = "kindAFF";
                            }
                        }
                    }
                }
            }



            for my $k(0..$#Words1){
                if($Words1[$k] =~ /\blike\b/){ 
                    for my $q(0..$#ListL1){ 
                        if($Words1[$k - 1] eq $ListL1[$q]){
                            $Words1[$k] = "likec";
                            last;
                        }
                    }
                }
               
                if($Words1[$k] =~ /\blike\b/){
                    if($k == $#Words1 && $#Words1 < 6){
                        $Words1[$k] = "likex";
                    }
                }
                
                if($Words1[$k] =~ /\blike\b/){
                    for my $q(0..$#ListL2){
                        if($Words1[$k - 1] eq $ListL2[$q]){
                            $Words1[$k] = "likex";
                            last;
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/ && $Words1[$k - 1] =~ /\bwas\b/){
                    $Words1[$k] = "likex";
                }
                if($Words1[$k] =~ /\blike\b/ && $Words1[$k - 1] =~ /\bis\b/){
                    $Words1[$k] = "likex";
                }
                if($Words1[$k] =~ /\blike\b/ && $Words1[$k - 1] =~ /\bs\b/){
                    $Words1[$k] = "likex";
                }
                if($Words1[$k] =~ /\blike\b/ && $Words1[$k - 1] =~ /\bnot\b/ && $Words1[$k - 2] =~ /\bs\b/){
                    $Words1[$k] = "likex";
                }
                if($Words1[$k] =~ /\blike\b/){
                    if($Words1[$k + 1] =~ /\bi\b/){
                        for my  $q(0..$#ListL3){
                            if($Words1[$k - 1] eq $ListL3[$q]){  
                                $Words1[$k] = "likec";
                                last;
                            }
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/){
                    for my $q(0..$#ListL1){
                        if($Words1[$k + 1] eq $ListL1[$q]){
                            $Words1[$k] = "likex";
                            last;
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/ && $Words1[$k + 1] =~ /\bi\b/ && $Words1[$k + 2] =~ /\bdon\b/){
                    $Words1[$k] = "likex";
                }
                if($Words1[$k] =~ /\blike\b/ && $Words1[$k + 1] =~ /\byou/){
                    $Words1[$k] = "likex";
                }

                if($Words1[$k] =~ /\blike\b/){
                    if($Words1[$k - 1] =~ /\bs\b/ && $Words1[$k - 2] =~ /\bit\b/){
                        my $Hit = 0;
                        for my $q(0..$#ListL4){
                            if($Words1[$k - 3] eq $ListL4[$q]){ 
                                $Words1[$k] = "likec";
                                $Hit++;
                                last;
                            }
                            if($Hit == 0){ 
                               $Words1[$k] = "likex"; 
                            }
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/){
                    for my $m(0..$#ListL5){ #Rule 14f
                        if($Words1[$k - 1] eq $ListL5[$m]){  
                            $Words1[$k] = "likev"; 
                            last;
                        }    
                    }
                }
                
                if($Words1[$k] =~ /\blike\b/){
                    if($Words1[$k - 1] =~ /\bt\b/){
                        for my $m(0..$#ListL6){
                            if($Words1[$k - 2] eq $ListL6[$m]){
                                $Words1[$k] = "likev";
                                last;
                            }
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/){
                    if($Words1[$k - 1] =~ /\bnot\b/){
                       
                        my $Hit = 0;
                        for my $m(0..$#ListL7){ 
                            if($Words1[$k - 2] eq $ListL7[$m]){
                                $Words1[$k] = "likev";
                                $Hit++;
                                last;
                            }
                        }

                    }
                }
                
                if($Words1[$k] =~ /\blike\b/){
                    for my $m(0..$#ListL8){
                        if($Words1[$k - 1] eq $ListL8[$m]){
                            my $Hit = 0;
                            for my $q(0..$#ListL9){
                                if($Words1[$k - 1] eq $ListL9[$q]){
                                    for my $r(0..$#ListL10){
                                        if($Words1[$k + 1] eq $ListL10[$r]){
                                            $Words1[$k] = "likex";
                                            $Hit++;
                                        }
                                    }
                                }
                            }

                            if($Hit == 0){
                                $Words1[$k] = "likec";
                            }
                            last;
                        }
                    }
                }

                if($Words1[$k] =~ /\blike\b/ && $Words1[$k - 1] =~ /\bto\b/){
                    for my $q(0..$#ListL8){
                        if ($Words1[$k + 1] eq $ListL8[$q]){
                            $Words1[$k] = "likex";
                            last
                        }
                    }
                }

                if($Words1[$k] =~ /\blike\b/){
                    if($k < $#Words1 - 1 && $Words1[$k + 1] =~ /\bto\b/){
                        my $Hit = 0;
                        for my $m(0..$#ListL11){
                            if($Words1[$k - 1] eq $ListL11[$m]){
                                $Hit++;
                                last;
                            } 
                        }
                        if($Hit == 0){
                            $Words1[$k] = "likev";
                        }else{
                            $Words1[$k] = "likec";
                        }
                    }
                }

                if($Words1[$k] =~ /\blike\b/){
                    if($k > 0 && $k < $#Words1){
                        for my $m(0..$#ListL10){
                            if($Words1[$k - 1] eq $ListL10[$m] && $Words1[$k - 1] ne $Words1[$k + 1]){ #Rule 14i1
                                $Words1[$k] = "likev";
                                last;
                            }
                        }
                    }
                }
                
                if($Words1[$k] =~ /\blike\b/){
                    if($k > 0 && $k < $#Words1){
                        for my $m(0..$#ListL12){   
                            if($Words1[$k + 1] eq $ListL12[$m]){ 
                                $Words1[$k] = "likec";
                                last;
                            }
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/){
                    for my $m(0..$#ListL13){   
                        if($Words1[$k + 1] eq $ListL13[$m]){ 
                            $Words1[$k] = "likev";
                            last;
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/){
                    if($k > 0 && $k < $#Words1){
                        for my$m(0..$#ListL14){
                            if($Words1[$k + 1] eq $ListL14[$m]){
                                my $Hit1 = 0;
                                for my $q(0..$#ListL15){
                                    if($Words1[$k - 1] eq $ListL15[$q]){
                                        $Hit1++;
                                        last;
                                    }
                                }
                                if($Hit1 == 0){
                                    $Words1[$k] = "likec";
                                    last;
                                }else{
                                    $Words1[$k] = "likex";
                                }
                            }
                        }
                    }
                }
            }

            for my $k(0..$#Words1){
               
                if($Words1[$k] =~ /\bknow\b/ && $Words1[$k - 1] =~ /\byou\b/){
                    my $Hit = 0;
                    for my $m(0..$#ListY1){
                        if($Words1[$k + 1] eq $ListY1[$m]){
                            $Hit++;
                            last;
                        }
                    }
                    for my $m(0..$#ListY2){
                        if($Words1[$k - 2] eq $ListY2[$m]){
                            $Hit++;
                            last;
                        }
                    }
                    if($Hit == 0){
                        $Words1[$k] = "knowD";
                        
                    }
                }
            }

            for my $x(0..$#Words1){

                if($Words1[$x] =~ /\bwell\b/ && $Words1[$x - 1] =~ /\bas\b/){
                    $Words1[$x] = "wellc";
                    next;
                }
            }
            for my $x(0..$#Words1){

                
                if($Words1[$x] =~ /\bwell\b/){
                    my $Hit = 0;
                    for my $m(0..$#ListW1){
                        if($Words1[$x - 1] eq $ListW1[$m]){
                            $Hit++;
                            last;
                        }
                    }
                    for my $q(0..$#ListW2){
                        if($Words1[$x - 1] eq $ListW2[$q]){
                            $Hit++;
                            last;
                        }
                    }
                    if($Hit > 0){
                        $Words1[$x] = "wella";    
                    }
                }
            }
            for my $x(0..$#Words1){

                
                if($Words1[$x] =~ /\bwell\b/){
                    my $Hit = 0;
                    for my $m(0..$#ListW3){
                        if($Words1[$x - 1] eq $ListW3[$m]){
                            $Hit++;
                            last;
                        }
                    } 
                    if($Hit > 0){
                        $Words1[$x] = "welld";
                    }
                }
                if($Words1[$x] =~ /\bwell\b/){
                    my $Hit = 0;
                    for my $m(0..$#ListK2){
                        if($Words1[$x - 1] eq $ListK2[$m]){
                            $Hit++;
                            last;
                        }
                    } 
                    if($Hit > 0){
                        $Words1[$x] = "welld";
                    }
                }
                if($Words1[$x] =~ /\bwell\b/){
                    my $Hit = 0;
                    for my $m(0..$#ListW5){
                        if ($Words1[$x + 1] eq $ListW5[$m]){
                            $Hit++;
                            last;
                        }
                    }
                    if($Hit > 0){
                        $Words1[$x] = "welld";
                    }
                }
                if($Words1[$x] =~/\bwell\b/ && $Words1[$x + 1] =~ /\bof\b/){
                    $Words1[$x] = "wellw";
                }


            }

        
            for my $k(0..$#Words1){
                if($Words1[$#Words1] =~ /\bknow\b/ && $Words1[$#Words1 - 1] =~ /\byou\b/){
                    $Words1[$#Words1] = "knowD";
                    pop @Words1;
                }

            }
            for (my $k = 1; $k <= $#Words1;$k++){ # start third pass
                if($Words1[$k] =~ /\blike/){
                    if($Words1[$k + 1] =~/\bwelld\b/){
                        $Words1[$k] = "likex";
                    }
                }
                if($Words1[$k] =~ /\blike/){
                    if($Words1[$k + 1] =~/\bmean\b/){
                        $Words1[$k] = "likex";
                    }
                }
            }
            for my $k(0..$#Words1){#Fourth pass
                if($Words1[$k] =~ /\bwell\b/){
                    $Words1[$k] = "welld";
                }
                if ($Words1[$k] =~ /\bkindad\b/){
                    $Words1[$k] = "kindas";
                }
                
                if($Words1[$k] =~ /\blikex\b/){
                    $Words1[$k] = "like";
                }
            }
            if($Words1[0] =~ /\blikec\b/ || $Words1[0] =~/\blikev\b/){
                $Words1[0] = "like";
            }
            
            for my $k(0..$#Words1){
                push @{$SentsC[$i]},$Words1[$k];

            }
        }
    }
    my @OutputM;

    for my $i(0..$#Sents){
        if($Sents[$i] =~ /\w+/){

            if($i < $#Sents && $Sents[$i + 1] =~ /\w+/){
                print LogFile "ERROR 6. Problem with splits at $Sents[$i] \n $Sents[$i + 1]\n";
                $LocLogWarn++;
            }elsif($i < $#Sents){

                for my $k(0..$#{$SentsC[$i]} - 1){
                    if($SentsC[$i][$k] =~ /parenth(\d+)/){

                        my $ParNum = $1;

                        my @Split1 = split "@",$ParenStuff[$ParNum];
                        for my $m(0..$#Split1){

                            if($Split1[$m] =~ /\w+/){
                                push @OutputM, $Split1[$m];
                                
                            }
                        }

                    }else{
                        $GWordN++;
                        my $NewWord = &MPrep($SentsC[$i][$k]);
                        my @NewWords = split "@", $NewWord;
                        for my $q(0..$#NewWords){
                            push @OutputM,$NewWords[$q];
                        }
                        if($GWordN % $MTTNum == 0){
                            my $Mark = "[$GWordN]";
                            push @OutputM, $Mark;
                        }
                    }
                }
                if($SentsC[$i][$#{$SentsC[$i]}] =~ /parenth(\d+)/){
                    my $ParNum = $1;
                    my @Split1 = split /@/,$ParenStuff[$ParNum];
                    for my $m(0..$#Split1){
                        if($Split1[$m] =~ /\w+/){
                            push @OutputM, $Split1[$m];

                        }
                    }
                    
                }else{
                    $GWordN++;
                    my $FinWord;
                    my $FinWordPrep = &MPrep($SentsC[$i][$#{$SentsC[$i]}]);
                    my @FinWord1 = split /@/,$FinWordPrep;
                    if($#FinWord1 == 0){
                        $FinWord = $FinWord1[0].$Sents[$i + 1];

                        push @OutputM,$FinWord;
                    }elsif($#FinWord1 == 1){
                        push @OutputM,$FinWord1[0];
                        my $Fin = $FinWord1[1].$Sents[$i + 1];
                        push @OutputM,$Fin;
                    }
                    if($GWordN % $MTTNum == 0){
                        my $Mark = "[$GWordN]";
                        push @OutputM, $Mark;
                    }
                }
            }elsif($i == $#Sents){
                for my $k(0..$#{$SentsC[$i]}){
                    if($SentsC[$i][$k] =~ /parenth(\d+)/){
                        my $ParNum = $1;

                        my @Split1 = split /@/,$ParenStuff[$ParNum];
                        for my $m(0..$#Split1){
                            if($Split1[$m] =~ /\w+/){
                                push @OutputM, $Split1[$m];

                            }
                        }
 

                    }else{
                        $GWordN++;
                        my $NewWord = &MPrep($SentsC[$i][$k]);
                        my @NewWords = split "@", $NewWord;
                        for my $q(0..$#NewWords){
                            push @OutputM,$NewWords[$q];
                        }
                        if($GWordN % $MTTNum == 0){
                            my $Mark = "[$GWordN]";
                            push @OutputM, $Mark;
                        }
                    }
                }
            }
        }
    }
    my @Results;
    $Results[0] = $GWordN;
    $Results[1] = $LocLogWarn;
    for my $i(0..$#OutputM){
        push @Results, $OutputM[$i];

    }
    return @Results;
}

my @BigDic;
my @LD;
open(Dic,"TheDic") or die("Can't open BigDic now\n");
while (<Dic>){
    chomp;
    push @BigDic,$_;
}

print "Please type the name of your subdirectory containing the files to be read\n";
chomp(my $Dir = <STDIN>);

my $LOGF = $Dir."LOG.txt";
my $TTF = $Dir."TTFile.txt";
opendir DR, "$Dir"  or die("can't open directory: $!");
open(LogFile,">$Dir/DATA/$LOGF") or die("Can't open Logfile\n");
open(TTFile, ">$Dir/DATA/$TTF") or die("Can't open TTFile\n");


my @TxtFiles;
foreach my $File (readdir DR){
    $_ = $File;
    if(/\.txt/){
	unless(/^\./){
		push @TxtFiles,$File;
	}
    }
 
}

my $LogWarn = 0;
for(my $w = 0; $w <= $#TxtFiles;$w++){
    
    my @FileSplit = split /\./,$TxtFiles[$w];
    if ($#FileSplit > 1){
        if ($FileSplit[1] ne "c" && $FileSplit[1] ne "a"){
   
            print "The file name $TxtFiles[$w] contains more than one period (full stop). preDAAP cannot process this file; please rename it\n";
            print LogFile "The file name $TxtFiles[$w] contains more than one period (full stop). preDAAP09 cannot process this file; please rename it\n";
        }
    }
    for my $i(0..$#FileSplit){
        if ($FileSplit[$i] =~ /.*?_/){
            print "The file name $TxtFiles[$w] contains an underscore. PreDAAP09 cannot process this file; please rename it\n";
            die;
        }
    }
    my $OUTF=$FileSplit[0].".a.txt";
    open(OUTFile, ">$Dir/$OUTF") or die("Failed to open OUTFile");
    open(InFile,"$Dir/$TxtFiles[$w]") or die("Can't open $TxtFiles[$w]");
    while(<InFile>){
        s/\r/\n/g;
 
        print OUTFile "$_\n";
    }
    close InFile;
    close OUTFile;
    my $NewF = $FileSplit[0]."\.a\.txt";
    open(InFilea,"$Dir/$NewF") or die("Can't read $FileSplit[0] dot a file\n");
    
    my @NS;#NewStream
    my %TTList;
    my @LLD;
    my %LocTTList;
    my $TN = 0; #TurnN
    my @TurnStream;
    my $CatSwitch = 0;
    my $TurnSwitch = 0;
    my $SpkrID = 0;
    my @Spkr;
    my $tCheck = 0;
    my $WordN = 0;
    my $Paren = 0;
    my $StSwitch = 0;
    my $NewName = $FileSplit[0].".c.txt";
    my $MTT = $FileSplit[0]."MTT1File.txt";
    my $LLD = $FileSplit[0]."LLDFile.txt";
   
    my $c9Check = 0;
    open(OutFile,">$Dir/$NewName") or die ("Can't write to $NewName\n");
    open(MTTFile,">$Dir/DATA/$MTT") or die ("Can't write to $MTT\n");
    open(LLDFile,">$Dir/DATA/$LLD") or die ("Can't write to $LLD\n");
    print LogFile "\n\n We are now reading $TxtFiles[$w]\n\n";
    print "\n\n We are now reading $TxtFiles[$w]\.a\n\n";
    while(<InFilea>){
	chomp;
	my $Line=$_;
        my $CLine;
        if(/^.+\\/){
            print "SERIOUS ERROR: Backslash not at first character of line:\n$Line\n";
            print LogFile "ERROR 1: Backslash not at first character of line:\n$Line\n";
        }
        if(/^\\c9/){

            my $Stream = join " ",@TurnStream;
                    my @ToSend = ($Stream,$WordN);

                    my @Response = &Process1(@ToSend);
                    $WordN = $Response[0];

                    my $LocLog = 0;
                    $LocLog = $Response[1];
                    if ($LocLog > 1){
                        print "The Local LogFile for Turn $TN has $LocLog item(s)\n";
                        print LogFile "The above $LocLog item(s) are for Turn $TN\n";
                    }
                    my $CItems = $Response[2];
                    
                    for my $i(3..$CItems + 3){
                        print OutFile " $Response[$i] ";
                        if(exists $TTList{$Response[$i]}){
                            $TTList{$Response[$i]}++;
                        }else{
                            $TTList{$Response[$i]} = 1;
                        }
                        if(exists $LocTTList{$Response[$i]}){
                            $LocTTList{$Response[$i]}++;
                        }else{
                            $LocTTList{$Response[$i]} = 1;
                        }
                    }

                    if($Response[1] =~ /^ERROR1/){
                        print "ERROR 3: Negative Parentheses at Turn: $TN\n";
                        print LogFile "ERROR 3: Negative Parentheses at Turn: $TN\n";
                    }
	    print OutFile "\n\\c9\n\n";

            $c9Check++;
            if($Paren != 0){
                print LogFile "ERROR 2: Paren != 0 at end of file\n";
                print "ERROR 2: Paren != 0 at  end of file\n";
            }
            
	    last;
	}
        if(/\s?\\t/){
            if(/\s?\\t\s+(\w+)\s?:\s?(\w+)/){
                $TurnSwitch = 0;
                $CatSwitch++;
                if($#TurnStream > -1){
                    my $Stream = join " ",@TurnStream;

                    my @ToSend = ($Stream,$WordN);
                    my @Response = &Process1(@ToSend);
                     $WordN = $Response[0];
                    my $LocLog = 0;
                    $LocLog = $Response[1] + 1;
                    if ($LocLog > 1){
                        print "The Local LogFile for Turn $TN has $LocLog items\n";
                        print LogFile "The above $LocLog items are for Turn $TN\n";
                    }
                    my $CItems = $Response[2];
                        
                    for my $i(3..$CItems + 3){
                        print OutFile " $Response[$i] ";
                        if(exists $TTList{$Response[$i]}){
                            $TTList{$Response[$i]}++;
                        }else{
                            $TTList{$Response[$i]} = 1;
                        }
                        if(exists $LocTTList{$Response[$i]}){
                            $LocTTList{$Response[$i]}++;
                        }else{
                            $LocTTList{$Response[$i]} = 1;
                        }
                    }
                    my @MFile;
                    for my $i($CItems + 4..$#Response){

                        push @MFile, $Response[$i];
                    }

                    if($Response[1] =~ /^ERROR1/){
                        print "ERROR 2: Negative Parentheses at Turn: $TN\n";
                        print LogFile "ERROR 2: Negative Parentheses at Turn: $TN\n";
                            
                    }
                    $tCheck++;
                    $TurnSwitch = 0;
                }
                print OutFile "\n\\t $1:$2\n";

                for my $q(0..$#TurnStream){
                    pop @TurnStream;
                    
                }
            }else{
                print LogFile "ERROR 8: There is an improper \\t line: $Line\n";
                $LogWarn++;
            }
        }elsif(/\s?\\s/){
            if(/\s?\\s\s?(\d+)\s?(.*)/ || /\s?\\s\s+(\d+)\s?(.*)/){
                my $Speaker = $1;
                my $Balance = $2;

                #$tCheck = 0;
                $StSwitch = 0;
                if($TurnSwitch == 0){

                    if($Speaker != $SpkrID){
                        if($#TurnStream == -1){
                            push @Spkr,$Speaker;
                           $SpkrID = $Speaker;
                            
                           $TN++;

                           print OutFile "\n\\s $Speaker [Turn $TN] ";

                        }elsif($#TurnStream > -1){       
                            my $Stream = join " ",@TurnStream;
                            my @ToSend = ($Stream,$WordN);
                            my @Response = &Process1(@ToSend);
                            $WordN = $Response[0];
                            my $LocLog = 0;
                            $LocLog = $Response[1] + 1;
                            if ($LocLog > 1){
                                print "The Local LogFile for Turn $TN has $LocLog items\n";
                                print LogFile "The above $LocLog items are for Turn $TN\n";
                            }
                            my $CItems = $Response[2];
                            $TN++;
                            for my $i(3..$CItems + 3){
                                print OutFile " $Response[$i] ";
                                if(exists $TTList{$Response[$i]}){
                                    $TTList{$Response[$i]}++;
                                }else{
                                    $TTList{$Response[$i]} = 1;
                                }
                                if(exists $LocTTList{$Response[$i]}){
                                    $LocTTList{$Response[$i]}++;
                                }else{
                                    $LocTTList{$Response[$i]} = 1;
                                }
                            }
                            my @MFile;
                            for my $i($CItems + 4..$#Response){

                                push @MFile, $Response[$i];
                            }

                            if($Response[1] =~ /^ERROR1/){
                                print "ERROR 3: Negative Parentheses at Turn: $TN\n";
                                print LogFile "ERROR 3: Negative Parentheses at Turn: $TN\n";
                                
                            }
           
                            $SpkrID = $Speaker;
                            push @Spkr,$Speaker;
                            for my $i(0..$#TurnStream){
                               pop @TurnStream;
                            }
                            print OutFile "\n\\s $Speaker [Turn $TN] ";

                        }
                    }elsif($Speaker == $SpkrID){
                        if($tCheck == 0){
                            print "ERROR 9: Adjacent Turns of Speech with same speaker at Turn $TN\n";
                            print "Balance = $Balance\n";
                            
                            print LogFile "ERROR 9: Adjacent Turns of Speech with same speaker at Turn $TN\n";
                            print LogFile "Balance = $Balance\n";
                            $LogWarn++;
                        }elsif($tCheck > 0){
                            if($#TurnStream > -1){
                                print "ERROR 10: tCheck > 0 and TurnStream not empty, Turn $TN";
                                print LogFile "ERROR 10: tCheck > 0 and TurnStream not empty, Turn $TN";
                                $LogWarn++;
                            }else{
                                push @Spkr,$Speaker;
                                $TN++;
                                print OutFile "\n\\s $Speaker [Turn $TN] ";
                            }
                        }
                    }
                    push @TurnStream,$Balance;
                }elsif($TurnSwitch > 0){
                    if($Speaker == $SpkrID){
                        push @TurnStream,$Balance;
                    }elsif($Speaker != $SpkrID){
                        my $Stream = join " ",@TurnStream;
                        my @ToSend = ($Stream,$WordN);
                        my @Response1 = &Process1(@ToSend);
                        my @Response2 = &Process2(@ToSend);
                        $WordN = $Response1[0];
                        my $LocLog = 0;
                        $LocLog = $Response1[1] + 1;
                        if ($LocLog > 1){
                            print "The Local LogFile for Turn $TN has $LocLog items\n";
                            print LogFile "The above $LocLog items are for Turn $TN\n";
                        }
                        my $CItems = $Response1[2];
                        
                        for my $i(3..$CItems + 3){
                            print OutFile " $Response1[$i] ";
                            if(exists $TTList{$Response1[$i]}){
                                $TTList{$Response1[$i]}++;
                            }else{
                                $TTList{$Response1[$i]} = 1;
                            }
                            if(exists $LocTTList{$Response1[$i]}){
                                $LocTTList{$Response1[$i]}++;
                            }else{
                                $LocTTList{$Response1[$i]} = 1;
                            }
                        }
                        my @MFile;
                        for my $i($CItems + 4..$#Response2){

                            push @MFile, $Response2[$i];
                        }

                        if($Response1[1] =~ /^ERROR1/){
                            print "ERROR 3: Negative Parentheses at Turn: $TN\n";
                            print LogFile "ERROR 3: Negative Parentheses at Turn: $TN\n";
                        }
                        for my $q(0..$#TurnStream){
                            pop @TurnStream;
                        }
                        $TN++;
                        $SpkrID = $Speaker;
                        print OutFile "\n\\s $Speaker [Turn $TN] ";
                        push @TurnStream,$Balance;
                    }
                }
                $TurnSwitch = 0;
                $tCheck = 0;
            }elsif (/\s?\\s(\w)\s?(\d+)\s?(.*)/ || /\s?\\s(\w)\s+(\d+)\s+(.*)/){   
            
                my $Signal = $1;
                my $Speaker = $2;
                my $Balance = $3;
                if($tCheck > 0){
                    print LogFile "ERROR 10: Confusion of \\t, \\st and \\s, Turn =$TN, Line  = $Line\n";
                    print "ERROR 10: Confusion of \\t, \\st and \\s, Turn =$TN, Line  = $Line\n";
                    $LogWarn++;
                }elsif($tCheck == 0){
                    if($Speaker == $SpkrID){
                        if($StSwitch == 0){
                            print LogFile "ERROR 11: Confusion of Speakers in \\st, Turn = $TN, Line = $Line\n";
                            print "ERROR 11: Confusion of Speakers in \\st, Turn = $TN, Line = $Line\n";
                            $LogWarn++;
                            $TurnSwitch++;
                        }else{
                            my @StStuff1 = split /\s+/,$Balance;
                            my $StStuff2 = join "\@", @StStuff1;
                            my $StStuff3 = "\(\\s$Signal$Speaker:$StStuff2\)";
                            push @TurnStream,$StStuff3;
                            $TurnSwitch++;
                        }
                    }elsif($Speaker != $SpkrID){
                        $TurnSwitch++;
                        $StSwitch++;
                        my @StStuff1 = split /\s+/,$Balance;
                        my $StStuff2 = join "\@", @StStuff1;
                        my $StStuff3 = "\(\\s$Signal$Speaker:$StStuff2\)";
                        
                        push @TurnStream,$StStuff3;
                    }
                }
               

            }else{
                print "ERROR 12: Syntax error involving \\s at Turn $TN\n";
                print LogFile "ERROR 12: Syntax error involving \\s at Turn $TN\n";
            }
        }else{
            if($TN == 0){
                
                print OutFile "\n$Line ";
               
            }elsif($TN > 0){
                if($tCheck > 0){
                    if($Line =~ /\w+/){                    
                        print LogFile "ERROR 13: No speaker ID after backslash t: Turn = $TN;\n$Line\n";
                        print "ERROR 13: No speaker ID after backslash t: \n$Line\n";
                        $LogWarn++;
                    }
                }else{
                    
                    push @TurnStream,$Line;
                }
            }
            
        }
    }


    
    close InFilea;
    open(InFilea,"$Dir/$NewF") or die("Can't read $FileSplit[0] dot a file Second time\n");
    for my $j(0..$#TurnStream){
        pop @TurnStream;
    }
    $SpkrID = 0;
    $TN = 0;
    $WordN = 0;
    while(<InFilea>){
	chomp;
	my $Line=$_;
        #my $CLine;
        
        if(/^\\c9/){
            $c9Check ++;
            my $Stream = join " ",@TurnStream;
            
            my @ToSend = ($Stream,$WordN);
            my @Response = &Process2(@ToSend);
            $WordN = $Response[0];
                       
            
            for my $i(2..$#Response){
 
                print MTTFile "$Response[$i] ";
            }
                    
            print MTTFile "\n\\c9\n";
            print MTTFile "The number of words is $WordN\n";
            print MTTFile "The number of turns is $TN";
	    last;
	}
        if(/\s?\\t/){
            if(/\s?\\t\s+(\w+)\s?:\s?(\w+)/){
                $TurnSwitch = 0;
                $CatSwitch++;
                if($#TurnStream > -1){
                    my $Stream = join " ",@TurnStream;
                    my @ToSend = ($Stream,$WordN);
                    my @Response = &Process2(@ToSend);
                     $WordN = $Response[0];
                    for my $p(2..$#Response){
                         
                        print MTTFile "$Response[$p] ";
                    }
                    
                    $TurnSwitch = 0;
                }
                
                print MTTFile "\n\\t $1:$2 [Word Number: $WordN]\n";
                for my $q(0..$#TurnStream){
                    pop @TurnStream;
                }
            
            }
        }elsif(/\s?\\s/){
            if(/\s?\\s\s?(\d+)\s?(.*)/ || /\s?\\s\s+(\d+)\s?(.*)/){
            
                my $Speaker = $1;
                my $Balance = $2;
                $StSwitch = 0;
                
                if($TurnSwitch == 0){

                    if($Speaker != $SpkrID){
                        if($#TurnStream == -1){
                            push @Spkr,$Speaker;
                           $SpkrID = $Speaker;
                           $TN++;
                           print MTTFile "\n\\s $Speaker [Turn $TN] ";
 
                        }elsif($#TurnStream > -1){       
                            my $Stream = join " ",@TurnStream;
                           
                            my @ToSend = ($Stream,$WordN);
                            my @Response = &Process2(@ToSend);
                            $WordN = $Response[0];
                            
                            $TN++;
                            
                            
                            for my $i(2..$#Response){
                    
                                print MTTFile "$Response[$i] ";
                            }
                            
                            $SpkrID = $Speaker;
                            push @Spkr,$Speaker;
                            
                            for my $i(0..$#TurnStream){
                               pop @TurnStream;
                            }
                            
                            print MTTFile "\n\\s $Speaker [Turn $TN] ";
                            
                        }
                    }elsif($Speaker == $SpkrID){
                        if($tCheck == 0){
                           
                        }elsif($tCheck > 0){
                            if($#TurnStream > -1){
                               
                            }else{
                                push @Spkr,$Speaker;
                                $TN++;
                                print MTTFile "\n\\s $Speaker [Turn $TN] ";
                            }
                        }
                    }
                    push @TurnStream,$Balance;
                
                }elsif($TurnSwitch > 0){

                    if($Speaker == $SpkrID){
                        push @TurnStream,$Balance;
                    }elsif($Speaker != $SpkrID){
                        my $Stream = join " ",@TurnStream;
                        my @ToSend = ($Stream,$WordN);
                        my @Response = &Process2(@ToSend);
                        $WordN = $Response[0];
                        my $LocLog = 0;
                        $LocLog = $Response[1] + 1;
                       
                        for my $i(2..$#Response){
                
                            print MTTFile "$Response[$i] ";
                        }
                        
                        for my $q(0..$#TurnStream){
                            pop @TurnStream;
                        }
                        $TN++;
                        $SpkrID = $Speaker;
                        
                        print MTTFile "\n\\s $Speaker [Turn $TN] ";
                        push @TurnStream,$Balance;
                    }
                }
                $TurnSwitch = 0;
                $tCheck = 0;
                
            }elsif(/\s?\\s(\w)\s?(\d)(.*)/ || /\s?\\s(\w)\s+(\d+)(.*)/){
                my $Signal = $1;
                my $Speaker = $2;
                my $Balance = $3;
                if($tCheck > 0){
                    
                }elsif($tCheck == 0){
                    if($Speaker == $SpkrID){
                        if($StSwitch == 0){
                            
                            $TurnSwitch++;
                        }else{
                            my @StStuff1 = split /\s+/,$Balance;
                            my $StStuff2 = join "\@", @StStuff1;
                            my $StStuff3 = "\(\\s$Signal$Speaker:$StStuff2\)";
                            push @TurnStream,$StStuff3;
                            $TurnSwitch++;
                        }
                    }elsif($Speaker != $SpkrID){
                        $TurnSwitch++;
                        $StSwitch++;
                        my @StStuff1 = split /\s+/,$Balance;
                        my $StStuff2 = join "\@", @StStuff1;
                        my $StStuff3 = "\(\\s$Signal$Speaker:$StStuff2\)";
                        
                        push @TurnStream,$StStuff3;
                    }
                }
            }
        
        }else{
            if($TN == 0){
                print MTTFile "\n$Line ";
            
            }elsif($TN > 0){
                if($tCheck == 0){
                    push @TurnStream,$Line;
                }
            }
        }
    }
     
    my $TopSpkr = 0;
    my %SpkrList;
    my $SpkrN = 0;
    for my $i(0..$#Spkr){
        if(exists $SpkrList{$Spkr[$i]}){
            $SpkrList{$Spkr[$i]}++;
        }else{
            $SpkrList{$Spkr[$i]} = 1;
            $SpkrN++;
            if($Spkr[$i] > $TopSpkr){
                $TopSpkr = $Spkr[$i];
            }
        }
    }
           
    if($TopSpkr != $SpkrN){
        print LogFile "ERROR 5:Problem with Speaker List\n TopSpkr = $TopSpkr; SpkrN = $SpkrN\n";
        print "ERROR 5:Problem with Speaker List\n TopSpkr = $TopSpkr; SpkrN = $SpkrN\n";
        
        $LogWarn++;
    }
   

    my $Hyphs = 0;
    foreach my $Word (sort keys %TTList){
        if($Word =~ /\w+-/){
            $Hyphs++;
        }else{
            print TTFile "$Word $TTList{$Word}\n";
            my $Hit = 0;
            for my $q(0..$#BigDic){
                if ($Word eq $BigDic[$q]){
                    $Hit++;
                    last;
                
                }
            }
            if($Hit == 0){
                push @LD,$Word;
                push @LLD, $Word;
            }
        }
    }
    for my $q(0..$#LD){
        print LLDFile "$LLD[$q]\n";
    }
    
    if($c9Check == 0){
        print OutFile "\n\\c9\n";
 	print MTTFile "\n\\c9\n";
        print LogFile "ERROR 14: File $TxtFiles[$w] lacking \\c9\n";
        print "ERROR 14: File $TxtFiles[$w] lacking \\c9\n";
    }
    close MTTFile;
    my $MTTNewName = $FileSplit[0]."MTT.txt";
    
    open(MTTFile,"$Dir/DATA/$MTT") or die ("Can't read $MTT\n");
    open(OutFile,">$Dir/DATA/$MTTNewName") or die ("Can't write to $NewName\n");
    
    while(<MTTFile>){
	chomp;
	
        s/' t\b/'t/g;
	s/' s\b/'s/g;
	s/' m\b/'m/g;
	s/' d\b/'d/g;
	s/' ve\b/'ve/g;
	s/' re\b/'re/g;
	s/' ll\b/'ll/g;
	s/' cause\b/ 'cause/g;
        s/knowD/know/g;
        
	print OutFile "$_\n";
    }
    unlink "$Dir/DATA/$MTT";
}
