% aRC_fuseScores.m - the script for weighted summation fusion of per-
% feature vocal arousal scores, with scores assigned by correlation between 
% feature score vector and mean feature score vector
% note: use for continuous time arousal rating
%
% Syntax:
%   aRC_fuseScores(main,score_dir,outputScore_file,annotation_dir,annotations_exist,arousal_mat);
%
% Subfunctions:
%   See also:
%
% AUTHOR    : Daniel Bone
%             dbone@usc.edu
% Copyright 2013  SAIL

function aRC_fuseScores(main,score_dir,annotation_dir,annotations_exist,arousal_mat)

fprintf('\nFusing scores across features....\n\n');
pause(1);

load([score_dir,'aRC_pitchLogRaw.mat']);
scores0=score_arousal;
times0=score_time;
load([score_dir,'aRC_ltas.mat']);
scores1=score_arousal;
times1=score_time;
load([score_dir,'aRC_intensityRaw.mat']);
scores2=score_arousal;
times2=score_time;
speaker_id=File_subject;
k=0;

for jj=1:1:length(main)
    
    score0=scores0{jj};
    time0=times0{jj};
    score1=scores1{jj};
    time1=times1{jj};
    score2=scores2{jj};
    time2=times2{jj};
    
    % smooth all scores with a 100ms window
    tscore0=NaN(max(time0)*100,1);
    tscore0(round(time0*100))=score0;
    tscore0=nanMedFilt(tscore0,11);
    time0=find(~isnan(tscore0))/100;
    score0=tscore0(~isnan(tscore0));
    
    tscore1=NaN(max(time1)*100,1);
    tscore1(round(time1*100))=score1;
    tscore1=nanMedFilt(tscore1,11);
    time1=find(~isnan(tscore1))/100;
    score1=tscore1(~isnan(tscore1));
    
    tscore2=NaN(max(time2)*100,1);
    tscore2(round(time2*100))=score2;
    tscore2=nanMedFilt(tscore2,11);
    time2=find(~isnan(tscore2))/100;
    score2=tscore2(~isnan(tscore2));
    
    time=intersect(time0,time1);
    time=intersect(time,time2);
    if annotations_exist
        x=csvread([annotation_dir,main{jj}{4}]);
        activation_rating=x(:,2);
        activation_time=x(:,1);
        %activation_time=round(activation_time*100)/100; %heuristic assuming 0.01s resolution
        
        time=intersect(time,activation_time);
    end
    
    if length(time)>=10
        score0=score0(ismember(time0,time));
        score1=score1(ismember(time1,time));
        score2=score2(ismember(time2,time));
        
        w0=corr(score0,nanmean([score0,score1,score2],2),'type','Spearman','rows','complete');
        w1=corr(score1,nanmean([score0,score1,score2],2),'type','Spearman','rows','complete');
        w2=corr(score2,nanmean([score0,score1,score2],2),'type','Spearman','rows','complete');
        
        fprintf('log-pitch weight = %0.2f, HF500 weight = %0.2f, intensity weight = %0.2f\n\n',w0,w1,w2);
        
        %---- unweighted combinaton for scores
        scores_uw=(score0+score1+score2)/3;
        
        %---- weighted combination for scores
        scores_w=[w0*score0+w1*score1+w2*score2]/(abs(w0)+abs(w1)+abs(w2));
        
        ws(jj,:)=[w0,w1,w2];
        
        if annotations_exist
            
            activation_ratingfull=activation_rating;
            %activation_rating=activation_rating(ismember(activation_time,time));
            scores_uwfull=NaN(length(activation_ratingfull),1);
            scores_wfull=NaN(length(activation_ratingfull),1);
            time_activation=zeros(length(scores_w),1);
            for iii=1:1:length(time)
                time_activation(iii)=find(time(iii)==activation_time);
            end
            scores_uwfull(time_activation)=scores_uw;
            scores_wfull(time_activation)=scores_w;
            scores_uw=scores_uwfull;
            scores_w=scores_wfull;
            
            % arousal rating gets smoothed
            scores_uw=nanMedFiltNan(scores_uw,200);
            scores_w=nanMedFiltNan(scores_w,200);
            
%             %---- show correlations with features
%             [r_arousal,p_arousal]=corr(score0,activation_rating,'type','Spearman','rows','complete');
%             fprintf('\tLog-pitch correlation with arousal is r=%0.2f\n',r_arousal);
%             [r_arousal,p_arousal]=corr(score1,activation_rating,'type','Spearman','rows','complete');
%             fprintf('\tHF500 correlation with arousal is r=%0.2f\n',r_arousal);
%             [r_arousal,p_arousal]=corr(score2,activation_rating,'type','Spearman','rows','complete');
%             fprintf('\tIntensity correlation with arousal is r=%0.2f\n\n',r_arousal);
            
            %---- show correlation with unweighted
            activation_rating=activation_rating(1:length(scores_uw));
            [r_arousal,p_arousal]=corr(scores_uw,activation_rating,'type','Spearman','rows','complete');
            fprintf('Combining scores without weighting. Correlation with arousal is r=%0.2f\n\n',r_arousal);
            rcuw(jj)=r_arousal;
            
            %---- show correlation with weighted
            activation_rating=activation_rating(1:length(scores_w));
            [r_arousal,p_arousal]=corr(scores_w,activation_rating,'type','Spearman','rows','complete');
            fprintf('Combining scores with weighting. Correlation with arousal is r=%0.2f\n\n',r_arousal);
            rcw(jj)=r_arousal;
            
            mabduw(jj)=mean(abs(scores_w(~isnan(scores_uw))-activation_rating(~isnan(scores_uw))));
            mabeuw(jj)=mean(abs(activation_rating(~isnan(scores_uw))-nanmean(activation_rating(~isnan(scores_uw)))));
            mabdw(jj)=mean(abs(scores_w(~isnan(scores_w))-activation_rating(~isnan(scores_w))));
            mabew(jj)=mean(abs(activation_rating(~isnan(scores_w))-nanmean(activation_rating(~isnan(scores_w)))));
            
%             figure(1);plot(activation_time,activation_rating);hold on;plot(activation_time,scores_w,'k+--');hold off;
%             pause;
            
        end
        
        %     %---- save scores with fusion
        %     pause;
        %     [path,filename,extn]=fileparts(main{1}{1});
        %     warning off;
        %     mkdir([score_dir,main{2},path]);
        %     warning on;
        %     fid=fopen([score_dir,main{2},path,filename,'.txt'],'w+');
        %     fprintf(fid,'time,arousalScore,trueArousal\n');
        %     for jj=1:1:length(scores_w)
        %         fprintf(fid,'%f,%0.4f,%0.4f\n',time,scores_w(jj),activation_rating(jj));
        %     end
        
    else
        
        fprintf('Warning: File "%s" does not have enough scored samples',main{jj}{1});
        k=k+1;
        pause(2);
        
    end
    
end

fprintf('%d files were excluded.\n',k);

if annotations_exist
    rcuw=rcuw(rcuw~=0);
    rcw=rcw(rcw~=0);
    fprintf('%d out of %d correlations for the unweighted arousal are NaN.\n', sum(isnan(rcuw)), length(rcuw));
    fprintf('%d out of %d correlations for the weighted arousal are NaN.\n', sum(isnan(rcw)), length(rcw));
    fprintf('Median (IQR) correlation for the unweighted arousal is %0.2f (%0.2f).\n',nanmedian(rcuw),iqr(rcuw));
    fprintf('Median (IQR) correlation for the weighted arousal is %0.2f (%0.2f).\n\n',nanmedian(rcw),iqr(rcw));
    fprintf('Median of the mean absolute difference (median absolute of label) for unweighted arousal is %0.2f (%0.2f).\n',nanmedian(mabduw),nanmedian(mabeuw));
    fprintf('Median of the mean absolute difference (median absolute of label) for weighted arousal is %0.2f (%0.2f).\n',nanmedian(mabdw),nanmedian(mabew));
    
    figure(1);hist(rcw);xlabel('Correlation of the weighted arousal with true arousal');ylabel('Frequency');
end

save(arousal_mat,'rcw','rcuw','ws','mab*');

fprintf('Scores fused across features.\n\n');

p=signrank(rcw(~isnan(rcw)),0)

end