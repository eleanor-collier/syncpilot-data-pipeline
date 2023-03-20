% aRC_computeScores_ltas.m - build neutral emotion models (or global
% if no neutral exists) and score each instance for 
% HF500. Window size 1s.
% note: use for continuous vocal arousal rating
%
% Syntax: 
%   aRC_computeScores_ltas(main,wav_dir,feat_dir,score_dir)   
%
% Subfunctions: 
%   See also: 
%
% AUTHOR    : Daniel Bone
%             dbone@usc.edu
% Copyright 2013  SAIL

function aRC_computeScores_ltas2(main,wav_dir,feat_dir,score_dir)

%------------ BEGIN CODE ------------%

fprintf('\nComputing scores for HF500....\n');
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
k=0;
for subject=1:1:length(subjects)
    
    fprintf('\t Speaker %d of %d\n',subject,length(subjects));
    files_neutral=find(File_subject==subject); % perform global speaker modeling
    feature_cat=[];
    for iii=1:1:length(files_neutral)
        file_cat=[];
        time_cat=[];
        fid=fopen([feat_dir,main{subject}{2},'/',Files(files_neutral(iii)).fname,'.wav.txt']);
        feature=textscan(fid,'%f\t%f\t%f\n','Headerlines',1);
        fclose(fid);
        featurep=feature{2};
        featuret=feature{1};
        featurep(featurep==0)=NaN;
        
        featurepbuffer=buffer(featurep,100,99);
        featurepbuffer(featurepbuffer==0)=NaN;
        featurepbmed=log(nanmedian(featurepbuffer));
        featuretbuffer=buffer(featuret,100,99);
        featuretbmed=featuretbuffer(51,:);
        %     featurebuffer=buffer(feature,100,99);
        %     featurebmed=nanmedian(featurebuffer);
        %     featurebmed(isnan(featurepbmed))=NaN;
        
        featurepbmed(featuretbmed<=0)=[];
        featuretbmed(featuretbmed<=0)=[];
        
        [acoustic,Fs]=wavread([wav_dir,Files(files_neutral(iii)).fname,'.wav']);
        if size(acoustic,1)==2
            acoustic=acoustic(1,:);
        elseif size(acoustic,2)==2
            acoustic=acoustic(:,1);
        end
        acoustic=buffer(acoustic,round(0.025*Fs),round(0.015*Fs));
        
        acoustic(:,1:featuretbmed(1)*100-1)=[]; % align feature file and acoustic file
        
        window_sz=1; % window size in seconds
        window_sz=window_sz*100;
        
        for jj=window_sz/2+1:1:length(acoustic)-3*(window_sz/2-1)
            acoustic_wn=acoustic(:,jj-window_sz/2:jj+window_sz/2-1);
            acoustic_wn=acoustic_wn(:,find(~isnan(featurepbmed(jj-window_sz/2:jj+window_sz/2-1))));
            time=featuretbmed(jj);
            
            if ~isempty(acoustic_wn)

                linfbe=abs(fft(acoustic_wn));nFFT=size(linfbe,1);n500=ceil(nFFT/Fs*500)+1;linfbe=mean(linfbe,2);n80=ceil(nFFT/Fs*80);
                ltas=sum(linfbe(n500+1:ceil(nFFT/2)+1))/sum(linfbe(n80:n500));
                feature_cat=[feature_cat;log(ltas)];
                file_cat=[file_cat;log(ltas)];
                time_cat=[time_cat;time];
                
            end
        end
        
        ltas_feat{files_neutral(iii)}=file_cat;
        ltas_time{files_neutral(iii)}=time_cat;
    end
    gn = feature_cat(~isnan(feature_cat));
    gns{subject}=gn;
end

%---- score utterances on models
for ii=1:1:length(Files)
    subject=File_subject(ii);
    
    feature=ltas_feat{ii};
    arousal=NaN(length(feature),1);
    for jj=1:1:length(feature)
        arousal(jj,1)=2*(mean(feature(jj)>=gns{subject}))-1;
    end
    time=ltas_time{ii};
    
    score_arousal{ii}=arousal;
    score_time{ii}=time;
    
    
    if floor(ii*10/length(Files))>k
        k=k+1;
        fprintf(['\t',num2str(k*10),'%% computed....\n']);
    end
end

%---- store scores for fusion with this score HF500
save([score_dir,'aRC_ltas.mat'],'score_arousal','score_time','File_subject');

fprintf('Scores computed for HF500.\n\n');

% %---- correlate scores with arousal
% [r_arousal,p_arousal]=corr(score_arousal,File_arousal,'type','Spearman','rows','complete');
% fprintf('\tCorrelation with arousal is r=%0.2f\n\n',r_arousal);

%------------ Code Finish ------------%