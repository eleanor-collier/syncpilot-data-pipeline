% arousalRating.m - Main file for arousal rating code. Declares variables
% and calls necessary functions.
% note: Use when wanting a single arousal rating per file.
% note: Uses 16kHz sampling rate.
% Syntax: 
%   arousalRating   
%
% Subfunctions: aR_extractFeats.m, aR_computeScores_pitchLogRaw.m,
% aR_computeScores_intensityRaw.m, aR_computeScores_ltas.m, aR_fuseScores.m
%   See also: 
%
% AUTHOR    : Daniel Bone
%             dbone@usc.edu
% Copyright 2013  SAIL

clear all;close all;fclose all;clc;

%------------ INPUTS ------------%

main_file=''; % format: input file,additional path for ouput,neutral,arousal,speaker
wav_dir=''; % base folder for wavs
feat_dir=''; % base folder for feats
score_dir=''; % base folder for scores
praat_bin=''; % location of Praat binary
praat_script='batchf0E_perFileTemplate.praat'; % template of the script
outputScore_file=''; % output file. format: scores, ground truth
% %---- IEMOCAP ----%
% main_file='IEMOCAPmod_main.txt'; % format: input file,ouput extension,neutral,arousal,speaker
% wav_dir='../data/IEMOCAP/'; % base folder for wavs
% feat_dir='../data/IEMOCAP/speechComFeats/'; % base folder for feats
% score_dir='../data/IEMOCAP/speechComScoresMod/'; % base folder for scores
% praat_bin='/Applications/Praat.app/Contents/MacOS/Praat';
% praat_script='batchf0E_perFileTemplate.praat';
% outputScore_file='IEMOCAPmod_scores.txt';
% %---- VAM ----%
% main_file='VAM_main.txt'; % format: input file,ouput extension,neutral,arousal,speaker
% wav_dir='../data/VAN/VAM_Audio/data/'; % base folder for wavs
% feat_dir='../data/VAN/VAM_Audio/speechComFeats/'; % base folder for feats
% score_dir='../data/VAN/VAM_Audio/speechComScores/'; % base folder for scores
% praat_bin='/Applications/Praat.app/Contents/MacOS/Praat';
% praat_script='batchf0E_perFileTemplate.praat';
% outputScore_file='VAM_scores.txt';
% %---- EMA5 ----%
% main_file='EMA5agree_main.txt'; % format: input file,ouput extension,neutral,arousal,speaker
% wav_dir='../data/ema_5emo/wave_arti/'; % base folder for wavs
% feat_dir='../data/ema_5emo/speechComFeats/'; % base folder for feats
% score_dir='../data/ema_5emo/speechComScoresAgree/'; % base folder for scores
% praat_bin='/Applications/Praat.app/Contents/MacOS/Praat';
% praat_script='batchf0E_perFileTemplate.praat';
% outputScore_file='EMA5agree_scores.txt';
% %---- emoDB ----%
% main_file='emoDB_main.txt'; % format: input file,ouput extension,neutral,arousal,speaker
% wav_dir='../data/emoDB/wav/'; % base folder for wavs
% feat_dir='../data/emoDB/speechComFeats/'; % base folder for feats
% score_dir='../data/emoDB/speechComScores/'; % base folder for scores
% praat_bin='/Applications/Praat.app/Contents/MacOS/Praat';
% praat_script='batchf0E_perFileTemplate.praat';
% outputScore_file='emoDB_scores.txt';

extract_features=1;
compute_scores=1;
fuse_scores=1;

%------------ BEGIN MAIN ------------%

%---- read main
main=textread(main_file,'%[^\n]');
main=regexp(main,',','split');

fprintf('--------------------------------------------------------\n\n');

%---- extract features
if extract_features
    aR_extractFeats(main,wav_dir,feat_dir,praat_bin,praat_script);
    fprintf('--------------------------------------------------------\n\n');
end

%---- compute scores
if compute_scores
    aR_computeScores_pitchLogRaw(main,wav_dir,feat_dir,score_dir);
    aR_computeScores_intensityRaw(main,wav_dir,feat_dir,score_dir);
    aR_computeScores_ltas(main,wav_dir,feat_dir,score_dir);
    fprintf('--------------------------------------------------------\n\n');
end

%---- fuse scores
if fuse_scores
    aR_fuseScores(main,score_dir,outputScore_file);
    fprintf('--------------------------------------------------------\n\n');
end

%------------ END MAIN ------------%

