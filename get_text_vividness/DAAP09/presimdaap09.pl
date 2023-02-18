=NOTE

This is preSimDAAP09.pl which must be run prior to running simdaap09.pl, the single
speaker version of the Discourse Attributes Analysis Program (DAAP)

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
my $MTTNum = 20;
my @ListL10 = qw/i you we they/; #Used for like: if preceding in list 1, and subsequent not equal to preceding, then likev
my @ListL8; #verbs in separate file; if preceding like, then likec; also if prepreceding like, and preceding not in List19; also likec to like if following likec
my @ListW2; #verbs in separate file; if preceding well, then wella;
my @ListL9 = qw/get/;
my @ListL14 = qw/this that/; #for use with list 25 concerning like
my @ListY1 = qw/this that what who where when which how/; #succeeds you know as opposed to youknow
my @ListL4 = qw/how that what/;
my @ListW1 = qw/awfully feeling into really definitely particularly very somewhat doing quite perfectly/; #makes wella if preceding well
my @ListY2 = qw/should would can shall will do if/; #if precedes you know, then stet
my @ListK2 = qw/likex ah mm uhm um er hm hmm youknow welld/;#If preceding well, changes to welld, if following form of like, change to like
my @ListL6 = qw/can shouldn shan wouldn don didn won/; # if precedes t before form of like, change to likev
my @ListL5 = qw/would should could shall will can do does d ll/; #if before like, change to  likev
my @ListW3 = qw/in on by and near far to of now before then think say said says well welld like liked/; #if precedes well, change to welld
my @ListW5 = qw/i we if and or but well why where who what how/; # if follows well, change to welld 
my @ListL7 = qw/can might should would do will could/;# if followed by not and then like, change like to likev
my @ListL12 = qw/i it he she you they/;
my @ListL11;# if like is followed by to: if preceded by list21, then likec, otherwise likev
my @ListK1 = qw/some any this that/; #of List23 kind
my @ListL15 = qw/found saw heard/; # For like, used with list 3
my @ListL2; #MM words
my @ListL3 = qw/act acted acting acts/; # if follows likec then like
my @ListL1 = qw/feel feeling feels felt look looked looking looks seem seemed seeming seems sound sounded sounding sounds/;
my @ListL13 = qw/her him i me them us/;
my @ListH1 = qw/um-hmm uh-huh uh-oh ah-ha un-hum mm-hmm/;#used for hyphenation
my @ListH2 = qw/anti co ex mid non pro re self/;#used for hyphenation
my @ListM1 = qw/aah ah ahh eh ehm hm hmm hmmm mmm uh uhh uhhh uhm uhmm um umm ummm unh/; #to be replaced by mm
open (ListL8,"ListL8.txt") or die ("Can't read ListL8\n"); 
while (<ListL8>){
    chomp;
    push @ListL8,$_;
}
open (ListW2,"ListW2.txt") or die ("Can't read ListW2\n");
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

my $RParens = 0;
sub NewLines{
    my @Lines;
    for my $w(0..$#_){
        print "$_[$w]\n";
        $_[$w] =~ s/\013?\010/\n/g;
        print "$_[$w]\n";
        $Lines[$w] = $_[$w];
    }
    return @Lines;
}

sub MPrep{
    my $Word = $_[0];
        
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
sub Process{
    my $LocLogWarn = 0;
    my $Stream1 = $_[0];
    my $GWordN = $_[1];
    my @Prelim = split /\s+/,$Stream1;
    
    for my $i(0..$#Prelim){
        $Prelim[$i] =lc $Prelim[$i];
        if($Prelim[$i] =~ /^o'clock(.*)/){
            $Prelim[$i] = "oclock$1";
        }
        if($Prelim[$i] =~ /^o'clock(.*)/){
            $Prelim[$i] = "oclock$1";
        }
        if($Prelim[$i] =~/^'em(.*)/){
            $Prelim[$i] = "them";
        }
        if($Prelim[$i] =~ /^'cause(.*)/){
            $Prelim[$i] = "because('cause)";
        }
        if($Prelim[$i] =~ /^\d+'s$/){
            $Prelim[$i] = "nums";
        }
        
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
    
    my @PSplit;
    my $Stream2 = join "@",@Prelim;
    if ($RParens == 0){
        @PSplit = split /([\(\)\[\]])/,$Stream2;
    }else{
        @PSplit = split /([\[\]])/,$Stream2;
    }
    my @ParenStuff;
    my @ParensN;
    my @ParenHold;
    my $LocParen;
    #my $NWordN = 0;
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
            
        }elsif($PSplit[$j] eq ')' || $PSplit[$j] eq ']'){
            $Paren--;
            
            push @ParenHold,$PSplit[$j];
           
            $ParenCheck--;
            if($ParenCheck == 0){
                
               $LocParen = join "",@ParenHold;
                push @ParenStuff,$LocParen;
                
                my $Marker = "parenth$#ParenStuff";
                push @NS,$Marker;
                
            }
            
        }elsif($Paren > 0){
            push @ParenHold,$PSplit[$j];
            
        }elsif($Paren < 0){
            my @FinList = (0,"ERROR1");
            return @FinList; 
        }elsif($Paren == 0){
            my @Words = split /@/,$PSplit[$j];
            for my $k(0..$#Words){
                if($Words[$k] =~ /\w+/){
                    push @NS,$Words[$k];
                    
                }
            }                            
        }
    }
    if($Paren != 0){
            my @FinList = (0,"ERROR1");
            return @FinList;
    }
    my @Sents;
    my $BigSent = join "@",@NS;
    @Sents = split /([\(\)\.,\*\срс"р"'у`т;:\?])/,$BigSent;
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
                
                if($Words1[$j] =~ /^[я!\*\+и]?(\w+)[я!\*\+и]{0,}$/){
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
                if($Words1[$j] =~ /\bok\b/){
                    $Words1[$j] = "okay";
                }
                if($Words1[$j] =~ /\b[\*!\?]\b/){
                   
                    my @Temp;
                    for my $k($j + 1..$#Words1){
                        push @Temp,$Words1[$k];
                    }
                    for my $k(0..$#Temp){
                        $Words1[$j + $k] = $Temp[$k];
                    }
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
                    $Words1[0] = "youknow";
                    pop @Words1;
                }elsif($#Words1 > 1){
                    my $Hit = 0;
                    for my $m(0..$#ListY1){
                        if ($Words1[2] eq $ListY1[$m]){
                            $Hit++;
                            last;
                        }
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
                    for my $m(0..$#ListL5){ #Rule 14f
                        if($Words1[$k - 1] eq $ListL5[$m]){  
                            $Words1[$k] = "likev"; 
                            last;
                        }    
                    }
                }
                
                if($Words1[$k] =~ /\blike\b/){
                    if($Words1[$k - 1] =~ /\bt\b/){ #Rule 14b
                        for my $m(0..$#ListL6){ #Rule 14b1
                            if($Words1[$k - 2] eq $ListL6[$m]){
                                $Words1[$k] = "likev";
                                last;
                            }
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/){
                    if($Words1[$k - 1] =~ /\bnot\b/){ #Rule 14c
                        #print "Here1\n";
                        my $Hit = 0;
                        for my $m(0..$#ListL7){ #Rule 14c1
                            if($Words1[$k - 2] eq $ListL7[$m]){
                                $Words1[$k] = "likev";
                                $Hit++;
                                last;
                            }
                        }

                    }
                }
                
                if($Words1[$k] =~ /\blike\b/){
                    for my $m(0..$#ListL8){#Rule 14d
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
                    if($k < $#Words1 - 1 && $Words1[$k + 1] =~ /\bto\b/){#Rule 14h
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
                    if($k > 0 && $k < $#Words1){#Rule 14i
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
                            if($Words1[$k + 1] eq $ListL12[$m]){#Rule 14i2  
                                $Words1[$k] = "likec";
                                last;
                            }
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/){
                    for my $m(0..$#ListL13){   
                        if($Words1[$k + 1] eq $ListL13[$m]){#Rule 14i2  
                            $Words1[$k] = "likev";
                            last;
                        }
                    }
                }
                if($Words1[$k] =~ /\blike\b/){
                    if($k > 0 && $k < $#Words1){
                        for my$m(0..$#ListL14){#Rule 14i3
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
            }

            for my $x(0..$#Words1){
                
                if($Words1[$x] =~ /\bwell\b/ && $Words1[$x - 1] =~ /\bas\b/){
                    $Words1[$x] = "wellc";
                    next;
                }
            }
            for my $x(0..$#Words1){
                #print "$Words1[$x]\n";
                
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
                    if($Words1[$k + 1] =~/\bimean\b/){
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
                if($Words1[$k] =~ /\bimeand\b/){
                    $Words1[$k] = "imean";
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
    my(@OutputC,@OutputM);
    
    for my $i(0..$#Sents){
        if($Sents[$i] =~ /\w+/){
            
            if($i < $#Sents && $Sents[$i + 1] =~ /\w+/){
                print LogFile "ERROR 6: Problem with splits at $Sents[$i] \n $Sents[$i + 1]\n";
                print "ERROR 6: Problem with splits at $Sents[$i] \n $Sents[$i + 1]\n";
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
                        
                        push @OutputC,$SentsC[$i][$k];
                        
                        
                        my $NewWord = &MPrep($SentsC[$i][$k]);
                        
                        my @NewWords = split "@", $NewWord;
                        for my $q(0..$#NewWords){
                            if($NewWords[$q] =~ /\w/){
                                push @OutputM,$NewWords[$q];
                                $GWordN++;
                            }
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
                        
                            push @OutputM, $Split1[$m];
                            
                        
                    }
                    
                }else{
                    
                    push @OutputC,$SentsC[$i][$#{$SentsC[$i]}];
                    
                    
                    
                    my $FinWord;
                    my $FinWordPrep = &MPrep($SentsC[$i][$#{$SentsC[$i]}]);
                    
                    my @FinWord1 = split /@/,$FinWordPrep;
                    if($#FinWord1 == 0){
                        $FinWord = $FinWord1[0].$Sents[$i + 1];
                        if($FinWord =~/\w/){
                            push @OutputM,$FinWord;
                            $GWordN++;
                        }
                        
                    }elsif($#FinWord1 == 1){
                        if($FinWord1[0] =~/\w/){
                            push @OutputM,$FinWord1[0];
                            $GWordN++;
                        }
                        my $Fin = $FinWord1[1].$Sents[$i + 1];
                        if($Fin =~/\w/){
                            push @OutputM,$Fin;
                            $GWordN++;
                        }
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
                       
                        push @OutputC,$SentsC[$i][$k];
                        my $NewWord = &MPrep($SentsC[$i][$k]);
                        my @NewWords = split "@", $NewWord;
                        for my $q(0..$#NewWords){
                            if($NewWords[$q] =~/\w/){
                                push @OutputM,$NewWords[$q];
                                $GWordN++;
                            }
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
    $Results[2] = $#OutputC;
    for my $i(0..$#OutputC){
        push @Results, $OutputC[$i];
    }
    for my $i(0..$#OutputM){
        push @Results, $OutputM[$i];
        
    }
    return @Results;
}


my @BigDic;
my @LD;
my %GTTList;
open(Dic,"TheDic") or die("Can't open TheDic \n");
while (<Dic>){
    chomp;
    push @BigDic,$_;
}

print "Please type the name of your subdirectory containing the files to be read\n";
chomp(my $Dir = <STDIN>);
print "Process words inside round but not square parentheses?\n Type 'y' or 'Y' for yes\n";
chomp(my $Response = <STDIN>);
if($Response eq 'y' || $Response eq 'Y'){
    $RParens++;
}
my $LOGF = $Dir."LOG.txt";

opendir DR, "$Dir"  or die("can't open directory: $!");
open(LogFile,">$Dir/DATA/$LOGF") or die("Can't open Logfile\n");

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
        print "The file name $TxtFiles[$w] contains more than one period (full stop). DAAP cannot process this file;\n";
        next;
    }
    for my $i(0..$#FileSplit){
        if ($FileSplit[$i] =~ /.*?_/){
            print "The file name $TxtFiles[$w] contains an underscore. DAAP cannot process this file;\n";
            die;
        }
    }
    my $C9Check = 0;
    my @NS;#NewStream
    my %LTTList;
    my @LLD;
    my $TN = 1; #TurnN using \t as turn markers
    my @TurnStream;
    my $TurnSwitch = 0;
    my $SpkrID = 0;
    my @Spkr;
    my $tCheck = 0;
    my $WordN = 0;
    my $FinWordN = 0;
    my $Paren = 0;
    my $NewName = $FileSplit[0].".c.txt";
    my $MTT = $FileSplit[0]."MTTFileTemp.txt";
    my $Temp = $FileSplit[0]."Temp.txt";
    open(InFile,"$Dir/$TxtFiles[$w]") or die("Can't open $TxtFiles[$w]\n");
    
    open(OutFile,">$Dir/$NewName") or die ("Can't write to $NewName\n");
    open(MTTFile,">$Dir/DATA/$MTT") or die ("Can't write to $MTT\n");
    
    print LogFile "\n\n We are now reading $TxtFiles[$w]\n\n";
    open(TFile,">$Dir/DATA/$Temp") or die("Can't write to Temp\n");
    
    while(<InFile>){
        my $Line = $_;
        
        $Line =~ \s/\015\010?/\n/g;
        #print "$Line\n";
        print TFile "$Line\n";
    }
    open(TFile,"$Dir/DATA/$Temp") or die("Can't read Temp\n");

    while(<TFile>){

        chomp;
        my $Line = $_;
        my $CLine;
        if(/^\[.*\]$/){
            print MTTFile "$Line\n";
            next;
        }
        if(/^.+\\/){
            print "ERROR 1: Backslash not at first character of line:\n";
            print LogFile "ERROR 1: Backslash not at first character of line:\n$Line\n\n";
        }
        if(/^\\c9/){
            $C9Check++;
            my $Stream = join " ",@TurnStream;
            my @ToSend = ($Stream,$WordN);
            #print "c9: $Stream, WordN = $WordN\n";
            my @Response = &Process(@ToSend);
            $WordN = $Response[0];
            my $LocLog = 0;
            $LocLog = $Response[1] + 1;
            if ($LocLog > 1){
                print "The Local LogFile for Turn $TN has $LocLog items\n";
                print LogFile "The above $LocLog items are for Turn $TN\n";
            }
            my $CItems = $Response[2];
            
            for my $i(3..$CItems + 3){
                if($Response[$i] =~ /\b\W?\W?(\w+)\W?\W?\b/){
                    $Response[$i] = $1;
                    print OutFile "$Response[$i] ";
                }
                
                if(exists $LTTList{$Response[$i]}){
                    $LTTList{$Response[$i]}++;
                }else{
                    $LTTList{$Response[$i]} = 1;
                }
                if(exists $GTTList{$Response[$i]}){
                    $GTTList{$Response[$i]}++;
                }else{
                    $GTTList{$Response[$i]} = 1;
                }
            }
            my @MFile;
            for my $i($CItems + 4..$#Response){
                push @MFile, $Response[$i];
            }
            my $RealSegNo = $TN - 1;
            print MTTFile "\n[Segment = $RealSegNo]\n";
            
            $TN++;
            for my $i(0..$#MFile){
                
                print MTTFile "$MFile[$i] ";
                $FinWordN++;

            }
           
            if($Response[1] =~ /^ERROR1/){
                print "ERROR 2: File ends with unmatched round or square parentheses\n";
                print LogFile "ERROR 2: File ends with unmatched round or square parentheses\n";
            }
            print OutFile "\n\\c9\n\n";
            print MTTFile "\n\\c9\n";
            print MTTFile "The number of words is $WordN\n";
            print MTTFile "The number of turns is $RealSegNo";
           
            if($Paren != 0){
                print LogFile "ERROR 2: Paren != 0 at end of file\n";
                print "ERROR 2: Paren != 0 at  end of file\n";
            }
            
            last;
        }
        if(/\s?\\t/){
            if(/\s?\\t\s+(\w+)\s?:\s?(\w+)/){
                
                
                $tCheck++;
                #if($TN > 0){
                    my $Stream = join " ",@TurnStream;
                    if($#TurnStream > 0){
                        $TN++;
                    }
                    my @ToSend = ($Stream,$WordN);
                    my @Response = &Process(@ToSend);
                    $WordN = $Response[0];
            
                    my $LocLog = 0;
                    $LocLog = $Response[1] + 1;
                    if ($LocLog > 1){
                        print "The Local LogFile for Turn $TN has $LocLog items\n";
                        print LogFile "The above $LocLog items are for Turn $TN\n";
                    }
                    my $CItems = $Response[2];
                    
                    for my $i(3..$CItems + 3){
                        if($Response[$i] =~ /\b\W?\W?(\w+)\W?\W?\b/){
                            $Response[$i] = $1;
                            print OutFile "$Response[$i] ";
                        
                        
                            if(exists $LTTList{$Response[$i]}){
                                $LTTList{$Response[$i]}++;
                            }else{
                                $LTTList{$Response[$i]} = 1;
                            }
                            if(exists $GTTList{$Response[$i]}){
                                $GTTList{$Response[$i]}++;
                            }else{
                                $GTTList{$Response[$i]} = 1;
                            }
                        }
                    }
                    my @MFile;
                    for my $i($CItems + 4..$#Response){
                    
                    push @MFile, $Response[$i];
                    }
                    
                    for my $i(0..$#MFile){
                        print MTTFile "$MFile[$i] ";
                        $FinWordN++;

                    }
                    
                    print MTTFile "\n";
                   
                    if($Response[1] =~ /^ERROR1/){
                        print "ERROR 2: File ends with unmatched round or square parentheses\n";
                        print LogFile "ERROR 2: File ends with unmatched round or square parentheses\n";
                    }
                    for my $q(0..$#TurnStream){
                    pop @TurnStream;
                    }
                my $RealSegNo = $TN - 1;
                print OutFile "\n\\t $1:$2\n";
                print MTTFile "\n\\t $1:$2\n";
                print MTTFile "\n[Segment = $RealSegNo]\n";
            }else{
                print LogFile "ERROR 8: There is an improper \\t line: $Line\n; Segment: $TN \n";
                $LogWarn++;
            }
            
        }else{
            push @TurnStream,$Line;

        }
    }
    if($C9Check == 0){
        
        my $Stream = join " ",@TurnStream;
        my @ToSend = ($Stream,$WordN);
        
        my @Response = &Process(@ToSend);
        $WordN = $Response[0];
        
        my $LocLog = 0;
        $LocLog = $Response[1] + 1;
        if ($LocLog > 1){
            print "The Local LogFile for Turn $TN has $LocLog items\n";
            print LogFile "The above $LocLog items are for Turn $TN\n";
        }
        my $CItems = $Response[2];
        
        for my $i(3..$CItems + 3){
            if($Response[$i] =~ /\b\W?\W?(\w+)\W?\W?\b/){
                $Response[$i] = $1;
                
                print OutFile "$Response[$i] ";
            }

        }
        my @MFile;
        for my $i($CItems + 4..$#Response){
            push @MFile, $Response[$i];
        }
        
       
        $TN++;
        for my $i(0..$#MFile){
            print MTTFile "$MFile[$i] ";
            $FinWordN++;

        }
        
        if($Response[1] =~ /^ERROR1/){
            print "ERROR 2: File ends with unmatched round or square parentheses\n";
            print LogFile "ERROR 2: File ends with unmatched round or square parentheses\n";
        }
        my $RealTurns = $TN - 2;
        print OutFile "\n\\c9\n\n";
        print MTTFile "\n\\c9\n";
        print MTTFile "The number of words is $WordN\n";
        print MTTFile "The number of turns is $RealTurns\n";
       
        if($Paren != 0){
            print LogFile "ERROR 2: Paren != 0 at end of file\n";
            print "ERROR 2: Paren != 0 at  end of file\n";
        }
  
    }

    close MTTFile;
    my $MTTNewName = $FileSplit[0]."MTT.txt";
    
    open(MTTFile,"$Dir/DATA/$MTT") or die ("Can't read $MTT\n");
    open(OutFile,">$Dir/DATA/$MTTNewName") or die ("Can't write to $NewName\n");
    print "\n\n We are now reading $TxtFiles[$w]\n\n";
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
    
	print OutFile "$_\n";
    }
    unlink "$Dir/DATA/$MTT", "$Dir/DATA/$Temp";
}

