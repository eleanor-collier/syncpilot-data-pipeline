#DAAP09.6 README

DAAP09.6 is a command line program that can operate on either a Windows or Mac
platform; it has not as yet been tested for operation on a Linux platform.

This Repository includes the following files:

	A. Programs:  
		PreDAAP09.pl  
		DAAP09.6.pl  

	B. License and Operating Instructions  
		DAAP09.6.pl Operating Instructions 
		(as DAAP09.6OPERATINGINSTRUCTIONS.md and
		DAAP09.6OPERATINGINSTRUCTIONS.pdf)  
		GNU General Public License  

	C. Word lists (dictionaries) necessary for operating the programs  
		ListL2.txt  
		ListL8.txt  
		ListL11.txt  
		ListW2.txt  
		TheDic  
		ZBad.txt  
		ZChange.txt  
		ZGood.txt  

	D. Referential Process dictionaries other than WRAD  
		AN (Negative Affect)  
		AP (Positive Affect)  
		AZ (Non-valenced affect)  
		DF (Disfluency)  
		R (Reflection)  
		SenS (Sensory-Somatic)  

**Note that the Weighted Referential Activity Dictionary (WRAD) is not
included in this repository as it is not covered by the GNU General Public
License. The WRAD can be downloaded directly from
<https://github.com/DAAP/WRAD>.**
	
	
##INSTALLING DAAP09.6 FOR MAC OSX

Create a new folder (in these instructions the name of this folder is
`DAAP09`), and copy all the files in categories A, B and C above,from the
DAAP09.6 repository into this folder. (Even though `ZBad.txt`, `ZChange.txt`
and `ZGood.txt` are currently empty, `DAAP09.6` still requires that there be
files with these names.)

Create a subfolder of the DAAP09 folder labeled `DicStore` and copy the
Referential Process dictionary files (in D above) into this folder. Also
download the file `WRAD.Wt` from <https://github.com/DAAP/WRAD> and copy it
into this subfolder.

Create a subfolder of the DAAP09 folder for each project (in these
instructions, this subfolder is named `Project`).

Create a subfolder of the Project folder named `DATA`; CAUTION: DAAP is case
sensitive; a folder named `data` will not work.

Create a subfolder of the Project folder named `Dics`. Copy the dictionaries
you wish to use for this project into this dics subfolder.

Copy the text files to be processed into the Project folder. These files must
be in text (`.txt`) format, and their names must all be of the form
`FileName.txt`, where FileName consists only of letters and numbers, no
spaces, commas or dots.

##INSTALLING DAAP09.6 ON A WINDOWS PLATFORM

`DAAP09.6.pl` is written in perl; you need to have the perl interpreter
installed on your computer. There are free downloads available at
<www.perl.org>, and at <www.activestate.com/activeperl>.

Create a new folder (in these instructions the name of this folder is
`DAAP09`), and copy all the above files from the DAAP09.6 repository into this
folder.

Create a subfolder of the DAAP09 folder labeled `DicStore` and copy the
Referential Process dictionary files (in D above) into this folder. Also
download the file `WRAD.Wt` from <https://github.com/DAAP/WRAD> and copy it
into this subfolder.

Create a subfolder of the DAAP09 folder for each project (in these
instructions, this subfolder is named `Project`).

Create a subfolder of the Project folder named `DATA`; CAUTION: DAAP is case
sensitive; a folder named `data` will not work.

Create a subfolder of the Project folder named `Dics`. Copy the dictionaries
you wish to use for this project into this dics subfolder.

Copy the text files to be processed into the Project folder. These files must
be in text (`.txt`) format, and their names must all be of the form
`FileName.txt`, where FileName consists only of letters and numbers, no
spaces, commas or dots.

**[The operating instructions for DAAP09.6 are contained in a separate
document in this repository.](DAAP09.6OPERATINGINSTRUCTIONS.md)**