% arousalRating_fullFile.m - Main file for arousal rating code. Declares variables
% and calls necessary functions. Creates shorter versions of a long audio file.
% note: Use when wanting a single arousal rating per file.
% note: Uses 16kHz sampling rate.
% Syntax: 
%   arousalRating   
%
% Subfunctions: aR_extractFeats.m, aR_computeScores_pitchLogRawFullFile.m,
% aR_computeScores_intensityRawFullFile.m, aR_computeScores_ltasFullFile.m, aR_fuseScores.m
%   See also: 
%
% AUTHOR    : Daniel Bone
%             dbone@usc.edu
% Copyright 2013  SAIL

clear all;close all;fclose all;clc;

%------------ INPUTS ------------%


main_file=''; % format: input file,additional path for ouput,neutral,arousal,speaker,start time,end time
wav_dir=''; % base folder for wavs
feat_dir=''; % base folder for feats
score_dir=''; % base folder for scores
praat_bin=''; % location of Praat binary
praat_script='batchf0E_perFileTemplate.praat'; % template of the script
outputScore_file=''; % output file. format: scores, ground truth
% main_file='ADOSpGlobal_main.txt'; % format: input file,additional path for ouput,neutral,arousal,speaker,start time,end time
% wav_dir='../ADOS/data_final/'; % base folder for wavs
% feat_dir='../ADOS/prosody_subtasks/src/arousal/featsp/'; % base folder for feats
% score_dir='../ADOS/prosody_subtasks/src/arousal/scorespGlobal/'; % base folder for scores
% praat_bin='/Applications/Praat.app/Contents/MacOS/Praat'; % location of Praat binary
% praat_script='batchf0E_perFileTemplate.praat'; % template of the script
% outputScore_file='ADOSpGlobal_scores.txt'; % output file. format: scores, ground truth
% audio_file='psych.wav';

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
    aR_extractFeatsFullFile(main,wav_dir,feat_dir,praat_bin,praat_script,audio_file);
    fprintf('--------------------------------------------------------\n\n');
end

%---- compute scores
if compute_scores
    aR_computeScores_pitchLogRawFullFile(main,wav_dir,feat_dir,score_dir);
    aR_computeScores_intensityRawFullFile(main,wav_dir,feat_dir,score_dir);
    aR_computeScores_ltasFullFile(main,wav_dir,feat_dir,score_dir,audio_file);
    fprintf('--------------------------------------------------------\n\n');
end

%---- fuse scores
if fuse_scores
    aR_fuseScores(main,score_dir,outputScore_file);
    fprintf('--------------------------------------------------------\n\n');
end

%------------ END MAIN ------------%

