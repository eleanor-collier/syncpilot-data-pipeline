% nanMedFiltNan.m - performs a median filtering on the non-NaN values of
% window size N, only assigns non-NaN to non-NaN values
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
Xo=X;
X=[X;NaN(N-1,1)];
% X=[NaN(floor(N/2),1);X;NaN(floor(N/2),1)];

X=buffer(X,N,N-1);
Y=nanmedian(X,1);
Y=Y(floor(N/2)+1:floor(end-N/2))';
%figure(2);subplot(3,1,1);plot(Xo(1:100));
%figure(2);subplot(3,1,2);plot(Y(1:100));
Y(isnan(Xo))=NaN;
%figure(2);subplot(3,1,3);plot(Y(1:100));
% for jj=1:1:length(Y)
%     a=nanmedian(X(jj:jj+N-1));
%     if ~isempty(a);
%         Y(jj)=a;
%     end
% end