% chopWav.m - chops wav by placing Gaussian white noise where a
% person is not speaking according to the VAD
% Syntax: 
%   chopWav   
%
% Subfunctions: 
%   See also: 
%
% AUTHOR    : Daniel Bone
%             dbone@usc.edu
% Copyright 2013  SAIL

clear all;close all;fclose all;clc;

%%%%------------ INPUTS ------------%%%%
chop_main='CreativeIT_chopMain.txt'; % main file for chopping, listed as wav file, vad file (vad format: speech start, speech end)
wav_dir='../data/CreativeIT/'; % base folder for wavs
vad_dir='../data/CreativeIT/transcription/'; % base folder for VAD
wavout_dir='../data/CreativeIT/choppedVAD/'; % output directory for wavs

%%%%------------ MAIN ------------%%%%

main=textread(chop_main,'%[^\n]');
main=regexp(main,',','split');

fprintf('Chopping files with VAD.\n\n');
for jj=1:1:length(main)
    fprintf('\tFile %d out of %d files\n',jj, length(main));
    [wav,Fs]=wavread([wav_dir,main{jj}{1}]);
    if size(wav,2)>size(wav,1)
        wav=wav';
    end
    wav=wav(:,1);
    
    vad=csvread([vad_dir,main{jj}{2}]);
    vadstart=vad(:,1);
    vadend=vad(:,2);
    
    vadv=zeros(length(wav),1);
    for jjj=1:1:length(vadstart)
        vadv(max(ceil(vadstart(jjj)*Fs),1):min(floor(vadend(jjj)*Fs),length(wav)))=1;
    end
    vadv=logical(vadv);
    
    speechwav=zeros(length(wav),1);
    noiseadd=zeros(length(wav),1);
    
    speechwav(vadv)=wav(vadv);
    noisewav=wav(~vadv);
    noisepower=sqrt(mean(noisewav.^2));
    signalmean=mean(wav);
    noiseadd(~vadv)=randn(sum(~vadv),1)*sqrt(noisepower)/10+signalmean;
    
    prepWav=speechwav+noiseadd;
    
    prepFile=[wavout_dir,main{jj}{1}];
    [filepath,filename,fileext]=fileparts(prepFile);
    
    warning off;
    mkdir(filepath);
    warning on;
    
    wavwrite(prepWav,Fs,prepFile);
end

fprintf('\nFiles chopped with VAD.\n');