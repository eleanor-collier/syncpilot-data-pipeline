% arousalRatingContinous.m - Main file for arousal rating code. Declares variables
% and calls necessary functions.
% note: Use when wanting continuous ratings within each file.
% note: Uses 16kHz sampling rate.
% Syntax: 
%   arousalRatingContinuous   
%
% Subfunctions: aR_extractFeats.m, aRC_computeScores_pitchLogRaw.m,
% aRC_computeScores_intensityRaw.m, aRC_computeScores_ltas.m, aRC_fuseScores.m
%   See also: 
%
% AUTHOR    : Daniel Bone
%             dbone@usc.edu
% Copyright 2013  SAIL

clear all;close all;fclose all;clc;

%------------ INPUTS ------------%

%---- wavs with using VAD ----%
main_file='CreativeIT_main.txt'; % format: input file,additional path for ouput,speaker,annotation file (annotation file in format col1: time, col2: arousal))
wav_dir='../data/CreativeIT/choppedVAD/'; % base folder for wavs
feat_dir='../data/CreativeIT/speechComFeatsChop/'; % base folder for feats
score_dir='../data/CreativeIT/speechComScoresChop/'; % base folder for scores
annotation_dir='../data/CreativeIT/annotations_txt/'; % base folder for ratings
praat_bin='/Applications/Praat.app/Contents/MacOS/Praat'; % location of Praat binary
praat_script='batchf0E_perFileTemplate.praat'; % template of the script
arousal_mat='CreativeIT_rating.mat';
% outputScore_file='CreativeIT_scores.txt'; % output file. format: scores, ground truth
% %---- wavs without using VAD ----%
% main_file='CreativeIT_main.txt'; % format: input file,additional path for ouput,speaker,annotation file (annotation file in format col1: time, col2: arousal))
% % vad_file='CreativeIT_VAD'; % speech/non-speech listing, format: input file, associated speech/non-speech file name (vad file in format col1: speech start time, col2: speech end time).
% % * note: additional functionality to be added is that all files are first
% % run through VAD per speaker if multiple speakers and separate wave files
% % are created, often also called chop *
% wav_dir='../data/CreativeIT/'; % base folder for wavs
% feat_dir='../data/CreativeIT/speechComFeats/'; % base folder for feats
% score_dir='../data/CreativeIT/speechComScores/'; % base folder for scores
% annotation_dir='../data/CreativeIT/annotations_txt/'; % base folder for ratings
% praat_bin='/Applications/Praat.app/Contents/MacOS/Praat'; % location of Praat binary
% praat_script='batchf0E_perFileTemplate.praat'; % template of the script
% % outputScore_file='CreativeIT_scores.txt'; % output file. format: scores, ground truth
% arousal_mat='CreativeIT_rating.mat';
extract_features=1;
compute_scores=1;
fuse_scores=1;
annotations_exist=1;

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
    aRC_computeScores_pitchLogRaw2(main,wav_dir,feat_dir,score_dir);
    aRC_computeScores_intensityRaw2(main,wav_dir,feat_dir,score_dir);
    aRC_computeScores_ltas2(main,wav_dir,feat_dir,score_dir);
    fprintf('--------------------------------------------------------\n\n');
end

%---- fuse scores
if fuse_scores
    aRC_fuseScores(main,score_dir,annotation_dir,annotations_exist,arousal_mat);
    fprintf('--------------------------------------------------------\n\n');
end

%------------ END MAIN ------------%

