% aR_computeScores_intensityRaw.m - build neutral emotion models (or global
% if no neutral exists) and score each instance for vocal intensity.
%
% Syntax: 
%   aR_computeScores_intensityRaw(main,wav_dir,feat_dir,score_dir)   
%
% Subfunctions: 
%   See also: 
%
% AUTHOR    : Daniel Bone
%             dbone@usc.edu
% Copyright 2013  SAIL

function aR_computeScores_intensityRawFullFile(main,wav_dir,feat_dir,score_dir)

%------------ BEGIN CODE ------------%

fprintf('\nComputing scores for intensity....\n');
pause(1);

%---- prepare file parsing data
for ii=1:1:length(main)
    [filepath,filen,files]=fileparts(main{ii}{1});
    edited_name=[filepath,'/',filen,'_',main{ii}{8},files];
    [path,fname,ext]=fileparts(edited_name);
    Files(ii).fname=[path,'/',fname];
    Files(ii).subject=main{ii}{5};
    Files(ii).arousal=str2num(main{ii}{4});
    Files(ii).neutral=str2num(main{ii}{3});
    subjects{ii}=Files(ii).subject;
end
subjects=unique(subjects);

for ii=1:1:length(Files)
    File_subject(ii,1)=find(strcmp(subjects,Files(ii).subject));
    File_neutral(ii,1)=Files(ii).neutral;
    File_arousal(ii,1)=Files(ii).arousal;
end

%---- extract features from neutral files
%---- build models
for subject=1:1:length(subjects)
    files_neutral=find(File_subject==subject & File_neutral);
    if isempty(files_neutral)
        files_neutral=find(File_subject==subject); % perform global speaker modeling
    end
    feature_cat=[];
    for iii=1:1:length(files_neutral)
        fid=fopen([feat_dir,main{subject}{2},'/',Files(files_neutral(iii)).fname,'.wav.txt'],'r+');
        feature=textscan(fid,'%f\t%f\t%f\n','Headerlines',1);
        fclose(fid);
        featurep=feature{2};
        featurep(featurep==0)=NaN;
        feature=feature{3};
        feature(feature==0)=NaN;
        feature=feature(~isnan(featurep));
        featurep=featurep(~isnan(featurep));
        
        feature_cat=[feature_cat;nanmedian(feature)];
    end
    gn = feature_cat(~isnan(feature_cat));
    gns{subject}=gn;
end

%---- score utterances on models
k=0;
for ii=1:1:length(Files)
    subject=File_subject(ii);
    fid=fopen([feat_dir,main{ii}{2},'/',Files(ii).fname,'.wav.txt'],'r+');
    feature=textscan(fid,'%f\t%f\t%f\n','Headerlines',1);
    fclose(fid);
    featurep=feature{2};
    featurep(featurep==0)=NaN;
    feature=feature{3};
    feature(feature==0)=NaN;
    feature=feature(~isnan(featurep));
    featurep=featurep(~isnan(featurep));
    
    m=nanmedian(feature);
    if ~isnan(m)
        score_arousal(ii,1)=2*(mean(m>=gns{subject}))-1;
    else
        score_arousal(ii,1)=NaN;
    end
    
    
    if floor(ii*10/length(Files))>k
        k=k+1;
        fprintf(['\t',num2str(k*10),'%% computed....\n']);
    end
end

%---- store scores for fusion
save([score_dir,'aR_intensityRaw.mat'],'score_arousal','File_arousal','File_subject');

fprintf('Scores computed for intensity.\n\n');

%---- correlate scores with arousal
[r_arousal,p_arousal]=corr(score_arousal,File_arousal,'type','Spearman','rows','complete');
fprintf('\tCorrelation with arousal is r=%0.2f\n\n',r_arousal);

%------------ Code Finish ------------%