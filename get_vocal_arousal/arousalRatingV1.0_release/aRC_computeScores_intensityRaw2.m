% aR_computeScores_intensityRaw.m - build neutral emotion models (or global
% if no neutral exists) and score each instance for vocal intensity.
% note: use for continuous vocal arousal rating
%
% Syntax: 
%   aRC_computeScores_intensityRaw(main,wav_dir,feat_dir,score_dir)   
%
% Subfunctions: 
%   See also: 
%
% AUTHOR    : Daniel Bone
%             dbone@usc.edu
% Copyright 2013  SAIL

function aRC_computeScores_intensityRaw2(main,wav_dir,feat_dir,score_dir)

%------------ BEGIN CODE ------------%

fprintf('\nComputing scores for intensity....\n');
pause(1);

%---- prepare file parsing data
for ii=1:1:length(main)
    [path,fname,ext]=fileparts(main{ii}{1});
    Files(ii).fname=[path,'/',fname];
    Files(ii).subject=main{ii}{3};
    subjects{ii}=Files(ii).subject;
end
subjects=unique(subjects);

for ii=1:1:length(Files)
    File_subject(ii,1)=find(strcmp(subjects,Files(ii).subject));
end

%---- extract features from neutral files
%---- build models
for subject=1:1:length(subjects)
    files_neutral=find(File_subject==subject); % perform global speaker modeling
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
        feature=feature(~isnan(feature));
        
        feature_cat=[feature_cat;feature];
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
    featuret=feature{1};
    feature=feature{3};
    featurepbuffer=buffer(featurep,100,99);
    featurepbuffer(featurepbuffer==0)=NaN;
    featurepbmed=log(nanmedian(featurepbuffer));
    featuretbuffer=buffer(featuret,100,99);
    featuretbmed=featuretbuffer(51,:);
    featurebuffer=buffer(feature,100,99);
    featurebmed=nanmedian(featurebuffer);
    featurebmed(isnan(featurepbmed))=NaN;
    
    featurepbmed(featuretbmed<=0)=[];
    featurebmed(featuretbmed<=0)=[];
    featuretbmed(featuretbmed<=0)=[];
    
    %---- intensity scoring
    gn=gns{subject};
    emo_scorei=[];
    for jjj=1:1:length(featurebmed)
        if ~isnan(featurepbmed(jjj))
            emo_scorei(jjj,1)=2*mean(featurebmed(jjj)>gn)-1;
        else
            emo_scorei(jjj,1)=NaN;
        end
    end
    
    score_arousal{ii}=emo_scorei;
    score_time{ii}=featuretbmed;
    
    if floor(ii*10/length(Files))>k
        k=k+1;
        fprintf(['\t',num2str(k*10),'%% computed....\n']);
    end
end

%---- store scores for fusion
save([score_dir,'aRC_intensityRaw.mat'],'score_arousal','score_time','File_subject');

fprintf('Scores computed for intensity.\n\n');

% %---- correlate scores with arousal
% [r_arousal,p_arousal]=corr(score_arousal,File_arousal,'type','Spearman','rows','complete');
% fprintf('\tCorrelation with arousal is r=%0.2f\n\n',r_arousal);

%------------ Code Finish ------------%