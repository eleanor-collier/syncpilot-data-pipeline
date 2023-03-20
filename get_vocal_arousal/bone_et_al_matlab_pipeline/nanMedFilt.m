% nanMedFilt.m - performs a median filtering on the non-NaN values of
% window size N
% Syntax: 
%   nanMedFilt   
%
% Subfunctions: 
%   See also: 
%
% AUTHOR    : Daniel Bone
%             dbone@usc.edu
% Copyright 2013  SAIL

function Y = nanMedFilt(X,N)

if mod(N,2)==0 % make N an odd
    N=N+1;
end

if size(X,2)>size(X,1) % make X a column
    X=X';
end

Y=NaN(size(X));

X=[NaN(N-1,1);X];
% X=[NaN(floor(N/2),1);X;NaN(floor(N/2),1)];

X=buffer(X,N,N-1);
Y=nanmedian(X,1);
Y=Y(N:end)';
% for jj=1:1:length(Y)
%     a=nanmedian(X(jj:jj+N-1));
%     if ~isempty(a);
%         Y(jj)=a;
%     end
% end