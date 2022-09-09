% aR_fuseScores.m - the script for weighted summation fusion of per-
% feature vocal arousal scores, with scores assigned by correlation between 
% feature score vector and mean feature score vector
% 
% Syntax: 
%   aR_fuseScores(main,score_dir,outputScore_file);   
%
% Subfunctions: 
%   See also: 
%
% AUTHOR    : Daniel Bone
%             dbone@usc.edu
% Copyright 2013  SAIL

function aR_fuseScores(main,score_dir,outputScore_file)

fprintf('\nFusing scores across features....\n\n');
pause(1);

load([score_dir,'aR_pitchLogRaw.mat']);
scores0=score_arousal;
load([score_dir,'aR_ltas.mat']);
scores1=score_arousal;
load([score_dir,'aR_intensityRaw.mat']);
scores2=score_arousal;
speaker_id=File_subject;
activation_rating=File_arousal;

[r_arousal,p_arousal]=corr(scores0,activation_rating,'type','Spearman','rows','complete');
fprintf('\tLog-pitch correlation with arousal is r=%0.2f\n',r_arousal);
[r_arousal,p_arousal]=corr(scores1,activation_rating,'type','Spearman','rows','complete');
fprintf('\tHF500 correlation with arousal is r=%0.2f\n',r_arousal);
[r_arousal,p_arousal]=corr(scores2,activation_rating,'type','Spearman','rows','complete');
fprintf('\tIntensity correlation with arousal is r=%0.2f\n\n',r_arousal);

w0=zeros(size(scores0));w1=zeros(size(scores1));w2=zeros(size(scores2));
for ii=1:1:length(unique(speaker_id))
    t=speaker_id==ii;
    w0(t)=corr(scores0(t),mean([scores0(t),scores1(t),scores2(t)],2),'type','Spearman','rows','complete');
    w1(t)=corr(scores1(t),mean([scores0(t),scores1(t),scores2(t)],2),'type','Spearman','rows','complete');
    w2(t)=corr(scores2(t),mean([scores0(t),scores1(t),scores2(t)],2),'type','Spearman','rows','complete');
end
wMean(1)=nanmean(w0);
wMean(2)=nanmean(w1);
wMean(3)=nanmean(w2);
fprintf('\tMean correlation across speakers-- the un-normalized score weights:\n\t\tmean log-pitch weight = %0.2f, mean HF500 weight = %0.2f, mean intensity weight = %0.2f\n\n',wMean(1),wMean(2),wMean(3));

%---- unweighted combinaton for scores
scores_uw=scores0+scores1+scores2;
[r_arousal,p_arousal]=corr(scores_uw,activation_rating,'type','Spearman','rows','complete');
fprintf('\tCombining scores without weighting. Correlation with arousal is r=%0.2f\n\n',r_arousal);

%---- weighted combination for scores
scores_w=[w0.*scores0+w1.*scores1+w2.*scores2]./(abs(w0)+abs(w1)+abs(w2));
[r_arousal,p_arousal]=corr(scores_w,activation_rating,'type','Spearman','rows','complete');
fprintf('\tCombining scores with weighting. Correlation with arousal is r=%0.2f\n\n',r_arousal);

%---- save scores with fusion
fid=fopen(outputScore_file,'w+');
fprintf(fid,'arousalScore,trueArousal\n');
for jj=1:1:length(scores_w)
    fprintf(fid,'%0.4f,%0.4f\n',scores_w(jj),activation_rating(jj));
end

fprintf('Scores fused across features.\n\n');

end