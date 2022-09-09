% aR_extractFeats.m - the script for extracting features in Praat
% Syntax: 
%   aR_extractFeats(main,wav_dir,feat_dir,praat_bin,praat_script);   
%
% Subfunctions: 
%   See also: 
%
% AUTHOR    : Daniel Bone
%             dbone@usc.edu
% Copyright 2013  SAIL

function aR_extractFeats(main,wav_dir,feat_dir,praat_bin,praat_script)

fprintf('\nExtracting pitch and intensity with Praat....\n');
pause(1);
praat_file='batchf0E_perFileEdited.praat';

k=0;
for jj=1:1:length(main)
    %---- praat script with edits
    praat_template=textread(praat_script,'%[^\n]');
    fid=fopen(praat_file,'w+');
    fprintf(fid,['input_file$ = "',[wav_dir,main{jj}{1}],'"\n']);
    fprintf(fid,['output_file$ = "',[feat_dir,main{jj}{2},'/',main{jj}{1},'.txt'],'"\n']);
    
    warning off;
    [pathstr,name,ext]=fileparts(main{jj}{1});
    mkdir([feat_dir,main{jj}{2},'/',pathstr]);
    warning on;
    
    for jjj=1:1:length(praat_template)
        fprintf(fid,[praat_template{jjj},'\n']);
    end
    fclose(fid);
    
    %---- run script
    system([praat_bin,' ',praat_file]);
    
    if floor(jj*10/length(main))>k
        k=k+1;
        fprintf(['\t',num2str(k*10),'%% computed....\n']);
    end
    
end

fprintf('Extracted pitch and intensity.\n\n');

end