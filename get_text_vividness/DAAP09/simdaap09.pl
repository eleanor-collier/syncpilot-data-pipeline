=NOTE

This is SimDAAP09.pl the latest version of one speaker simple DAAP.(Discourse Attribute Analysis Program).
DAAP09 compares words in textfiles with ordinary dictionaries (word lists), weighted dictionaries, and Z-Dictionaries; these
are weighted dictionaries that use wordstems, rather than words.

This program is designed to operate with presimdaap09.pl, which must be run first.

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
my $ZValNeutral =.5;
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

sub Covar{ #Note that this is the cosine measure; it depends on the mean or neutral  value put at the end of the array
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
my $NewLOL = $Dir."NewLOL.txt";
my $TTGlob = $Dir."TTGlob.csv";
my $LOGF = $Dir."LOGF.txt";
my $AG0F = $Dir."AG0.csv";
my $AG1F = $Dir."AG1.csv";
my $AG1SD = $Dir."AG1SD.csv";
my $AG2F = $Dir."AG2.csv";
my $GLBF = $Dir."GLB.csv";
my $TRNF = $Dir."TRN.csv";
my $ZMat = $Dir."ZMat.txt";
my $DATA = "DATA";
my @BadWords;
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
#open(Ag1File,">$Dir/DATA/$AG1F") or die("Can't open AG1File\n");
#open(Ag1SDFile,">$Dir/DATA/$AG1SD") or die("Can't open AG1SDFile\n");
open(Ag2File,">$Dir/DATA/$AG2F") or die("Can't open AG2File\n");
open(GlbFile,">$Dir/DATA/$GLBF") or die("Can't open GLBFile\n");
open(TRNFile,">$Dir/DATA/$TRNF") or die("Can't open TRNFile\n");
open(TTGFile,">$Dir/DATA/$TTGlob") or die("Can't write to TTGlob\n");
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
for my $i(0..$#Dics){
        
        print GlbFile "$Dics[$i]Mat,$Dics[$i]Cov,";
}
        print GlbFile "\n";
for my $i(0..$#Dics){
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
	my $MTT = "MTT.txt";
	my %Speakers;
	my $WrdF=$FileSplit[0].$Raw;
        my $SmtF=$FileSplit[0].$Smt;
	my $MTTF = $FileSplit[0].$MTT;
	
	open(InFile,"$Dir/$TxtFiles[$w]") or die("Can't open $TxtFiles[$w]");
	open(WrdFile, ">$Dir/DATA/$WrdF") or die("Failed to open Wrdfile");
        open(SmtFile, ">$Dir/DATA/$SmtF") or die("Failed to open Smtfile");
	open(MTTFile,">>$Dir/DATA/$MTTF") or die("Failed to append to MTTFile\n");
	print "SimpleDAAP09 is now reading $TxtFiles[$w]\n";

	#Finished making the output files
	my $C9Check = 0;	
	my $WordN=0;
	my @DicMatch;
	my $LogWarn = 0;
	my $LocWdN = 0; 
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
	my $TMark = 0;
	my $TurnMarker = 0;
	while(<InFile>){
		chomp;
		my $Line=$_;
		
		my @NewLine;
		my $LocWds=0;
		my $Words=0;

		if(/(.+\\.*)/){
			print LogFile "ERROR 1: Backslash not at first character in Line: $1\n";
			print  "ERROR 1: Backslash not at first character in Line:\n $1\n";
			die;
		}
		
		if(/^\\c9/){
			$C9Check++;			
			for(my $i = 0;$i <= $#DWBN;$i++){
				push @DWBG,$DWBN[$i];
			}
			
			push @TurnWds, $WordN;
			$TurnN++;
			print GlbFile "$TxtFiles[$w],$WordN,$TurnN,";
			
			last;
		}
		if(/\w+/){
			if(/^\\t.*/){
				if(/^\\t\s*(\w+):(\w+)\s*$/){
					$TMark++;
					if($WordN == 0){
						push(@CatList,$1);
						$CatIndx{$1}=$#CatList;
						$LocCat[$#CatList]=$2;
						$GlobCat[$#CatList][0]=$2;
						
					}elsif($WordN > 0){
						if(exists $CatIndx{$1}){
							$LocCat[$CatIndx{$1}]=$2;
							$GlobCat[$CatIndx{$1}][$TurnN] = $2;
						}else{
							print "ERROR 15: Undeclared Category at Word $WordN: $_\n";
							print LogFile "ERROR 15: Undeclared Category at Word $WordN: $_\n";
							die;
						}
					}
					$CatSwitch++;
					
				}else{
					print LogFile "ERROR 8: Improper category marker: $_\n";
					print "ERROR 8: Improper category marker: $_\n";
					$LogWarn++;
					die;
				}
					
			}else{
				
				if($CatSwitch > 0){
					
				
					$LocWdN=0;    
					
					for(my $i = 0;$i <= $#DWBN;$i++){
						push @DWBG,$DWBN[$i];
					}
					if($#DWB != $#DWBN){
						print "DWB and DWBN have different numbers of elements\n";
					}
					
					my $NNN = $#DWB;
					for(my $i = 0;$i <= $NNN;$i++){
						pop @DWB;
						pop @DWBN;
					}
					
					for(my $k1=0;$k1<=$#CatList;$k1++){
						$GlobCat[$k1][$TurnN]=$LocCat[$k1];
					}
					if($WordN > 0){
						push @TurnWds, $WordN;
						
						#$TurnN++;
					}
					$CatSwitch = 0;
				}
				if($TMark > 0){
					$TurnN++;
					$TMark = 0;
				}
				my $Switch = 0;
				my @Words=split /\s+/,$Line; 
				foreach my $Word (@Words){
					$WordN++;
					$LocWdN++;
					$Word=lc $Word;
					push @WordBank,$Word;
					push @DWB, $Word;
					if(/\w+-$/){
						push @DWBN,1;
					}elsif(/(\w+)dx/){
						push @DWBN,1;
						$Word = $1;
						
					}elsif($MultiDic{$Word}[$DFDic] == 1){
						push @DWBN,1;
				
					}else{
						push @DWBN,0;
					}
					if($#DWB > 0){
						if($DWB[$#DWB] eq $DWB[$#DWB - 1]){
							if($DWBN[$#DWB - 1] == 0){
								$DWBN[$#DWB - 1] = 1;
							}
						}
					}
					if($#DWB > 2){
						if($DWB[$#DWB] eq $DWB[$#DWB - 2] && $DWB[$#DWB - 1] eq $DWB[$#DWB - 3]){
							if($DWBN[$#DWB - 2] == 0 && $DWBN[$#DWB - 3] == 0){
								$DWBN[$#DWB - 2] = 1;
								
							}
						}
					}
					my $WordSw = 0;
					my $Indx = $#DicReads;
					
					if($Word =~/\w+-?/){
						
						if($Word =~ /\w+-$/){
							for my $m(0..$#Dics - $#Dics){
								$DicReads[$Indx + 1][$m] = 0;
								push @ZWordBank, "DF";
							}
							
						}else{
							
							for my $m(0..$#Dics - $#ZDics - 1){
								if($MultiDic{$Word}[$m] != 0){
									$WordSw++;
									$DicReads[$Indx + 1][$m] = $MultiDic{$Word}[$m];
								}else{
									$DicReads[$Indx + 1][$m] = 0;
								}
							     
							}
							
							my @Mats;
							my $RealMat;
							my $Hit1 = 0;
							my $Hit2 = 0;
							my $Hit3 = 0;
							
							for my $q(0..$#BadWords){
								if($Word eq $BadWords[$q]){
									$Hit1++;
									last;
								}
							}
							if($Hit1 > 0){
								my $Temp = "Bad";
								push @ZWordBank,$Temp;
								for my $m(0..$#ZDics){
									$DicReads[$Indx + 1][$#Dics - $#ZDics + $m] = 0;
								}
																
								
							}elsif($Hit1 == 0){
								for my $q(0..$#ZChangeFrom){
									if($Word eq $ZChangeFrom[$q]){
										$RealMat = $ZChangeTo[$q];
										$Hit2++;
										last;
									}
									if(! exists $ZMatTT{$Word}){
									
									
										$ZMatTT{$Word} = $RealMat;
									
									}
								}
								if($Hit2 > 0){
									push @ZWordBank,$RealMat;
									for my $m(0..$#ZDics){
										if($ZMultiDic{$RealMat}[$m] != 0){
								
											$DicReads[$Indx + 1][$#Dics - $#ZDics + $m] = $ZMultiDic{$RealMat}[$m];
										}else{
											$DicReads[$Indx + 1][$#Dics - $#ZDics + $m] = 0;
										}
									}
									
								}elsif($Hit2 == 0){
									for my $q(0..$#ZStems){
										if($Word =~ /^$ZStems[$q]/){
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
											if(exists $ZMatTT{$Word}){
											}else{
												$ZMatTT{$Word} = $RealMat;
											}
											if(exists $ZUnusual{$Word}){
												
											}elsif(length($Word) > length($RealMat)){
												$ZUnusual{$Word} = $RealMat;
											}
											
											
										}
										push @ZWordBank,$RealMat;
										for my $m(0..$#ZDics){
											if($ZMultiDic{$RealMat}[$m] != 0){
												$DicReads[$Indx + 1][$#Dics - $#ZDics + $m] = $ZMultiDic{$RealMat}[$m];
											}else{
												$DicReads[$Indx + 1][$#Dics - $#ZDics + $m] = 0;
											}
								
										}
										if(exists $ZMatTT{$Word}){
										}else{
											$ZMatTT{$Word} = $RealMat;
										}
									
									}else{
										my $Temp = "Nil";
										push @ZWordBank,$Temp;
										for my $m(0..$#ZDics){
											$DicReads[$Indx + 1][$#Dics - $#ZDics + $m] = 0;
										}
										if(exists $ZMatTT{$Word}){
										}else{
											$ZMatTT{$Word} = $Temp;
										}
									}
								}
			
							}
						
							if($WordSw == 0){
								if(exists $OLOL{$Word}){
									$WordSw++;
								}else{
									if(exists $NewLOL{$Word}){
										$NewLOL{$Word}++;
									}else{
										$NewLOL{$Word} = 1;
									}
								}
							}
							
							if(exists $TTList{$Word}){
								$TTList{$Word}++;
							}else{
								$TTList{$Word} = 1;
							}
							
							
							if(exists $TTGlob{$Word}){
								$TTGlob{$Word}++;
							}else{
								$TTGlob{$Word} = 1;
							}
						
						} 
								
					}else{
						print LogFile "ERROR 4: The Word $Word at Word Number $WordN is unusual\n";
						$LogWarn++;
						
					}
				}
			}
		}

	}
	
	if($C9Check == 0){
		print "File $TxtFiles[$w] does not have \\c9 at its end.\n presimpledaap09.pl must be run  before this program is run\n";
	}
	
	
	my @RawData;

	for (my $m = 0;$m <= $WordN;$m++){
				
		if ($DFDic >= 0 && $DWBG[$m] == 1){
			$DicReads[$m][$DFDic] = 1;
		}
	}
	my $Start = $#Dics - $#WDics - $#ZDics - 1;
	for(my $m = $Start;$m <= $#Dics;$m++){
		for(my $p = 0;$p <= $#DicReads;$p++){
			$DicReads[$p][$m] = .5*$DicReads[$p][$m] +.5;
		}
	}
	
	print "SimpleDAAP09 has finished reading your file and is now processing the data;\n please wait.\n";	

	my(@DataSmth,@STData);
	
	for(my $m=1;$m<=$#TurnWds;$m++){
		my @DataTList;

                for my $j (0..$#Dics){
                        for my $k ($TurnWds[$m - 1]..$TurnWds[$m] - 1){
                                $DataTList[$j][$k - $TurnWds[$m - 1]] = $DicReads[$k][$j];
                                
                        }
                        push @{$DataSmth[$j]}, &Sth(@{$DataTList[$j]});
		}

	}
        

        print WrdFile "Word,";
        for my $j(0..$#Dics){
                print WrdFile "$Dics[$j],";
        }
	
	for(my $k = 0;$k <= $#Dics;$k++){
		print SmtFile "$Dics[$k],";
	}
		
	if($#ZDics > -1){
		print WrdFile "ZMat,\n";
	}else{
		print WrdFile "\n";
	}
        print SmtFile "\n";#This completes the top row of the RAW (Word) and Smooth files
	
	for(my $i=1;$i<=$#TurnWds;$i++){
                
		for(my $j=$TurnWds[$i-1];$j<$TurnWds[$i];$j++){
			
			print WrdFile "$WordBank[$j],";
			for(my $q = 0;$q <= $#Dics;$q++){
				
                                print SmtFile "$DataSmth[$q][$j],";
                                print WrdFile "$DicReads[$j][$q],";
			}
			if ($#ZDics > -1){
				print WrdFile "$ZWordBank[$j]\n";
			}else{
				print WrdFile "\n";
			}
                        print SmtFile "\n";
 
		}
	}	
	print "SimpleDAAP09 has produced the raw and smooth data files\n";
	
	print TRNFile "File,TurnNo,";
	
	for(my $i=0;$i<=$#CatList;$i++){
		print TRNFile "$CatList[$i],";
		
	}
	print TRNFile "Words,FirstWord,";
	for(my $j = 0;$j<= $#Dics;$j++){
		print TRNFile "M$Dics[$j],";
   
	}
        for my $j (0..$#WDics){
                print TRNFile "MH$Dics[$WDics[$j]],HP$Dics[$WDics[$j]],"
        }
	for my $j(0..$#ZDics){
		print TRNFile "MH$Dics[$ZDics[$j]],HP$Dics[$ZDics[$j]],ML$Dics[$ZDics[$j]],LP$Dics[$ZDics[$j]],";
	}
	if($CoVarSwitch == 0){
		for(my $j = 0;$j < $#Dics;$j++){
			for(my $k = $j + 1; $k <= $#Dics;$k++){
				print TRNFile "$Dics[$j]_$Dics[$k],";
			
			}
		}
	}
	print TRNFile "\n"; #This completes the top row of the TrnFile
	
	my(@DataSum);
        my $TrnWordN = 0;
	for my $i (1..$#TurnWds){
				
		for(my $j=$TurnWds[$i-1];$j<$TurnWds[$i];$j++){
			$TrnWordN++;
			for(my $k = 0;$k<=$#Dics;$k++){
				$DataSum[$k]+=$DicReads[$j][$k];
			}
		}
	}
	my(@DataMean0);
	
	for my $j (0..$#Dics){
		$DataMean0[$j] = 0;
	}

	
	for(my $j = 0;$j <= $#Dics;$j++){
		if($TrnWordN > 0){
			
		
			$DataMean0[$j] = $DataSum[$j]/$TrnWordN;
		}

	}

	my @GDataM0;
	
	for my $j(0..$#Dics){
		my $GDataSum = 0;
		my $WordSum = 0;
		for my $i(1..$#TurnWds){
			$GDataSum+= $DataSum[$j];
			$WordSum += $TurnWds[$i];
		}
		if($WordSum > 0){
			$GDataM0[$j] = $GDataSum/$WordSum;
		}else{
			$GDataM0[$j] = 0;
		}
	}
	for my $i(1..$#TurnWds){
		
		print TRNFile "$TxtFiles[$w],$i,";
		
		for(my $k2=0;$k2<=$#CatList;$k2++){
			print TRNFile "$GlobCat[$k2][$i-1],";
			
		}
		my $TWds = 0;
		for my $j(0..$i-1){
			$TWds += $TurnWds[$j];
		}
		my $CurrentWords = $TurnWds[$i] - $TurnWds[$i - 1];
		print TRNFile "$CurrentWords,$TurnWds[$i - 1],"; #This completes the basic data for each row
		
		my (@MeanData,@CoVars,@MHData,@HPData,@ZHData,@ZHDataN,@ZLData,@ZLDataN,@HDataN);
                my(@Data,@SmthData);
                for my $j(0..$#Dics){
                        for my $k ($TurnWds[$i - 1]..$TurnWds[$i] - 1){
                                $Data[$j][$k - $TurnWds[$i - 1]] = $DicReads[$k][$j];
                                $SmthData[$j][$k - $TurnWds[$i - 1]] = $DataSmth[$j][$k];
                                if(exists $WtDics{$j} && $DataSmth[$j][$k] > .5){
                                        $MHData[$j] += $DataSmth[$j][$k] - .5;
                                        $HDataN[$j]++;
                                }
				if(exists $ZDics{$j}){
					if($Dics[$j] eq "ZInt" && $DataSmth[$j][$k] > $ZIntNeutral && $DataSmth[$j][$k] != $ZIntNeutral){
						$ZHData[$j] += $DataSmth[$j][$k] - $ZIntNeutral;
						$ZHDataN[$j]++;
					}elsif($Dics[$j] eq "ZVal" && $DataSmth[$j][$k] > $ZValNeutral){
						$ZHData[$j] += $DataSmth[$j][$k] - $ZValNeutral;
						$ZHDataN[$j]++;
					}elsif($Dics[$j] eq "ZInt" && $DataSmth[$j][$k] < $ZIntNeutral){
						$ZLData[$j] += $ZIntNeutral - $DataSmth[$j][$k];
						$ZLDataN[$j]++;
					}elsif($Dics[$j] eq "ZVal" && $DataSmth[$j][$k] < $ZValNeutral){
						$ZLData[$j] += $ZValNeutral - $DataSmth[$j][$k];
						$ZLDataN[$j]++;
					}
				}
                        }
                }

                for my $j(0..$#Dics){
                        $MeanData[$j] = &Mean(@{$SmthData[$j]});
                        print TRNFile "$MeanData[$j],";
                }
                my(@MH,@HP,@ZMH,@ZHP,@ZML,@ZLP);
                for my $k(0..$#WDics){
                        
                        $MH[$k] = 0;
                        $HP[$k] = 0;
                        if($HDataN[$WDics[$k]] > 0){
                               
                                $MH[$k] = $MHData[$WDics[$k]]/$HDataN[$WDics[$k]];
			}
			if($CurrentWords > 0){

                                $HP[$k] = $HDataN[$WDics[$k]]/$CurrentWords;
			
 
				print TRNFile "$MH[$k],$HP[$k],";
				for my $k(0..$#ZDics){
					$ZMH[$k] = 0;
					$ZHP[$k] = 0;
					$ZML[$k] = 0;
					$ZLP[$k] = 0;
					if($ZHDataN[$ZDics[$k]] > 0){
		       
						$ZMH[$k] = $ZHData[$ZDics[$k]]/$ZHDataN[$ZDics[$k]];
						if($CurrentWords> 0){
							$ZHP[$k] = $ZHDataN[$ZDics[$k]]/$CurrentWords;
						}else{
							$ZHP[$k] = 0;
						}
				
					}
					print TRNFile "$ZMH[$k],$ZHP[$k],";
					if($ZLDataN[$ZDics[$k]] > 0){
		       
						$ZML[$k] = $ZLData[$ZDics[$k]]/$ZLDataN[$ZDics[$k]];
					}
					if($CurrentWords > 0){
						$ZLP[$k] = $ZLDataN[$ZDics[$k]]/$CurrentWords;
					}else{
						$ZLP[$k] = 0;
					}
					print TRNFile "$ZML[$k],$ZLP[$k],";
				}
						
		
			}
                }
		if($CoVarSwitch == 0){
			for my $j(0..$#Dics - 1){	
				for(my $j1 = $j + 1;$j1 <= $#Dics;$j1++){
					$CoVars[$j][$j1] = 0;
				}
			}
			
			for my $j(0..$#Dics){
				if(exists $WtDics{$j}){
					push @{$SmthData[$j]},0.5;
										
				}else{
					push @{$SmthData[$j]},$DataMean0[$j];
				}        
			}
				       
			for my $j(0..$#Dics - 1){
				for my $k($j+1..$#Dics){
					$CoVars[$j][$k] = &Covar(@{$SmthData[$j]},@{$SmthData[$k]});
					print TRNFile "$CoVars[$j][$k],";
				}
			}
		}
                
         	print TRNFile "\n";
                                		
	}
	print "SimpleDAAP09 has produced the Turn Data File\n";

	#Now we make the AG0File
		
	print Ag0File "File,";
	print Ag0File "Words,Turns,";
	
	for my $j(0..$#Dics){
		print Ag0File "M$Dics[$j],";
	}
	
	for my $j (0..$#WDics){
                print Ag0File "MH$Dics[$WDics[$j]],HP$Dics[$WDics[$j]],";
        }
	for my $j(0..$#ZDics){
		print Ag0File "MH$Dics[$ZDics[$j]],HP$Dics[$ZDics[$j]],ML$Dics[$ZDics[$j]],LP$Dics[$ZDics[$j]],";
	}
	if($CoVarSwitch == 0){
		for(my $j = 0;$j < $#Dics;$j++){
			for(my $k = $j + 1; $k <= $#Dics;$k++){
				print Ag0File "$Dics[$j]_$Dics[$k],";
			}
		}
	}
	print Ag0File "\n"; #This completes the top line of the AG0 file
	
	my (@SmthData,@MHData,@HDataN,@ZHData,@ZHDataN,@ZLData,@ZLDataN,@MeanData,@CoVars);
	my(@MH,@HP,@ZMH,@ZHP,@ZML,@ZLP);
	my $Turns = 0;
	my $Words = 0;
	print Ag0File "$TxtFiles[$w],";
		
	for my $i(1..$#TurnWds){		
		$Turns++;
		for my $j(0..$#Dics){                                   
			for my $k ($TurnWds[$i - 1]..$TurnWds[$i] - 1){
				
				$SmthData[$j][$k - $TurnWds[$i - 1] + $Words] = $DataSmth[$j][$k];
				if(exists $WtDics{$j} && $DataSmth[$j][$k] > .5){
					$MHData[$j] += $DataSmth[$j][$k] - .5;
					$HDataN[$j]++;                                        
				}
				if(exists $ZDics{$j}){
					if($Dics[$j] eq "ZInt" && $DataSmth[$j][$k] > $ZIntNeutral){
						$ZHData[$j] += $DataSmth[$j][$k] - $ZIntNeutral;
						$ZHDataN[$j]++;
					}elsif($Dics[$j] eq "ZVal" && $DataSmth[$j][$k] > $ZValNeutral){
						$ZHData[$j] += $DataSmth[$j][$k] - $ZValNeutral;
						$ZHDataN[$j]++;
					}elsif($Dics[$j] eq "ZInt" && $DataSmth[$j][$k] < $ZIntNeutral){
						$ZLData[$j] += $ZIntNeutral - $DataSmth[$j][$k];
						$ZLDataN[$j]++;
					}elsif($Dics[$j] eq "ZVal" && $DataSmth[$j][$k] < $ZValNeutral){
						$ZLData[$j] += $ZValNeutral - $DataSmth[$j][$k];
						$ZLDataN[$j]++;
					}
				}
			}
			
			
		}
	
		$Words+= $TurnWds[$i] - $TurnWds[$i - 1];
		
	}	
	if($Words != 0){
			
		for my $j(0..$#Dics){
			$MeanData[$j] = &Mean(@{$SmthData[$j]});
		}
	}else{
		for my $j(0..$#Dics){
			$MeanData[$j] = 0;
		}
	}
	
	
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
		
		if($ZLDataN[$ZDics[$k]] > 0){
		       
			$ZML[$k] = $ZLData[$ZDics[$k]]/$ZLDataN[$ZDics[$k]];
			if($Words > 0){
				$ZLP[$k] = $ZLDataN[$ZDics[$k]]/$Words;
			}else{
				$ZLP[$k] = 0;
			}
		}
				

	}
	
               
	if($CoVarSwitch == 0){
		for my $j(0..$#Dics - 1){	
			for(my $j1 = $j + 1;$j1 <= $#Dics;$j1++){
				$CoVars[$j][$j1] = 0;
			}
		}
	    
		for my $j(0..$#Dics){
			if(exists $WtDics{$j}){
				push @{$SmthData[$j]},0.5;
							
			}else{
				push @{$SmthData[$j]},$DataMean0[$j];
			}        
		}
			       
		for my $j(0..$#Dics - 1){
			for my $k($j+1..$#Dics){
				$CoVars[$j][$k] = &Covar(@{$SmthData[$j]},@{$SmthData[$k]});
				
				if($#{$SmthData[$j]}!= $#{$SmthData[$k]}){
					print "SmthData[$j] != SmthData[$k]\n";
				}
			}
		}
	}
	
	print Ag0File "$Words,$Turns,";
	for my $j(0..$#Dics){
                print Ag0File "$MeanData[$j],";
        }
	for my $k(0..$#WDics){
		print Ag0File "$MH[$k],$HP[$k],";
	}
	for my $k(0..$#ZDics){
		print Ag0File "$ZMH[$k],$ZHP[$k],";
		print Ag0File "$ZML[$k],$ZLP[$k],";
	}
	if($CoVarSwitch == 0){
		for my $j(0..$#Dics - 1){
			for my $k($j+1..$#Dics){
				print Ag0File "$CoVars[$j][$k],";
			}
		}
	}
        print Ag0File "\n";
			
	
	print "SimpleDAAP09 has finished making the Ag0 file\n";
	print "This is SimpleDAAP09, processing texts with only one speaker; there is no Ag1 file\n";
	my @AgList;
	my $CatSwitch1=0;
	
	print Ag2File "File,";
	for(my $i=0;$i<=$#CatList;$i++){
		print Ag2File "$CatList[$i],";
	}
	print Ag2File "Words,Turns,";	
	for(my $j = 0;$j<= $#Dics;$j++){
		print Ag2File "M$Dics[$j],";
   
	}
        for my $j (0..$#WDics){
                print Ag2File "MH$Dics[$WDics[$j]],HP$Dics[$WDics[$j]],"
        }
	for my $j(0..$#ZDics){
		print Ag2File "MH$Dics[$ZDics[$j]],HP$Dics[$ZDics[$j]],ML$Dics[$ZDics[$j]],LP$Dics[$ZDics[$j]],";
	}
	if($CoVarSwitch == 0){
		for(my $j = 0;$j < $#Dics;$j++){
			for(my $k = $j + 1; $k <= $#Dics;$k++){
				print Ag2File "$Dics[$j]_$Dics[$k],";
				
			}
		}
	}
	print Ag2File "\n"; #This completes the top row of the Ag2File
        
	$CatSwitch1=0;
	
	for my $i(0..$#TurnWds - 1){
		if($AgList[$i] != 0){
			next;
		}else{
                        my $Count = 0;
                        my (@Data,@SmthData,@MeanData,@CoVars,@MHData,@HPData,@HDataN);
			my(@Ag2ZHData,@Ag2ZHDataN,@Ag2ZLData,@Ag2ZLDataN);
                        my $WrdCt = 0;
                        for(my $j = 0;$j <= $#Dics;$j++){
                                $MeanData[$j] = 0;
                                $DataSum[$j] = 0;
                        }
                        my $Ag2TurnN = 1;
                        $WrdCt += $TurnWds[$i + 1] - $TurnWds[$i];
                        for my $j(0..$#Dics){                                   
                                for my $k ($TurnWds[$i]..$TurnWds[$i + 1] - 1){
                                        
                                        $Data[$j][$k - $TurnWds[$i]] = $DicReads[$k][$j];
                                        $SmthData[$j][$k - $TurnWds[$i]] = $DataSmth[$j][$k];
                                        if(exists $WtDics{$j} && $DataSmth[$j][$k] > .5){
                                                $MHData[$j] += $DataSmth[$j][$k] - .5;
                                                $HDataN[$j]++;                                        
                                        }
					if(exists $ZDics{$j}){
						if($Dics[$j] eq "ZInt" && $DataSmth[$j][$k] > $ZIntNeutral){
							$Ag2ZHData[$j] += $DataSmth[$j][$k] - $ZIntNeutral;
							$Ag2ZHDataN[$j]++;
						}elsif($Dics[$j] eq "ZVal" && $DataSmth[$j][$k] > $ZValNeutral){
							$Ag2ZHData[$j] += $DataSmth[$j][$k] - $ZValNeutral;
							$Ag2ZHDataN[$j]++;
						}elsif($Dics[$j] eq "ZInt" && $DataSmth[$j][$k] < $ZIntNeutral){
							$Ag2ZLData[$j] += $ZIntNeutral - $DataSmth[$j][$k];
							$Ag2ZLDataN[$j]++;
						}elsif($Dics[$j] eq "ZVal" && $DataSmth[$j][$k] < $ZValNeutral){
							$Ag2ZLData[$j] += $ZValNeutral - $DataSmth[$j][$k];
							$Ag2ZLDataN[$j]++;
						}
					}
                                }
                        }
                        
			print Ag2File "$TxtFiles[$w],";
			for(my $q6=0;$q6<=$#CatList;$q6++){
				my $Switch2 = 0;
				for(my $r6=0;$r6<=$#AggCats;$r6++){
					if($AggCats[$r6] eq $CatList[$q6]){
						print Ag2File ",";
						$Switch2++;
						last;
					}
				}
				if($Switch2==0){
					print Ag2File "$GlobCat[$q6][$i],";
				}
			}
                        
                        
                        for(my $k6=$i+1;$k6<=$#TurnWds - 1;$k6++){
				if($AgList[$k6] != 0){
					next;
				}
				
				for(my $m6=0;$m6<=$#CatList;$m6++){
					
					my $Switch2=0;
					for(my $r6=0;$r6<=$#AggCats;$r6++){
						
						if($AggCats[$r6] eq $CatList[$m6]){
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
                                        $Ag2TurnN++;
                                        
                                        for my $j(0..$#Dics){                                   
                                                for my $k ($TurnWds[$k6]..$TurnWds[$k6 + 1] - 1){
                                        
                                                        $Data[$j][$k - $TurnWds[$k6] + $WrdCt] = $DicReads[$k][$j];
                                                        $SmthData[$j][$k - $TurnWds[$k6] + $WrdCt] = $DataSmth[$j][$k];
                                                        if(exists $WtDics{$j} && $DataSmth[$j][$k] > .5){
                                                                $MHData[$j] += $DataSmth[$j][$k] - .5;
                                                                $HDataN[$j]++;                                        
                                                        }
							if(exists $ZDics{$j}){
								if($Dics[$j] eq "ZInt" && $DataSmth[$j][$k] > $ZIntNeutral){
									$Ag2ZHData[$j] += $DataSmth[$j][$k] - $ZIntNeutral;
									$Ag2ZHDataN[$j]++;
								}elsif($Dics[$j] eq "ZVal" && $DataSmth[$j][$k] > $ZValNeutral){
									$Ag2ZHData[$j] += $DataSmth[$j][$k] - $ZValNeutral;
									$Ag2ZHDataN[$j]++;
								}elsif($Dics[$j] eq "ZInt" && $DataSmth[$j][$k] < $ZIntNeutral){
									$Ag2ZLData[$j] += $ZIntNeutral - $DataSmth[$j][$k];
									$Ag2ZLDataN[$j]++;
								}elsif($Dics[$j] eq "ZVal" && $DataSmth[$j][$k] < $ZValNeutral){
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
                        
			print Ag2File "$WrdCt,$Ag2TurnN,";
			if($WrdCt != 0){
                                for my $j(0..$#Dics){
                                        $MeanData[$j] = &Mean(@{$SmthData[$j]});
                                        
                                }
                        }
                        
                        for my $j(0..$#Dics){
                                print Ag2File "$MeanData[$j],";
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
				for my $j(0..$#Dics - 1){	
					for(my $j1 = $j + 1;$j1 <= $#Dics;$j1++){
						$CoVars[$j][$j1] = 0;
					}
				}
		    
				for my $j(0..$#Dics){
					if(exists $WtDics{$j}){
						push @{$SmthData[$j]},0.5;
					
					
					}else{
						push @{$SmthData[$j]},$DataMean0[$j];
					}        
				}
				       
				for my $j(0..$#Dics - 1){
					for my $k($j+1..$#Dics){
						$CoVars[$j][$k] = &Covar(@{$SmthData[$j]},@{$SmthData[$k]});
						print Ag2File "$CoVars[$j][$k],";
					}
				}
			}
                        print Ag2File "\n";
                }
        }
	print "SimpleDAAP09 has completed the Ag2 File\n";                        
	my $Types = 0;
	my $Tokens = 0;
	
	foreach my $Type (sort keys %TTList){

		$Types++;
		$Tokens += $TTList{$Type};
		
	}
	
	print MTTFile "\nThe number of Types for $TxtFiles[$w] is $Types\n";
	print MTTFile "The number of Tokens for $TxtFiles[$w] is $Tokens\n";
	my $TTRat = 0;
	if ($Tokens != 0){
		$TTRat = $Types/$Tokens;
	}
	print MTTFile "The Type-Token Ratio for $TxtFiles[$w] is $TTRat\n\n";
	close MTTFile;
	
        my @Match;
        for my $i(0..$#Dics){
                $Match[$i] = 0;
        }
        for my $i(0..$#Dics){
		if(exists $WtDics{$i}){
			for my $j(0..$WordN - 1){
				if($DicReads[$j][$i] != 0.5){
					$Match[$i]++;
					
				}
			}
		}elsif(exists $ZDics{$i}){
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
                for my $i(0..$#Dics){
                        $Cov[$i] = $Match[$i]/$WordN;
                }
        }else{
                for my $i(0..$#Dics){
                        $Cov[$i] = 0;
                }
        }
		
	for my $i(0..$#Dics){
                print GlbFile "$Match[$i],$Cov[$i],";
        }
        print GlbFile "\n";
	
	print "SimpleDAAP09 has finished processing the individual files\n";
	if($LogWarn > 0){
		print "\nWARNING: The Log file has $LogWarn item(s) listed!\n";
	}

}

open (ZGood,"ZGood.txt") or die("Can't read ZGood\n");
open (ZGoodQ,">$Dir/DATA/ZGoodQ") or die("Can't write to ZGoodQ\n");
my @GoodWords;
while(<ZGood>){
	chomp;
	push @GoodWords,$_;
}
print TTGFile "Type,Tokens,";
for my $i(0..$#Dics){
	print TTGFile "$Dics[$i],";
	
}
if($#ZDics > -1){
	print TTGFile "Lemma,New?\n";

}else{
	print TTGFile "\n";
}
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
		for my $m(0..$#Dics - $#ZDics - 1){
			if($MultiDic{$Type}[$m] != 0){
											
				print TTGFile "$MultiDic{$Type}[$m],";
			}else{
				print TTGFile "0,";
			}
				
		}
	}else{
		for my $m(0..$#Dics - $#ZDics - 1){
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
				
				last;
			}
		}
			

		if($Hit1 == 0){
			for my $q(0..$#ZChangeFrom){
				if($Type eq $ZChangeFrom[$q]){
					$Lemma = $ZChangeTo[$q];
						
					$Hit2++;
					last;
					
				}
			}
		}
				
				
	
		if($Hit1 == 0 && $Hit2 == 0){
			for my $q(0..$#ZStems){
				if($Type =~ /^$ZStems[$q]/){
					push @Mats, $ZStems[$q];
					
					
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
