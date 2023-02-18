=NOTE

This is DAAP09.6. the latest version of multispeaker DAAP. This version includes NADF, which is a Disfluency dictionary without
words, only incomplete words and repeated words and pairs of repeated words are counted.
NADF operates only when the DF dictionary is in the Dics subfolder.

DAAP09.6 has the facility to compare words in textfiles with ZDictionaries.
These are weighted dictionaries using wordstems, rather than words.

This is program is designed to operate with predaap09.pl, which must be run first.

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

my $ZIntNeutral = .5;
my $ZValNeutral = .5;
my %MultiDic;
my %DicScore;
my %ZDicScore;
my @DicNames;

my $DFDic = -1;
my $WDic = 0;
my @WDics;
my %WtDics;
my %ZMultiDic;
my @ZDics;
my %ZDics;
my @ZStems;
my %ZMatTT;
sub Max{
	my $MaxV=$_[0];
	if($_[1]>$MaxV){
			$MaxV=$_[1];
	}
	return $MaxV;
}
sub Min{
	my $MinV=$_[0];
	if($_[1]<$MinV){
			$MinV=$_[1];
	}
	return $MinV;
}

my $ParaM = 100; #These are the smoothing parameters and can be changed
my $ParaQ = 2.0;
my $TotalWgt = 0;
for(my $j = 1;$j < $ParaM;$j++){
	$TotalWgt += 2*exp(-$ParaQ*(($ParaM)**2)*($ParaM**2+$j**2)/(($ParaM**2-$j**2)**2));
}
$TotalWgt += exp(-$ParaQ);
sub Wts{ 
	my $i = $_[0];
	my $Weight = exp(-$ParaQ*(($ParaM)**2)*($ParaM**2+$i**2)/(($ParaM**2-$i**2)**2));
	return $Weight;
}
sub Sth{ #This is the smoothing function; it uses the above weight function
	my $Place = $_[$#_];
	my @Vals;
	for(my $i = 0;$i <= $#_;$i++){
		push @Vals,$_[$i];
	}
	for(my $i = 0;$i <= $#_;$i++){
		push @Vals,$_[$#_ - $i];
	}
	my $Mod = $#Vals + 1;
	my @Smooth;
	for(my $i = 0; $i <= $#_;$i++){
		my $Avg = 0;
		for(my $j = 1;$j < $ParaM;$j++){
			if($i - $j < 0){
				my $k = ($j - $i - 1) % $Mod;
				$Avg+=$Vals[$k]*&Wts($j);
			}else{
				my $k = ($i - $j) % $Mod;
				$Avg+=$Vals[$k]*&Wts($j);
			}
		}
		for(my $j = 0;$j < $ParaM;$j++){
			my $k = ($i + $j) % $Mod;
			$Avg+=$Vals[$k]*&Wts($j);
		}
		$Avg = $Avg/$TotalWgt;
		push @Smooth,$Avg;
	}
	return @Smooth;
}

sub Sum{
	my @RawDat=@_;
	my $TSum=0;
	for(my $i1=0;$i1<=$#RawDat;$i1++){
		$TSum+=$RawDat[$i1];
	}
	return $TSum;
}
		
sub Mean{
	my @RawDat = @_;
	my $TSum=&Sum(@RawDat);
	my $Avg=0;
	if(defined $RawDat[0]){
		$Avg = $TSum/($#RawDat+1);
	}else{
		$Avg=0;
	}
	return $Avg;
}
sub StanDev{
	my @RawDat=@_;
	my $Avg=&Mean(@RawDat);
	my $TVar=0;
	my $SDev=0;
	for(my $i2=0;$i2<=$#RawDat;$i2++){
		$TVar+=($RawDat[$i2]-$Avg)**2;
	}
	if($TVar>0){
		$SDev=sqrt($TVar/($#RawDat+1));
	}else{
		$SDev=0;
	}
	return $SDev;
}

sub Covar{ #Note that this is a cosine measure; it depends on the mean or neutral values put at the end of each array
	if($#_ % 2 != 1){
		print "unequal number of items for Covar.\n";
	}
	my @List1;
	my @List2;
	my $Mean1 = 0;
	my $Mean2 = 0;
	my $Sum = 0;
	my $Var1 = 0;
	my $Var2 = 0;
	for(my $i=0;$i<=($#_-3)/2;$i++){
		push @List1,$_[$i];
	}
	$Mean1 = $_[($#_ - 1)/2];
	
	for(my $i=(($#_-1)/2)+1;$i<$#_;$i++){
		push @List2,$_[$i];
	}
	
	$Mean2=$_[$#_];
	for(my $i=0;$i<=$#List1;$i++){
		$Sum+=($List1[$i]-$Mean1)*($List2[$i]-$Mean2);
	}
	
	my $Corr = 0;
	for (my $i = 0;$i<=$#List1;$i++){
		$Var1+= ($List1[$i] - $Mean1)**2;
		$Var2+= ($List2[$i] - $Mean2)**2;
	}
			
	if($Var1>0&&$Var2>0){
		$Corr=$Sum/sqrt($Var1*$Var2);
	}
	my $SD1 = 0;
	my $SD2 = 0;
	$SD1 = &StanDev(@List1);
	$SD2 = &StanDev(@List2);
	if($SD1 == 0 || $SD2 == 0){
		$Corr = 0;
	}
	return $Corr;
}
my $NADFDic = 0;

my @AggCats;
my %Global;
my @GWordCt;
my $GSpkN = 2;
my $ZDics = 0;
my %ZUnusual;
print "Please type the name of your subdirectory containing the files to be read\n";
chomp(my $Dir = <STDIN>);


opendir(DicDir,"$Dir/Dics") or die("Failed to open Dic SubDirectory");
my @Dics = grep /^\w+\.?/, readdir DicDir; #Make list of Dic files in $Dir

for(my $i = 0;$i <= $#Dics;$i++){

	$_ = $Dics[$i];
	if($_ eq "DF"){ #The  DF file is special
		$DFDic = $i;
		$NADFDic = 1;
	}
	if(/(\w+)\.Wt/){ #These are weighted dics
	
		open(Dic,"$Dir/Dics/$Dics[$i]") or die ("Can't open this $Dics[$i]\n");
		$Dics[$i] = $1;
		push @WDics, $i;
		$WtDics{$i} = $1;
		
		while(<Dic>){
			chomp;
			if(/^(\w+)\s+(-?\.?\d+)/){
				if(exists $MultiDic{$1}){
					for my $j($DicScore{$1} + 1..$i - 1){
						$MultiDic{$1}[$j] = 0;
					}
					$MultiDic{$1}[$i] = $2;
					$DicScore{$1} = $i;
					
				}else{
					for(my $j = 0;$j < $i;$j++){
						$MultiDic{$1}[$j] = 0;
					}
					$MultiDic{$1}[$i] = $2;
					$DicScore{$1} = $i;
				}
			}
		}
	}elsif(/(\w+)\.ZWt/){
		open(Dic,"$Dir/Dics/$Dics[$i]") or die ("Can't open this $Dics[$i]\n");
		$Dics[$i] = $1;
		push @ZDics, $i;
		$ZDics{$i} = $1;
		while(<Dic>){
			chomp;
			if(/^(\w+)\s+(-?0\.\d+)/){
				
				if(exists $ZMultiDic{$1}){
					
					$ZMultiDic{$1}[$ZDics] = $2;
					$ZDicScore{$1} = $i;
					
				}else{
					
					$ZMultiDic{$1}[$ZDics] = $2;
					$ZDicScore{$1} = $i;
				}
			}
		}
		$ZDics++;
	
		
	}else{
		open(Dic,"$Dir/Dics/$Dics[$i]") or die ("Can't open $Dics[$i]\n");
		
		while(<Dic>){
			chomp;
			s/\015/\n/g;
			if(/(\w+)/){
			
				if(exists $MultiDic{$1}){
					for my $j($DicScore{$1} + 1..$i - 1){
						$MultiDic{$1}[$j] = 0;
					}
					$MultiDic{$1}[$i] = 1;
					$DicScore{$1} = $i;
				
				}else{
					for(my $j = 0;$j < $i;$j++){
						$MultiDic{$1}[$j] = 0;
					}
					$MultiDic{$1}[$i] = 1;
					$DicScore{$1} = $i;
				}
			}
		}
	}
}
foreach my $Stem(sort keys %ZMultiDic){
	push @ZStems, $Stem;
}
foreach my $Dic (keys %MultiDic){
	if($DicScore{$Dic} != $#Dics){
		for my $i($DicScore{$Dic} + 1..$#Dics){
			$MultiDic{$Dic}[$i] = 0;
		}
	}
}


my %NewWtDics;
my %NewZDics;
my @NewDics;

if($NADFDic == 0){

	for my $i(0..$#Dics){
		$NewDics[$i] = $Dics[$i];
		
	}
	
	foreach my $Dic (%WtDics){
		$NewWtDics{$Dic} = $WtDics{$Dic};
	}
	foreach my $Dic (%ZDics){
		$NewZDics{$Dic} = $ZDics{$Dic};
	}
	
}elsif($NADFDic > 0){
	$NewDics[0] = "NADF";
	
	for my $i(0..$#Dics){
		$NewDics[$i + 1] = $Dics[$i];
		if(exists $WtDics{$i}){
			$NewWtDics{$i + 1} = $WtDics{$i};
		}
		if(exists $ZDics{$i}){
			$NewZDics{$i + 1} = $ZDics{$i};
		}
	}
	for my $i(0..$#WDics){
		$WDics[$i]++;
	}
	for my $i(0..$#ZDics){
		$ZDics[$i]++;
	}
	$DFDic++;
}

my $NewLOL = $Dir."NewLOL.txt";
my $TTGlob = $Dir."TTGlob.csv";
my $TTSGlob = $Dir."TTSGlob.txt";
my $LOGF = $Dir."LOGF.txt";
my $AG0F = $Dir."AG0.csv";
my $AG1F = $Dir."AG1.csv";
my $AG1SD = $Dir."AG1SSD.csv";
my $AG2F = $Dir."AG2.csv";
my $AG2SD = $Dir."AG2SSD.csv";
my $GLBF = $Dir."GLB.csv";
my $TRNF = $Dir."TRN.csv";
my $ZMat = $Dir."ZMat.txt";
my $DATA = "DATA";
my @BadWords;
my @GSpkr;
open(ZBad,"ZBad.txt") or die("Can't read ZBad\n");
while (<ZBad>){
	chomp;
	push @BadWords,$_;
}
my(@ZChangeFrom,@ZChangeTo);
open(ZChange,"ZChange.txt") or die ("Can't read ZChange\n");
while (<ZChange>){
	chomp;
	my @Change = split /\,/,$_;
	push @ZChangeFrom,$Change[0];
	push @ZChangeTo,$Change[1];
}
open (OldLOL,"TheDic") or die("Can't open TheDic\n");
my %OLOL;
while (<OldLOL>){
	chomp;
	if(exists $OLOL{$_}){
		$OLOL{$_}++;
	}else{
		$OLOL{$_} = 1;
	}
}
my %NewLOL;
opendir DR, "$Dir"  or die("can't open directory: $!");

open(LogFile,">$Dir/DATA/$LOGF") or die("Can't open Logfile\n");
open(Ag0File,">$Dir/DATA/$AG0F") or die("Can't  open Ag0File\n");
open(Ag1File,">$Dir/DATA/$AG1F") or die("Can't open AG1File\n");
open(Ag1SDFile,">$Dir/DATA/$AG1SD") or die("Can't open AG1SDFile\n");
open(Ag2File,">$Dir/DATA/$AG2F") or die("Can't open AG2File\n");
open(Ag2SDFile,">$Dir/DATA/$AG2SD") or die("Can't open AG2SDFile\n");
open(GlbFile,">$Dir/DATA/$GLBF") or die("Can't open GLBFile\n");
open(TRNFile,">$Dir/DATA/$TRNF") or die("Can't open TRNFile\n");
open(TTGFile,">$Dir/DATA/$TTGlob") or die("Can't write to TTGlob\n");
open(TTSGFile,">$Dir/DATA/$TTSGlob") or die("Can't write to TTSGlob\n");
open(LOLFile,">$Dir/DATA/$NewLOL") or die("Can't write to NewLOL\n");
open(ZMatFile,">$Dir/DATA/$ZMat") or die("Can't open ZMatFile\n");
print "Please type the category names you wish to aggregate for the .Ag2 file\n";
print "For example, if your categories are time, place and person, and you with to \n";
print "aggregate across time only, type time; if you wish to aggregate across both  time\n";
print "and place, type time:place; if you wish to aggregate across all three, type \n";
print "time:place:person, etc\n";
chomp(my $Aggregs = <STDIN>);
@AggCats = split /:/,$Aggregs;
my %TTGlob;
my @TTSGlob;
my $CoVarSwitch = 0;
print "Do you wish to skip covariations; if you type y or Y, DAAP will not produce any covariations\n";
chomp(my $Covar = <STDIN>);
if($Covar eq "y" || $Covar eq "Y"){
	$CoVarSwitch = 1;
	
}

my @TxtFiles;
foreach my $File (readdir DR){
    $_ = $File;
    if(/\.c.txt/){
	unless(/^\./){
		push @TxtFiles,$File;
	}
    }
}

my %LOLList;
my(@GSum,@GWtSum,@GWtSumN);
print GlbFile "File,Words,Turns,";
for my $i(0..$#NewDics){
        
        print GlbFile "$NewDics[$i]Mat,$NewDics[$i]Cov,";
}
        print GlbFile "\n";
for my $i(0..$#NewDics){
        for my $j(0..$GSpkN){
                $GSum[$i][$j] = 0;
        }
}
for(my $w = 0; $w <= $#TxtFiles;$w++){
	my @DicReads;
	my @ZDicReads;
	print LogFile "\n\nWe are now reading $TxtFiles[$w]\n\n\n";
	my @FileSplit=split /\./, $TxtFiles[$w];
	
 	my $Raw="RAW.csv";
        my $Smt="SMT.csv";
	my $TTR = "TTR.txt";
	my %Speakers;
	my $WrdF=$FileSplit[0].$Raw;
        my $SmtF=$FileSplit[0].$Smt;
	my $TTRF = $FileSplit[0].$TTR;
	open(InFile,"$Dir/$TxtFiles[$w]") or die("Can't open $TxtFiles[$w]");
	open(WrdFile, ">$Dir/DATA/$WrdF") or die("Failed to open Wrdfile");
        open(SmtFile, ">$Dir/DATA/$SmtF") or die("Failed to open Smtfile");
	open(TTRFile,">$Dir/DATA/$TTRF") or die("Failed to open TTRFile");
	print "DAAP09 is now reading $TxtFiles[$w]\n";

	#Finished making the output files
		
	my $Paren=0;
	my $WordN=0;
	my @DicMatch;
	my $LogWarn = 0;
	my $LocWdN = 0; 
	my @Spkr;
	my $SpkrID=0;
	my $TurnN=0;
	my @TurnWds;
	$TurnWds[0]=0;
	my %CatIndx; 
	my @CatList;
	my @LocCat;
	my @GlobCat;
	my $CatSwitch=0;
	my %LolList;
	my %TTR;
	my %TTList;
	my @DWB;
	my @DWBN;
	my @DWBG;
        my @WordBank;
	my @ZWordBank;
	my @NADF;
	my @NADFG;
	while(<InFile>){
		chomp;
		my $Line=$_;
		my @NewLine;
		my $LocWds=0;
		my $Words=0;

		if(/(.+\\.*)/){
			print LogFile "ERROR 1:Backslash not at first character in Line: $1\n";
			print  "ERROR 1: Backslash not at first character in Line:\n $1\n";
			die;
		}

		if(/^\\c9/){
						
			for(my $i = 0;$i <= $#DWBN;$i++){
			push @DWBG,$DWBN[$i];
			}
			for my $i(0..$#NADF){
				push @NADFG,$NADF[$i];
			}
			push @TurnWds, $WordN;
			print GlbFile "$TxtFiles[$w],$WordN,$TurnN,";
			if($Paren!=0){
				print LogFile "ERROR 2:There is an unmatched open parentheses somewhere. Look in the mtt.txt file.\n";
				print LogFile "Look for the place where the word count markers ([n]) stop appearing.\n";
				print "ERROR 2: end of file reached with unmatched parentheses\n";
				die;
			}
			last;
		} 
		if($CatSwitch>0){
			if(/^\\t\s*(\w+):(\w+)\s*$/){
				$LocCat[$CatIndx{$1}]=$2;
				
				next;			
			}elsif(/^\\s\s*(\d+)(.*)/){ 
				push @Spkr, $1;
				$LocWdN=0;    
				$SpkrID=$1;
				for(my $i = 0;$i <= $#DWBN;$i++){
					push @DWBG,$DWBN[$i];
				}
				for my $i(0..$#NADF){
					push @NADFG,$NADF[$i];
				}
				if($#DWB != $#DWBN){
					print "DWB and DWBN have different numbers of elements\n";
				}
				if($#NADF != $#DWBN){
					print "DWBN and NADF have different numbers of elements\n";
				}
				my $NNN = $#DWB;
				for(my $i = 0;$i <= $NNN;$i++){
					pop @DWB;
					pop @DWBN;
					pop @NADF;
				}
				
				if(exists $Speakers{$1}){
					$Speakers{$1}++;
				}else{
					$Speakers{$1} = 1;
				}
				my $RealTurn = $TurnN + 1;
				
				for(my $k1=0;$k1<=$#CatList;$k1++){
					$GlobCat[$k1][$TurnN]=$LocCat[$k1];
				}
				push @TurnWds, $WordN;
				$Line=$2;    
				$TurnN++;	
			}
		}
		if($CatSwitch==0){
			if(/^[^\\]/){
				
				next;
			}elsif(/^\\st/ || /^\\sc/){
				
				next;
			
			}elsif(/^\\t\s*(\w+):(\w+)\s*$/){
				push(@CatList,$1);
				$CatIndx{$1}=$#CatList;
				$LocCat[$#CatList]=$2;
				$GlobCat[$#CatList][0]=$2;
				
				next;
			}
			elsif(/^\\s\s*(\d+)\s+(.*)/){
				push @Spkr, $1;
				$LocWdN=0;    
				$SpkrID=$1;
				$TurnN++;
				$CatSwitch++;
				
				$Line=$2;

			}
		}
		my $Switch = 0;
		my @Words1=split /([\(\[\)\]])/, $Line;    
		foreach my $Word1(@Words1){
			if($Word1 eq "("){  
				
				$Paren++;
			}elsif($Word1 eq ')'){  
				$Paren--;
				
			}elsif($Word1 eq '['){
				$Paren++;
				
			}elsif($Word1 eq ']'){
				$Paren--;
				
			
			}else{
				if($Paren<0){   
					print LogFile "ERROR 3: Improper parentheses at\n $Line\n";
					print "ERROR 3: Improper parentheses at\n $Line\n";
					die;
				}elsif($Paren>0){ 
					
				}else{
				
					my @Words2=split /\s+/,$Word1; 
					foreach my $Word2 (@Words2){
						my @Words3=split /([\.,\сур'"р";:!\?\*\+\/])/,$Word2;
					
						foreach my $Word3 (@Words3){
							$_=$Word3;
							if(/\.|,|"|"|;|:|р|р|\с|!|\?|у|\*|\+|\/|^-$|\'/){
								
						
							}elsif(/^\w+-?/){ 
								$WordN++;
								$LocWdN++;
                                                                push @WordBank,$Word3;
								
								
								$Word3=lc $Word3;
								for my $r(0..$#{$MultiDic{$Word3}}){
								}
								push @DWB, $Word3;
								if(/\w+-$/){
									push @DWBN,1;
									push @NADF,1;
								}elsif(/(\w+)dx/){
								
									push @DWBN,1;
									push @NADF,0;
									$Word3 = $1;
                                                                        
								}elsif($MultiDic{$Word3}[$DFDic - 1] == 1){
								
									push @DWBN,1;
									push @NADF,0;
								}else{
									
									push @DWBN,0;
									push @NADF,0;
								}
								if($#DWB > 0){
									if($DWB[$#DWB] eq $DWB[$#DWB - 1]){
										$NADF[$#NADF] = 1;
										if($DWBN[$#DWB - 1] == 0){
											$DWBN[$#DWB - 1] = 1;
										}
									}
								}
								if($#DWB > 2){
									if($DWB[$#DWB] eq $DWB[$#DWB - 2] && $DWB[$#DWB - 1] eq $DWB[$#DWB - 3]){
										$NADF[$#NADF] = 1;
										if($DWBN[$#DWB - 2] == 0 && $DWBN[$#DWB - 3] == 0){
											$DWBN[$#DWB - 2] = 1;
											
										}
									}
								}
								my $WordSw = 0;
								my $Indx = $#DicReads;
								if($Word3 =~ /-$/){
									for my $m(1..$#NewDics){
										$DicReads[$Indx + 1][$m] = 0;
										
									}
									push @ZWordBank, "DF";
								}else{
									if($NADFDic == 0){
										for my $m(0..$#NewDics - $#ZDics - 1){
											if($MultiDic{$Word3}[$m] != 0){
												$WordSw++;
												$DicReads[$Indx + 1][$m] = $MultiDic{$Word3}[$m];
											}else{
												$DicReads[$Indx + 1][$m] = 0;
											}
										   
										}
									}elsif($NADFDic > 0){
										
										for my $m(1..$#NewDics - $#ZDics - 1){
											if($MultiDic{$Word3}[$m - 1] != 0){
												
												$WordSw++;
												$DicReads[$Indx + 1][$m] = $MultiDic{$Word3}[$m - 1];
											}else{
												$DicReads[$Indx + 1][$m] = 0;
											}
										   
										}
										
									}
									
									my @Mats;
									my $RealMat;
									my $Hit1 = 0;
									my $Hit2 = 0;
									my $Hit3 = 0;
									
									for my $q(0..$#BadWords){
										if($Word3 eq $BadWords[$q]){
											$Hit1++;
											last;
										}
									}
									if($Hit1 > 0){
										my $Temp = "Bad";
										push @ZWordBank,$Temp;
										for my $m(0..$#ZDics){
											$DicReads[$Indx + 1][$#NewDics - $#ZDics + $m] = 0;
										}
																		
										
									}elsif($Hit1 == 0){
										for my $q(0..$#ZChangeFrom){
											if($Word3 eq $ZChangeFrom[$q]){
												$RealMat = $ZChangeTo[$q];
												$Hit2++;
												last;
											}
											if(exists $ZMatTT{$Word3}){
											}else{
												$ZMatTT{$Word3} = $RealMat;
											}
										}
										if($Hit2 > 0){
											push @ZWordBank,$RealMat;
											for my $m(0..$#ZDics){
												if($ZMultiDic{$RealMat}[$m] != 0){
										
													$DicReads[$Indx + 1][$#NewDics - $#ZDics + $m] = $ZMultiDic{$RealMat}[$m];
												}else{
													$DicReads[$Indx + 1][$#NewDics - $#ZDics + $m] = 0;
												}
											}
											
										}elsif($Hit2 == 0){
											for my $q(0..$#ZStems){
												if($Word3 =~ /^$ZStems[$q]/){
													push @Mats, $ZStems[$q];
												}
											}
											if($#Mats >= 0){
												$RealMat = $Mats[0];
												if($#Mats > 0){
													$Hit3++;
													$RealMat = $Mats[0];
													for my $j(1..$#Mats){
														if(length($Mats[$j]) > length($RealMat)){
															$RealMat = $Mats[$j];
														}
													}
													if(exists $ZMatTT{$Word3}){
													}else{
														$ZMatTT{$Word3} = $RealMat;
													}
													if(exists $ZUnusual{$Word3}){
														
													}elsif(length($Word3) > length($RealMat)){
														$ZUnusual{$Word3} = $RealMat;
													}
													
													
												}
												push @ZWordBank,$RealMat;
												for my $m(0..$#ZDics){
													if($ZMultiDic{$RealMat}[$m] != 0){
														$DicReads[$Indx + 1][$#NewDics - $#ZDics + $m] = $ZMultiDic{$RealMat}[$m];
													}else{
														$DicReads[$Indx + 1][$#NewDics - $#ZDics + $m] = 0;
													}
										
												}
												if(exists $ZMatTT{$Word3}){
												}else{
													$ZMatTT{$Word3} = $RealMat;
												}
											
											}else{
												my $Temp = "Nil";
												push @ZWordBank,$Temp;
												for my $m(0..$#ZDics){
													$DicReads[$Indx + 1][$#NewDics - $#ZDics + $m] = 0;
												}
												if(exists $ZMatTT{$Word3}){
												}else{
													$ZMatTT{$Word3} = $Temp;
												}
											}
										}
					
									}
									
									if($WordSw == 0){
										if(exists $OLOL{$Word3}){
											$WordSw++;
										}else{
											if(exists $NewLOL{$Word3}){
												$NewLOL{$Word3}++;
											}else{
												$NewLOL{$Word3} = 1;
											}
										}
									}
									if(exists $TTList{$SpkrID}){
										if(exists $TTList{$SpkrID}{$Word3}){
											$TTList{$SpkrID}{$Word3}++;
										}else{
											$TTList{$SpkrID}{$Word3} = 1;
										}
									}else{
										$TTList{$SpkrID}{$Word3} = 1;
									}
									
									if(exists $TTGlob{$Word3}){
										$TTGlob{$Word3}++;
									}else{
										$TTGlob{$Word3} = 1;
									}
									if(exists $TTSGlob[$SpkrID]{$Word3}){
										$TTSGlob[$SpkrID]{$Word3}++;
									}else{
										$TTSGlob[$SpkrID]{$Word3} = 1;
									}
								}
								
							}elsif($Word3 gt 0){ 
								
								print LogFile "ERROR 4:The Word $Word3 at Word Number $WordN is unusual\n";
								$LogWarn++;
								
							}
						}
					}
				}
			}
		}					
	}

	my @RawData;
	
	for (my $m = 0;$m <= $WordN;$m++){
		if ($DFDic >= 0 && $DWBG[$m] == 1){
			$DicReads[$m][$DFDic] = 1;
		}
		if($NADFDic > 0){
			$DicReads[$m][0] = $NADFG[$m];
			
		}
	}
	
	my $Start = $#NewDics - $#WDics - $#ZDics - 1;
	for(my $m = $Start;$m <= $#NewDics;$m++){
		for(my $p = 0;$p <= $#DicReads;$p++){
			$DicReads[$p][$m] = .5*$DicReads[$p][$m] +.5;
		}
	}
	
                     
	my %SpkrTnL;
	foreach my $Spkrno (@Spkr){
		if (exists $SpkrTnL{$Spkrno}){
			$SpkrTnL{$Spkrno}++;
		}else{
			$SpkrTnL{$Spkrno}=1;
		}
	}
	if($#Spkr!=$#TurnWds-1){
		print LogFile "ERROR 15: The number of items in the speaker array, $#Spkr, is not equal to the number of items, $#TurnWds, in the TurnWord array\n";
		print "ERROR 15: There is a problem with the number of turns; see the Log File.\n";
		$LogWarn++;
	}
	print "DAAP09 has finished reading your file and is now processing the data;\n please wait.\n";	

	my(@DataSmth,@STData);
	
	for(my $m=1;$m<=$#TurnWds;$m++){
		my @DataTList;

                for my $j (0..$#NewDics){
                        for my $k ($TurnWds[$m - 1]..$TurnWds[$m] - 1){
                                $DataTList[$j][$k - $TurnWds[$m - 1]] = $DicReads[$k][$j];
                                
                        }
                        push @{$DataSmth[$j]}, &Sth(@{$DataTList[$j]});
		}

	}
        
	my @BaseSpkL=sort keys %SpkrTnL;
	my $Temp;
	for(my $i = 0;$i<=$#BaseSpkL;$i++){
		my $Lowest = $i;
		for(my $j = $i+1;$j <= $#BaseSpkL;$j++){
			if($BaseSpkL[$j] < $BaseSpkL[$Lowest]){
				$Lowest = $j;
			}
			$Temp = $BaseSpkL[$i];
			$BaseSpkL[$i] = $BaseSpkL[$Lowest];
			$BaseSpkL[$Lowest]=$Temp;
		}
	}
							
					
	if($BaseSpkL[$#BaseSpkL] != $#BaseSpkL + 1){
		my $SNo = $#BaseSpkL + 1;
		print "The number of speakers is $SNo,\n";
		print "but the highest numbered speaker is $BaseSpkL[$#BaseSpkL].\n";
		print "DAAP cannot process this file until this anamoly is resolved.\n";
		print "do you want to see a list of the speaker numbers [y/n]\n";
		chomp(my $Answer = <STDIN>);
		$Answer = lc $Answer;
		if($Answer eq 'y'){
			print "The speakers in this text are numbered: ";
			for(my $m = 0;$m <= $#BaseSpkL;$m++){
				print "$BaseSpkL[$m], ";
				
			}
		}
		die("DAAP requires the list of speakers to have no gaps");
	}
        if($#BaseSpkL + 1 != $GSpkN){
                $GSpkN =$#BaseSpkL + 1;
        }
	if($#GSpkr == -1){
		for my $q(0..$#BaseSpkL){
			$GSpkr[$q] = $BaseSpkL[$q];
		}
	}elsif($#GSpkr >= 0 && $#BaseSpkL > $#GSpkr){
		for my $q($#GSpkr + 1..$#BaseSpkL){
			$GSpkr[$q] = $BaseSpkL[$q];
		}
	}
		
	
        print WrdFile "Word,Spkr,";
        for my $j(0..$#NewDics){
                print WrdFile "$NewDics[$j],";
        }
	for(my $j = 1;$j <= $#BaseSpkL + 1;$j++){
		for(my $k = 0;$k <= $#NewDics;$k++){
			print SmtFile "$NewDics[$k](S$j),";
		}
		
	}
	if($#ZDics > -1){
		print WrdFile "ZMat,\n";
	}else{
		print WrdFile "\n";
	}
        print SmtFile "\n";#This completes the top row of the RAW (Word) and smooth files

	for(my $i=1;$i<=$#TurnWds;$i++){
                
		for(my $j=$TurnWds[$i-1];$j<$TurnWds[$i];$j++){
			for(my $k=1;$k < $Spkr[$i-1];$k++){
				for(my $m = 0;$m <= $#NewDics;$m++){
				
                                        print SmtFile ",";
                                        
				}
			}
			print WrdFile "$WordBank[$j],$Spkr[$i - 1],";
			for(my $q = 0;$q <= $#NewDics;$q++){
				
                                
                                print WrdFile "$DicReads[$j][$q],";

			}
			for(my $q = 0;$q <= $#NewDics;$q++){
				
                                print SmtFile "$DataSmth[$q][$j],";
                                

			}
			if($#ZDics > -1){
				print WrdFile "$ZWordBank[$j]\n";
			}else{
				print WrdFile "\n";
			}
                        print SmtFile "\n";
 
		}
	}	
	print "DAAP09 has produced the raw and smooth data files\n";
	
	print TRNFile "File,TurnNo,Spkr,";
	
	
	for(my $i=0;$i<=$#CatList;$i++){
		print TRNFile "$CatList[$i],";
		
	}
	print TRNFile "WordNo,FirstWd,";
	for(my $j = 0;$j<= $#NewDics;$j++){
		print TRNFile "M$NewDics[$j],";
   
	}
        for my $j (0..$#WDics){
                print TRNFile "MH$NewDics[$WDics[$j]],HP$NewDics[$WDics[$j]],"
        }
	for my $j(0..$#ZDics){
		print TRNFile "MH$NewDics[$ZDics[$j]],HP$NewDics[$ZDics[$j]],ML$NewDics[$ZDics[$j]],LP$NewDics[$ZDics[$j]],";
	}
	if($CoVarSwitch == 0){
		for(my $j = 0;$j < $#NewDics;$j++){
			for(my $k = $j + 1; $k <= $#NewDics;$k++){
				print TRNFile "$NewDics[$j]_$NewDics[$k],";
			
			}
		}
	}
	print TRNFile "\n"; #This completes the top row of the TrnFile
	
	
	my(@SpkWordN,@DataSum);
        
	for my $i (1..$#TurnWds){
				
		for(my $j=$TurnWds[$i-1];$j<$TurnWds[$i];$j++){
			$SpkWordN[$Spkr[$i - 1]]++;
			for(my $k = 0;$k<=$#NewDics;$k++){
				$DataSum[$Spkr[$i - 1]][$k]+=$DicReads[$j][$k];
			}
		}
	}
	my(@SpkWdSum,@DataMean0);
	for(my $i = 1;$i <=$#BaseSpkL + 1;$i++){
		for my $j (0..$#NewDics){
			$DataMean0[$i][$j] = 0;
		}
	}
		
	for(my $i = 1;$i <= $#BaseSpkL + 1;$i++){
		if($SpkWordN[$i] > 0){
			for(my $j = 0;$j <= $#NewDics;$j++){
				$DataMean0[$i][$j] = $DataSum[$i][$j]/$SpkWordN[$i];
			}
		}
			
	}

	my @GDataM0;
	
	for my $j(0..$#NewDics){
		my $GDataSum = 0;
		my $WordSum = 0;
		for my $i(1..$#BaseSpkL + 1){
			$GDataSum+= $DataSum[$i][$j];
			$WordSum += $SpkWordN[$i];
		}
		if($WordSum > 0){
			$GDataM0[$j] = $GDataSum/$WordSum;
		}else{
			$GDataM0[$j] = 0;
		}
	}
	
	for(my $i=0; $i<=$#Spkr;$i++){
		my $TurnNo = $i + 1;
		print TRNFile "$TxtFiles[$w],$TurnNo,$Spkr[$i],";
		
		for(my $k2=0;$k2<=$#CatList;$k2++){
			print TRNFile "$GlobCat[$k2][$i],";
			
		}
		my $WordCt=$TurnWds[$i+1]-$TurnWds[$i];
		print TRNFile "$WordCt,$TurnWds[$i],"; #This completes the basic data for each row
		
		my (@MeanData,@CoVars,@MHData,@HPData,@ZHData,@ZHDataN,@ZLData,@ZLDataN,@HDataN);
                my(@Data,@SmthData);
                for my $j(0..$#NewDics){
                        for my $k ($TurnWds[$i]..$TurnWds[$i + 1] - 1){
                                $Data[$j][$k - $TurnWds[$i]] = $DicReads[$k][$j];
                                $SmthData[$j][$k - $TurnWds[$i]] = $DataSmth[$j][$k];
                                if(exists $NewWtDics{$j} && $DataSmth[$j][$k] > .5){
                                        $MHData[$j] += $DataSmth[$j][$k] - .5;
                                        $HDataN[$j]++;
                                }
				if(exists $NewZDics{$j}){
					if($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] > $ZIntNeutral){
						$ZHData[$j] += $DataSmth[$j][$k] - $ZIntNeutral;
						$ZHDataN[$j]++;
					}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] > $ZValNeutral){
						$ZHData[$j] += $DataSmth[$j][$k] - $ZValNeutral;
						$ZHDataN[$j]++;
					}elsif($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] < $ZIntNeutral){
						$ZLData[$j] += $ZIntNeutral - $DataSmth[$j][$k];
						$ZLDataN[$j]++;
					}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] < $ZValNeutral){
						$ZLData[$j] += $ZValNeutral - $DataSmth[$j][$k];
						$ZLDataN[$j]++;
					}
				}
                        }
                }
                for my $j(0..$#NewDics){
                        $MeanData[$j] = &Mean(@{$SmthData[$j]});
                        print TRNFile "$MeanData[$j],";
                }
                my(@MH,@HP,@ZMH,@ZHP,@ZML,@ZLP);
                for my $k(0..$#WDics){
                        
                        $MH[$k] = 0;
                        $HP[$k] = 0;
                        if($HDataN[$WDics[$k]] > 0){
                               
                                $MH[$k] = $MHData[$WDics[$k]]/$HDataN[$WDics[$k]];
                                $HP[$k] = $HDataN[$WDics[$k]]/$WordCt;
                                
                        }
                        print TRNFile "$MH[$k],$HP[$k],";
		}
                for my $k(0..$#ZDics){
		
			$ZMH[$k] = 0;
			$ZHP[$k] = 0;
			$ZML[$k] = 0;
			$ZLP[$k] = 0;
			if($ZHDataN[$ZDics[$k]] > 0){
			       
				$ZMH[$k] = $ZHData[$ZDics[$k]]/$ZHDataN[$ZDics[$k]];
				if($WordCt> 0){
					$ZHP[$k] = $ZHDataN[$ZDics[$k]]/$WordCt;
				}else{
					$ZHP[$k] = 0;
				}
					
			}
			print TRNFile "$ZMH[$k],$ZHP[$k],";
			if($ZLDataN[$ZDics[$k]] > 0){
			       
				$ZML[$k] = $ZLData[$ZDics[$k]]/$ZLDataN[$ZDics[$k]];
				if($WordCt > 0){
					$ZLP[$k] = $ZLDataN[$ZDics[$k]]/$WordCt;
				}else{
					$ZLP[$k] = 0;
				}
			}
			print TRNFile "$ZML[$k],$ZLP[$k],";		
		}	
	
		if($CoVarSwitch == 0){
			for my $j(0..$#NewDics - 1){	
				for(my $j1 = $j + 1;$j1 <= $#NewDics;$j1++){
					$CoVars[$j][$j1] = 0;
				}
			}
			
			for my $j(0..$#NewDics){
				if(exists $NewWtDics{$j}){
					push @{$SmthData[$j]},0.5;
				
						
				}else{
					push @{$SmthData[$j]},$DataMean0[$Spkr[$i]][$j];
				}        
			}
				       
			for my $j(0..$#NewDics - 1){
				for my $k($j+1..$#NewDics){
					$CoVars[$j][$k] = &Covar(@{$SmthData[$j]},@{$SmthData[$k]});
					print TRNFile "$CoVars[$j][$k],";
				}
			}
		}
                
         	print TRNFile "\n";
                                		
	}
	print "DAAP09 has produced the Turn Data File\n";
	#Now we make the AG0File
		
	print Ag0File "File,Spkr,";
	print Ag0File "Words,Turns,";
	
	for my $j(0..$#NewDics){
		print Ag0File "M$NewDics[$j],";
	}
	
	for my $j (0..$#WDics){
                print Ag0File "MH$NewDics[$WDics[$j]],HP$NewDics[$WDics[$j]],";
        }
	for my $j(0..$#ZDics){
		print Ag0File "MH$NewDics[$ZDics[$j]],HP$NewDics[$ZDics[$j]],ML$NewDics[$ZDics[$j]],LP$NewDics[$ZDics[$j]],";
	}
	if($CoVarSwitch == 0){
		for(my $j = 0;$j < $#NewDics;$j++){
			for(my $k = $j + 1; $k <= $#NewDics;$k++){
				print Ag0File "$NewDics[$j]_$NewDics[$k],";
			}
		}
	}
	print Ag0File "\n"; #This completes the top line of the AG0 file
	for my $p(0..$#BaseSpkL){
		my (@SmthData,@MHData,@HDataN,@ZHData,@ZHDataN,@ZLData,@ZLDataN,@MeanData,@CoVars);
		my $Turns = 0;
		my $Words = 0;
		print Ag0File "$TxtFiles[$w],$BaseSpkL[$p],";
		
		for my $i(0..$#Spkr){
			if($Spkr[$i] != $BaseSpkL[$p]){
				next;
			}else{
				$Turns++;
				
				for my $j(0..$#NewDics){                                   
					for my $k ($TurnWds[$i]..$TurnWds[$i + 1] - 1){
						
						$SmthData[$j][$k - $TurnWds[$i] + $Words] = $DataSmth[$j][$k];
						if(exists $NewWtDics{$j} && $DataSmth[$j][$k] > .5){
							$MHData[$j] += $DataSmth[$j][$k] - .5;
							$HDataN[$j]++;                                        
						}
						if(exists $NewZDics{$j}){
							if($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] > $ZIntNeutral){
								$ZHData[$j] += $DataSmth[$j][$k] - $ZIntNeutral;
								$ZHDataN[$j]++;
							}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] > $ZValNeutral){
								$ZHData[$j] += $DataSmth[$j][$k] - $ZValNeutral;
								$ZHDataN[$j]++;
							}elsif($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] < $ZIntNeutral){
								$ZLData[$j] += $ZIntNeutral - $DataSmth[$j][$k];
								$ZLDataN[$j]++;
							}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] < $ZValNeutral){
								$ZLData[$j] += $ZValNeutral - $DataSmth[$j][$k];
								$ZLDataN[$j]++;
							}
						}
					}
				}
				$Words+= $TurnWds[$i+1] - $TurnWds[$i];
			}
		}
		print Ag0File "$Words,$Turns,";
		if($Words != 0){
                                
                        for my $j(0..$#NewDics){
                                $MeanData[$j] = &Mean(@{$SmthData[$j]});
			}
                }else{
			for my $j(0..$#NewDics){
				$MeanData[$j] = 0;
			}
		}
                for my $j(0..$#NewDics){
                        print Ag0File "$MeanData[$j],";
                }
		my(@MH,@HP,@ZMH,@ZHP,@ZML,@ZLP);
                for my $k(0..$#WDics){
                        
                        $MH[$k] = 0;
                        $HP[$k] = 0;
                        if($HDataN[$WDics[$k]] > 0){
                               
                                $MH[$k] = $MHData[$WDics[$k]]/$HDataN[$WDics[$k]];
                                if($Words > 0){
				$HP[$k] = $HDataN[$WDics[$k]]/$Words;
				}else{
					$HP[$k] = 0;
				}
                                        
                        }
		
                        print Ag0File "$MH[$k],$HP[$k],";
		}
		for my $k(0..$#ZDics){
	
			$ZMH[$k] = 0;
			$ZHP[$k] = 0;
			$ZML[$k] = 0;
			$ZLP[$k] = 0;
			if($ZHDataN[$ZDics[$k]] > 0){
			       
				$ZMH[$k] = $ZHData[$ZDics[$k]]/$ZHDataN[$ZDics[$k]];
				if($Words > 0){
					$ZHP[$k] = $ZHDataN[$ZDics[$k]]/$Words;
				}else{
					$ZHP[$k] = 0;
				}
					
			}
			print Ag0File "$ZMH[$k],$ZHP[$k],";
			if($ZLDataN[$ZDics[$k]] > 0){
			       
				$ZML[$k] = $ZLData[$ZDics[$k]]/$ZLDataN[$ZDics[$k]];
				if($Words > 0){
					$ZLP[$k] = $ZLDataN[$ZDics[$k]]/$Words;
				}else{
					$ZLP[$k] = 0;
				}
			}
			print Ag0File "$ZML[$k],$ZLP[$k],";		
	
		}
	
               
		if($CoVarSwitch == 0){
			for my $j(0..$#NewDics - 1){	
				for(my $j1 = $j + 1;$j1 <= $#NewDics;$j1++){
					$CoVars[$j][$j1] = 0;
				}
			}
		    
			for my $j(0..$#NewDics){
				if(exists $NewWtDics{$j}){
					push @{$SmthData[$j]},0.5;
				
				}else{
					push @{$SmthData[$j]},$DataMean0[$BaseSpkL[$p]][$j];
				}        
			}
				       
			for my $j(0..$#NewDics - 1){
				for my $k($j+1..$#NewDics){
					$CoVars[$j][$k] = &Covar(@{$SmthData[$j]},@{$SmthData[$k]});
					print Ag0File "$CoVars[$j][$k],";
					if($#{$SmthData[$j]}!= $#{$SmthData[$k]}){
						print "SmthData[$j] != SmthData[$k]\n";
					}
				}
			}
		}
                
                print Ag0File "\n";
			
	}
	my (@GData,@GMHData,@GHDataN,@GZHData,@GZHDataN,@GZLData,@GZLDataN,@GMeanData,@GCoVars);
	my $GWords = 0;
	my $GTurns = 0;
	print Ag0File "$TxtFiles[$w],All,";
	for my $i(0..$#Spkr){
		$GTurns++;
		
		
			
		for my $k ($TurnWds[$i]..$TurnWds[$i + 1] - 1){
			for my $j(0..$#NewDics){			
				$GData[$j][$GWords + $k - $TurnWds[$i]] = $DataSmth[$j][$k];
				if(exists $NewWtDics{$j} && $DataSmth[$j][$k] > .5){
					$GMHData[$j] += $DataSmth[$j][$k] - .5;
					$GHDataN[$j]++;                                        
				}
				if(exists $NewZDics{$j}){
					if($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] > $ZIntNeutral){
						$GZHData[$j] += $DataSmth[$j][$k] - $ZIntNeutral;
						$GZHDataN[$j]++;
					}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] > $ZValNeutral){
						$GZHData[$j] += $DataSmth[$j][$k] - $ZValNeutral;
						$GZHDataN[$j]++;
					}elsif($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] < $ZIntNeutral){
						$GZLData[$j] += $ZIntNeutral - $DataSmth[$j][$k];
						$GZLDataN[$j]++;
					}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] < $ZValNeutral){
						$GZLData[$j] += $ZValNeutral - $DataSmth[$j][$k];
						$GZLDataN[$j]++;
					}
				}
			}
			
		}
		$GWords += $TurnWds[$i + 1] - $TurnWds[$i];
	}
	print Ag0File "$GWords,$GTurns,";
		
	if($GWords != 0){
                                
                for my $j(0..$#NewDics){
                        $GMeanData[$j] = &Mean(@{$GData[$j]});
		}
        }else{
		for my $j(0..$#NewDics){
				$GMeanData[$j] = 0;
		}
	}
        for my $j(0..$#NewDics){
                print Ag0File "$GMeanData[$j],";
        }
	my(@MH,@HP,@ZMH,@ZHP,@ZML,@ZLP);
        for my $k(0..$#WDics){
                        
                $MH[$k] = 0;
                $HP[$k] = 0;
                if($GHDataN[$WDics[$k]] > 0){
                               
                        $MH[$k] = $GMHData[$WDics[$k]]/$GHDataN[$WDics[$k]];
		}else{
			$MH[$k] = 0;
		}
		if($GWords > 0){
                        $HP[$k] = $GHDataN[$WDics[$k]]/$GWords;
                                        
                }else{
			$HP[$k] = 0;
		}
                print Ag0File "$MH[$k],$HP[$k],";
        }
	
	for my $k(0..$#ZDics){
		
		$ZMH[$k] = 0;
		$ZHP[$k] = 0;
		$ZML[$k] = 0;
		$ZLP[$k] = 0;
		if($GZHDataN[$ZDics[$k]] > 0){
		       
			$ZMH[$k] = $GZHData[$ZDics[$k]]/$GZHDataN[$ZDics[$k]];
			if($GWords > 0){
			$ZHP[$k] = $GZHDataN[$ZDics[$k]]/$GWords;
			}else{
				$ZHP[$k] = 0;
			}
				
		}
		print Ag0File "$ZMH[$k],$ZHP[$k],";
		if($GZLDataN[$ZDics[$k]] > 0){
		       
			$ZML[$k] = $GZLData[$ZDics[$k]]/$GZLDataN[$ZDics[$k]];
			if($GWords > 0){
				$ZLP[$k] = $GZLDataN[$ZDics[$k]]/$GWords;
			}else{
				$ZLP[$k] = 0;
			}
		}
		print Ag0File "$ZML[$k],$ZLP[$k],";		
		
	}
	if($CoVarSwitch == 0){
		for my $j(0..$#NewDics - 1){	
			for(my $j1 = $j + 1;$j1 <= $#NewDics;$j1++){
				$GCoVars[$j][$j1] = 0;
			}
		}
		    
		for my $j(0..$#NewDics){
			if(exists $NewWtDics{$j}){
				push @{$GData[$j]},0.5;
			
			
			}else{
				push @{$GData[$j]},$GDataM0[$j];
			}        
		}
				       
		for my $j(0..$#NewDics - 1){
			for my $k($j+1..$#NewDics){
				$GCoVars[$j][$k] = &Covar(@{$GData[$j]},@{$GData[$k]});
				print Ag0File "$GCoVars[$j][$k],";
			}
		}
	}
                
        print Ag0File "\n";	
	

	#Now we make the basic aggregate data files: Ag1 and Ag1SD

	print Ag1File "File,Spkr,";
	print Ag1SDFile "File,Spkr,";
	
	for(my $i=0;$i<=$#CatList;$i++){
		print Ag1File "$CatList[$i],";
		print Ag1SDFile "$CatList[$i],";
	}
	
	print Ag1File "Words,Turns,";
	print Ag1SDFile "Words,Turns,";
	
	for(my $j = 0;$j<= $#NewDics;$j++){
		print Ag1File "M$NewDics[$j],";
		print Ag1SDFile "SD$NewDics[$j],";
		
	}
        for my $j (0..$#WDics){
                print Ag1File "MH$NewDics[$WDics[$j]],HP$NewDics[$WDics[$j]],";
		
        }
	for my $j(0..$#ZDics){
		print Ag1File "MH$NewDics[$ZDics[$j]],HP$NewDics[$ZDics[$j]],ML$NewDics[$ZDics[$j]],LPNew$Dics[$ZDics[$j]],";
	}
	if($CoVarSwitch == 0){
		for(my $j = 0;$j < $#NewDics;$j++){
			for(my $k = $j + 1; $k <= $#NewDics;$k++){
				print Ag1File "$NewDics[$j]_$NewDics[$k],";
				
			}
		}
	}
	print Ag1File "\n"; #This completes the top row of the Ag1File
	print Ag1SDFile "\n";
	
       
	my @AgList;
	my $CatSwitch1=0;
	for(my $i=0;$i<=$#Spkr;$i++){
		$AgList[$i]=0;
	}
	for(my $i=0; $i<=$#Spkr;$i++){
		if($AgList[$i]!=0){
			next;
		}else{
                        
                        print Ag1File "$TxtFiles[$w],$Spkr[$i],";
			print Ag1SDFile "$TxtFiles[$w],$Spkr[$i],";
			for(my $q6=0;$q6<=$#CatList;$q6++){
                                print Ag1File "$GlobCat[$q6][$i],";
				print Ag1SDFile "$GlobCat[$q6][$i],";
                        }
                        my $Count = 0;
                        my (@Ag1Data,@Ag1SmthData,@Ag1MeanData,@Ag1CoVars,@Ag1MHData,@Ag1HPData,@Ag1HDataN,@Ag1SDData);
			my(@Ag1ZHData,@Ag1ZHDataN,@Ag1ZLData,@Ag1ZLDataN);
                        my $WrdCt = 0;
                        for(my $j = 0;$j <= $#NewDics;$j++){
                                $Ag1MeanData[$j] = 0;
                                $DataSum[$j] = 0;
				$Ag1SDData[$j] = 0;
                        }
                        my $TurnN = 1;
                        $WrdCt += $TurnWds[$i + 1] - $TurnWds[$i];
                        
                        for my $j(0..$#NewDics){                                   
                                for my $k ($TurnWds[$i]..$TurnWds[$i + 1] - 1){
                                        
                                        $Ag1Data[$j][$k - $TurnWds[$i]] = $DicReads[$k][$j];
                                        $Ag1SmthData[$j][$k - $TurnWds[$i]] = $DataSmth[$j][$k];
                                        if(exists $NewWtDics{$j} && $DataSmth[$j][$k] > .5){
                                                $Ag1MHData[$j] += $DataSmth[$j][$k] - .5;
                                                $Ag1HDataN[$j]++;                                        
                                        }
						if(exists $NewZDics{$j}){
						if($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] > $ZIntNeutral){
							$Ag1ZHData[$j] += $DataSmth[$j][$k] - $ZIntNeutral;
							$Ag1ZHDataN[$j]++;
						}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] > $ZValNeutral){
							$Ag1ZHData[$j] += $DataSmth[$j][$k] - $ZValNeutral;
							$Ag1ZHDataN[$j]++;
						}elsif($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] < $ZIntNeutral){
							$Ag1ZLData[$j] += $ZIntNeutral - $DataSmth[$j][$k];
							$Ag1ZLDataN[$j]++;
						}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] < $ZValNeutral){
							$Ag1ZLData[$j] += $ZValNeutral - $DataSmth[$j][$k];
							$Ag1ZLDataN[$j]++;
						}
					}
                                }
                        }
                
                        for(my $k6=$i+1;$k6<=$#Spkr;$k6++){
                                if($AgList[$k6]!=0){#skip over turns already covered
                                        next;
                                }
                                if($Spkr[$k6]!=$Spkr[$i]){ #skip over other  speakers
                                        next;
                                }
                                for(my $m6=0;$m6<=$#CatList;$m6++){
                                        if($GlobCat[$m6][$k6] eq $GlobCat[$m6][$i]){
                                                next;
                                        }else{
                                                $CatSwitch1++;
                                                last;
                                        }
                                }
                                if($CatSwitch1==0){
                                        $TurnN++;
                                        
                                        for my $j(0..$#NewDics){
                                                for my $k ($TurnWds[$k6]..$TurnWds[$k6 + 1] - 1){
                                                
                                                        $Ag1Data[$j][$k - $TurnWds[$k6] +$WrdCt] = $DicReads[$k][$j];
                                                        $Ag1SmthData[$j][$k - $TurnWds[$k6] +$WrdCt] = $DataSmth[$j][$k];
                                                        if(exists $NewWtDics{$j} && $DataSmth[$j][$k] > .5){
                                                                $Ag1MHData[$j] += $DataSmth[$j][$k] - .5;
                                                                $Ag1HDataN[$j]++;                                        
                                                        }
							if(exists $NewZDics{$j}){
								if($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] > $ZIntNeutral){
									$Ag1ZHData[$j] += $DataSmth[$j][$k] - $ZIntNeutral;
									$Ag1ZHDataN[$j]++;
								}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] > $ZValNeutral){
									$Ag1ZHData[$j] += $DataSmth[$j][$k] - $ZValNeutral;
									$Ag1ZHDataN[$j]++;
								}elsif($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] < $ZIntNeutral){
									$Ag1ZLData[$j] += $ZIntNeutral - $DataSmth[$j][$k];
									$Ag1ZLDataN[$j]++;
								}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] < $ZValNeutral){
									$Ag1ZLData[$j] += $ZValNeutral - $DataSmth[$j][$k];
									$Ag1ZLDataN[$j]++;
								}
							}
						}
						
                                                $AgList[$k6]++;
                                        }
                                        $WrdCt += $TurnWds[$k6 + 1] - $TurnWds[$k6];
                                        
                                }
                                $CatSwitch1=0;
                        }
                        
                        print Ag1File "$WrdCt,$TurnN,";
			print Ag1SDFile "$WrdCt,$TurnN,";
			if($WrdCt != 0){
                                $GWordCt[$Spkr[$i]] += $WrdCt;
                                for my $j(0..$#NewDics){
                                        $Ag1MeanData[$j] = &Mean(@{$Ag1SmthData[$j]});
                                        my $TSum = &Sum(@{$Ag1Data[$j]});
                                        $GSum[$Spkr[$i]][$j] += $TSum;
					$Ag1SDData[$j] = &StanDev(@{$Ag1SmthData[$j]}); 
                                                                        
                                }
                        }
			
                        for my $j(0..$#NewDics){
                                print Ag1File "$Ag1MeanData[$j],";
				print Ag1SDFile "$Ag1SDData[$j],";
				
				
                        }
                     
                        my(@MH,@HP);
                        for my $k(0..$#WDics){
                        
                                $MH[$k] = 0;
                                $HP[$k] = 0;
                                if($Ag1HDataN[$WDics[$k]] > 0){
                               
                                        $MH[$k] = $Ag1MHData[$WDics[$k]]/$Ag1HDataN[$WDics[$k]];
                                        $HP[$k] = $Ag1HDataN[$WDics[$k]]/$WrdCt;
                                        $GWtSum[$Spkr[$i]][$WDics[$k]] += $Ag1MHData[$WDics[$k]];
                                        $GWtSumN[$Spkr[$i]][$WDics[$k]] += $Ag1HDataN[$WDics[$k]];
                                }
                                print Ag1File "$MH[$k],$HP[$k],";
                        
                    
                        }
			for my $k(0..$#ZDics){
		
			$ZMH[$k] = 0;
			$ZHP[$k] = 0;
			$ZML[$k] = 0;
			$ZLP[$k] = 0;
			if($Ag1ZHDataN[$ZDics[$k]] > 0){
			       
				$ZMH[$k] = $Ag1ZHData[$ZDics[$k]]/$Ag1ZHDataN[$ZDics[$k]];
			
				if($WrdCt > 0){
					$ZHP[$k] = $Ag1ZHDataN[$ZDics[$k]]/$WrdCt;
				}else{
					$ZHP[$k] = 0;
				}
			}
					
		
			print Ag1File "$ZMH[$k],$ZHP[$k],";
			if($Ag1ZLDataN[$ZDics[$k]] > 0){
			       
				$ZML[$k] = $Ag1ZLData[$ZDics[$k]]/$Ag1ZLDataN[$ZDics[$k]];
				if($WrdCt > 0){
					$ZLP[$k] = $Ag1ZLDataN[$ZDics[$k]]/$WrdCt;
				}else{
					$ZLP[$k] = 0;
				}
			}
			print Ag1File "$ZML[$k],$ZLP[$k],";		
		
		}
			if($CoVarSwitch == 0){
				for my $j(0..$#NewDics - 1){	
					for(my $j1 = $j + 1;$j1 <= $#NewDics;$j1++){
						$Ag1CoVars[$j][$j1] = 0;
					}
				}
		    
				for my $j(0..$#NewDics){
					if(exists $NewWtDics{$j}){
						push @{$Ag1SmthData[$j]},0.5;
										
					}else{
						push @{$Ag1SmthData[$j]},$DataMean0[$Spkr[$i]][$j];
					}        
				}
				       
				for my $j(0..$#NewDics - 1){
					for my $k($j+1..$#NewDics){
						$Ag1CoVars[$j][$k] = &Covar(@{$Ag1SmthData[$j]},@{$Ag1SmthData[$k]});
						print Ag1File "$Ag1CoVars[$j][$k],";
					}
				}
			}
                
                        print Ag1File "\n";
			print Ag1SDFile "\n";
                }
        } 
 
	print "DAAP09 has produced the first aggregate data file\n";
	
        
	print Ag2File "File,Spkr,";
	print Ag2SDFile "File,Spkr,";
	
	for(my $i=0;$i<=$#CatList;$i++){
		print Ag2File "$CatList[$i],";
		print Ag2SDFile "$CatList[$i],";
	}
	print Ag2File "Words,Turns,";
	print Ag2SDFile "Words,Turns,";
	for(my $j = 0;$j<= $#NewDics;$j++){
		print Ag2File "M$NewDics[$j],";
		print Ag2SDFile "SD$NewDics[$j],";
	}
        for my $j (0..$#WDics){
                print Ag2File "MH$NewDics[$WDics[$j]],HP$NewDics[$WDics[$j]],"
        }
	for my $j(0..$#ZDics){
		print Ag2File "MH$NewDics[$ZDics[$j]],HP$NewDics[$ZDics[$j]],ML$NewDics[$ZDics[$j]],LP$NewDics[$ZDics[$j]],";
	}
	if($CoVarSwitch == 0){
		for(my $j = 0;$j < $#NewDics;$j++){
			for(my $k = $j + 1; $k <= $#NewDics;$k++){
				print Ag2File "$NewDics[$j]_$NewDics[$k],";
				
			}
		}
	}
	print Ag2File "\n"; #This completes the top row of the Ag2File
        print Ag2SDFile "\n";
	
	$CatSwitch1=0;
	for my $i(0..$#Spkr){
		$AgList[$i]=0;
                
	}
	for my $i(0..$#Spkr){
		if($AgList[$i] != 0){
			next;
		}else{
                        my $Count = 0;
                        my (@Data,@SmthData,@MeanData,@CoVars,@MHData,@HPData,@HDataN);
			my(@Ag2ZHData,@Ag2ZHDataN,@Ag2ZLData,@Ag2ZLDataN,@Ag2SDData);
                        my $WrdCt = 0;
                        for(my $j = 0;$j <= $#Dics;$j++){
                                $MeanData[$j] = 0;
                                $DataSum[$j] = 0;
				$Ag2SDData[$j] = 0;
                        }
                        my $TurnN = 1;
                        $WrdCt += $TurnWds[$i + 1] - $TurnWds[$i];
                        for my $j(0..$#NewDics){                                   
                                for my $k ($TurnWds[$i]..$TurnWds[$i + 1] - 1){
                                        
                                        $Data[$j][$k - $TurnWds[$i]] = $DicReads[$k][$j];
                                        $SmthData[$j][$k - $TurnWds[$i]] = $DataSmth[$j][$k];
                                        if(exists $NewWtDics{$j} && $DataSmth[$j][$k] > .5){
                                                $MHData[$j] += $DataSmth[$j][$k] - .5;
                                                $HDataN[$j]++;                                        
                                        }
					if(exists $NewZDics{$j}){
						if($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] > $ZIntNeutral){
							$Ag2ZHData[$j] += $DataSmth[$j][$k] - $ZIntNeutral;
							$Ag2ZHDataN[$j]++;
						}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] > $ZValNeutral){
							$Ag2ZHData[$j] += $DataSmth[$j][$k] - $ZValNeutral;
							$Ag2ZHDataN[$j]++;
						}elsif($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] < $ZIntNeutral){
							$Ag2ZLData[$j] += $ZIntNeutral - $DataSmth[$j][$k];
							$Ag2ZLDataN[$j]++;
						}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] < $ZValNeutral){
							$Ag2ZLData[$j] += $ZValNeutral - $DataSmth[$j][$k];
							$Ag2ZLDataN[$j]++;
						}
					}
                                }
                        }
                        
			print Ag2File "$TxtFiles[$w],$Spkr[$i],";
			print Ag2SDFile "$TxtFiles[$w],$Spkr[$i],";
			
			for(my $q6=0;$q6<=$#CatList;$q6++){
				my $Switch2 = 0;
				for(my $r6=0;$r6<=$#AggCats;$r6++){
					if($AggCats[$r6] eq $CatList[$q6]){
						print Ag2File ",";
						print Ag2SDFile ",";
						$Switch2++;
						last;
					}
				}
				if($Switch2==0){
					print Ag2File "$GlobCat[$q6][$i],";
					print Ag2SDFile "$GlobCat[$q6][$i],";
				}
			}
                        
                        
                        for(my $k6=$i+1;$k6<=$#Spkr;$k6++){
				if($AgList[$k6]!=0){
					next;
				}
				if($Spkr[$k6]!=$Spkr[$i]){
					next;
				}
				for(my $m6=0;$m6<=$#CatList;$m6++){
					my $Switch2=0;
					for(my $r6=0;$r6<=$#AggCats;$r6++){
						if($AggCats[$r6]eq$CatList[$m6]){
							$Switch2++;
							last;
						}
					}
					if($Switch2>0){
						next;
					}
					if($GlobCat[$m6][$k6] eq $GlobCat[$m6][$i]){
						next;
					}else{
						$CatSwitch1++;
						last;
					}
				}
                                
                                
                                if($CatSwitch1 == 0){
                                        $TurnN++;
                                        
                                        for my $j(0..$#NewDics){                                   
                                                for my $k ($TurnWds[$k6]..$TurnWds[$k6 + 1] - 1){
                                        
                                                        $Data[$j][$k - $TurnWds[$k6] + $WrdCt] = $DicReads[$k][$j];
                                                        $SmthData[$j][$k - $TurnWds[$k6] + $WrdCt] = $DataSmth[$j][$k];
                                                        if(exists $NewWtDics{$j} && $DataSmth[$j][$k] > .5){
                                                                $MHData[$j] += $DataSmth[$j][$k] - .5;
                                                                $HDataN[$j]++;                                        
                                                        }
							if(exists $NewZDics{$j}){
								if($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] > $ZIntNeutral){
									$Ag2ZHData[$j] += $DataSmth[$j][$k] - $ZIntNeutral;
									$Ag2ZHDataN[$j]++;
								}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] > $ZValNeutral){
									$Ag2ZHData[$j] += $DataSmth[$j][$k] - $ZValNeutral;
									$Ag2ZHDataN[$j]++;
								}elsif($NewDics[$j] eq "ZInt" && $DataSmth[$j][$k] < $ZIntNeutral){
									$Ag2ZLData[$j] += $ZIntNeutral - $DataSmth[$j][$k];
									$Ag2ZLDataN[$j]++;
								}elsif($NewDics[$j] eq "ZVal" && $DataSmth[$j][$k] < $ZValNeutral){
									$Ag2ZLData[$j] += $ZValNeutral - $DataSmth[$j][$k];
									$Ag2ZLDataN[$j]++;
								}
							}
                                                }
                                               
                                        }
                                        $WrdCt += $TurnWds[$k6 + 1] - $TurnWds[$k6]; 
                        
                                        $AgList[$k6]++;
                                }
                                $CatSwitch1=0;
                        }
                        
			print Ag2File "$WrdCt,$TurnN,";
			print Ag2SDFile "$WrdCt,$TurnN,";
			if($WrdCt != 0){
                                for my $j(0..$#NewDics){
                                        $MeanData[$j] = &Mean(@{$SmthData[$j]});
					$Ag2SDData[$j] = &StanDev(@{$SmthData[$j]});
                                        
                                }
                        }
                        
                        for my $j(0..$#NewDics){
                                print Ag2File "$MeanData[$j],";
				print Ag2SDFile "$Ag2SDData[$j],";
                        }
                        my(@MH,@HP);
                        for my $k(0..$#WDics){
                        
                                $MH[$k] = 0;
                                $HP[$k] = 0;
                                if($HDataN[$WDics[$k]] > 0){
                               
                                        $MH[$k] = $MHData[$WDics[$k]]/$HDataN[$WDics[$k]];
					if($WrdCt >0){
						$HP[$k] = $HDataN[$WDics[$k]]/$WrdCt;
					}else{
						$HP[$k] = 0;
					}
                                
                                }
                                print Ag2File "$MH[$k],$HP[$k],";
                        
                        }
			for my $k(0..$#ZDics){
		
				$ZMH[$k] = 0;
				$ZHP[$k] = 0;
				$ZML[$k] = 0;
				$ZLP[$k] = 0;
				if($Ag2ZHDataN[$ZDics[$k]] > 0){
				       
					$ZMH[$k] = $Ag2ZHData[$ZDics[$k]]/$Ag2ZHDataN[$ZDics[$k]];
				
					if($WrdCt > 0){
						$ZHP[$k] = $Ag2ZHDataN[$ZDics[$k]]/$WrdCt;
					}else{
						$ZHP[$k] = 0;
					}
				}
						
			
				print Ag2File "$ZMH[$k],$ZHP[$k],";
				if($Ag2ZLDataN[$ZDics[$k]] > 0){
				       
					$ZML[$k] = $Ag2ZLData[$ZDics[$k]]/$Ag2ZLDataN[$ZDics[$k]];
					if($WrdCt > 0){
						$ZLP[$k] = $Ag2ZLDataN[$ZDics[$k]]/$WrdCt;
					}else{
						$ZLP[$k] = 0;
					}
				}
				print Ag2File "$ZML[$k],$ZLP[$k],";		
			
			}
			
			if($CoVarSwitch == 0){
				for my $j(0..$#NewDics - 1){	
					for(my $j1 = $j + 1;$j1 <= $#NewDics;$j1++){
						$CoVars[$j][$j1] = 0;
					}
				}
		    
				for my $j(0..$#NewDics){
					if(exists $NewWtDics{$j}){
						push @{$SmthData[$j]},0.5;
					
					}else{
						push @{$SmthData[$j]},$DataMean0[$Spkr[$i]][$j];
					}        
				}
				       
				for my $j(0..$#NewDics - 1){
					for my $k($j+1..$#NewDics){
						$CoVars[$j][$k] = &Covar(@{$SmthData[$j]},@{$SmthData[$k]});
						print Ag2File "$CoVars[$j][$k],";
					}
				}
			}
                        print Ag2File "\n";
			print Ag2SDFile "\n";
                }
        }
	print "DAAP09 has completed the Ag2 File\n";                        
	

	foreach my $List (sort keys %TTList){
		print TTRFile "\nThese are the types and tokens for Speaker $List\n";

		my $Types = 0;
		my $Tokens = 0;
		foreach my $Type (sort keys %{$TTList{$List}}){
			$Types++;
			$Tokens += $TTList{$List}{$Type};
			print TTRFile "$Type, $TTList{$List}{$Type}\n";
	
			#print TTRFile "\n";
		}
		print TTRFile "\nThe number of Types for Speaker $List is $Types\n";
		print TTRFile "The number of Tokens for Speaker $List is $Tokens\n";
		my $TTRat = 0;
		if ($Tokens != 0){
			$TTRat = $Types/$Tokens;
		}
		print TTRFile "The Type-Token Ratio for Speaker $List is $TTRat\n\n";
	}


        my @Match;
        for my $i(0..$#NewDics){
                $Match[$i] = 0;
        }
        for my $i(0..$#NewDics){
		if(exists $NewWtDics{$i}){
			
			for my $j(0..$WordN - 1){
				if($DicReads[$j][$i] != 0.5){
					$Match[$i]++;
					
				}
			}
		}elsif(exists $NewZDics{$i}){
			
			for my $j(0..$WordN - 1){
				if($DicReads[$j][$i] != 0.5){
					$Match[$i]++;
					
				}
			}
		
		}else{
			for my $j(0..$WordN - 1){
				if($DicReads[$j][$i] != 0){
					$Match[$i]++;
				}
			}
                        
                }
        }
	
        my @Cov;
        
	if($WordN != 0){
                for my $i(0..$#NewDics){
                        $Cov[$i] = $Match[$i]/$WordN;
                }
        }else{
                for my $i(0..$#NewDics){
                        $Cov[$i] = 0;
                }
        }
		
	for my $i(0..$#NewDics){
                print GlbFile "$Match[$i],$Cov[$i],";
        }
        print GlbFile "\n";
	
	
	if($LogWarn > 0){
		print "\nWARNING: The Log file has $LogWarn item(s) listed!\n";
	}

}
print "DAAP09 has finished processing the individual files\n";

open (ZGood,"ZGood.txt") or die("Can't read ZGood\n");
open (ZGoodQ,">$Dir/DATA/ZGoodQ") or die("Can't write to ZGoodQ\n");
my @GoodWords;
while(<ZGood>){
	chomp;
	push @GoodWords,$_;
}
print TTGFile "Type,Tokens,";
for my $i(0..$#NewDics){
	print TTGFile "$Dics[$i],";
	
}
if($#ZDics > -1){
	print TTGFile "Lemma,New?";
}


print TTGFile "\n";
my %New;
my $Types = 0;
my $Tokens = 0;
my %ZQuestion;
foreach my $Type (sort keys %TTGlob){
		
	$New{$Type} = 0;	
	$Types++;
	$Tokens += $TTGlob{$Type};
        print TTGFile "$Type,$TTGlob{$Type},";
		
	if ($DFDic == -1){	
		for my $m(0..$#NewDics - $#ZDics - 1){
			if($MultiDic{$Type}[$m] != 0){
											
				print TTGFile "$MultiDic{$Type}[$m],";
			}else{
				print TTGFile "0,";
			}
				
		}
	}else{
		for my $m(0..$#NewDics - $#ZDics - 2){
			if($MultiDic{$Type}[$m] != 0){
											
				print TTGFile "$MultiDic{$Type}[$m],";
			}else{
				print TTGFile "0,";
			}
				
		}
	}
	if($#ZDics >= 0){
		
		my @ZWordBank;
		my @Mats;
		my $Lemma;
		my $Val = 0;
		my $Hit1 = 0;
		my $Hit2 = 0;
		my $Hit3 = 0;
			
		for my $q(0..$#BadWords){
			if($Type eq $BadWords[$q]){
				#$New{$Type} = 1;
				$Hit1++;
				$Lemma = "Nil";
				#print "$Type $Lemma\n";
				last;
			}
		}
			

		if($Hit1 == 0){
			for my $q(0..$#ZChangeFrom){
				if($Type eq $ZChangeFrom[$q]){
					$Lemma = $ZChangeTo[$q];
					#$New{$Type} = 1;	
					$Hit2++;
					last;
					
				}
			}
		}
				
				
	
		if($Hit1 == 0 && $Hit2 == 0){
			for my $q(0..$#ZStems){
				if($Type =~ /^$ZStems[$q]/){
					push @Mats, $ZStems[$q];
					#print "$Type $ZStems[$q]\n";
					
				}
			}
			if($#Mats >= 0){
				
				$Lemma = $Mats[0];
				if($#Mats > 0){
					$Hit3++;
							
					for my $j(1..$#Mats){
						if(length($Mats[$j]) > length($Lemma)){
							$Lemma = $Mats[$j];
						}
					}
					
						
					
				}
				if (exists $ZQuestion{$Type}){
				}elsif(length($Type) > length($Lemma)){
					$ZQuestion{$Type} = $Lemma;
					#print "$Lemma\n";
				}
				if(exists $ZQuestion{$Type}){
					my $Hit4 = 0;
					for my $q(0..$#GoodWords){
						if($Type eq $GoodWords[$q]){
							$Hit4++;
							last;
							
						}
						
					}
					if($Hit4 == 0){
						$New{$Type} = 1;
					}
				}
			}
		}
			
		for my $m(0..$#ZDics){
							
			if($ZMultiDic{$Lemma}[$m] != 0){
				$Val = $ZMultiDic{$Lemma}[$m];
			}else{
				$Val = 0;
			}
			print TTGFile "$Val,";
		}
		print TTGFile "$Lemma,$New{$Type},";			
	}
	print TTGFile "\n";		
}
				
print LOLFile "\n\n Here are the NewLOL words\n\n";

foreach my $Word(sort keys %NewLOL){
	print LOLFile "$Word, $NewLOL{$Word}\n"
}

foreach my $Word (sort keys %ZQuestion){
	my $Hit = 0;
	for my $k(0..$#GoodWords){
		if($Word eq $GoodWords[$k]){
			$Hit++;
			last;	
		}
	}	
	if($Hit == 0){		
			
		print ZMatFile "$ZQuestion{$Word} $Word\n";
		print ZGoodQ "$Word\n";
	}
	
	
}
for my $q(1..$#GSpkr + 1){
	my $Types = 0;
	my $Tokens = 0;
	my $TTRat = 0;
	print TTSGFile "These are the types and tokens for overall speaker $q\n";
	foreach my $Word (sort keys %{$TTSGlob[$q]}){
		print TTSGFile "$Word, $TTSGlob[$q]{$Word}\n";
		$Types++;
		$Tokens += $TTSGlob[$q]{$Word};
	}
	print TTSGFile "The number of types for Speaker $q is $Types\n";
	print TTSGFile "The number of tokens for speaker $q is $Tokens\n";
	if($Tokens > 0){
		$TTRat = $Types/$Tokens;
	}
	print TTSGFile "The Type-Token Ratio for Speaker $q is $TTRat\n\n";
}

