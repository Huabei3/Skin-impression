function [pcseq,pcseq1,pcseq2]=pc_seqScheffe(items)
%create a randomized sequence for a Scheffé paired
%comparison experiment.
%items = number of items.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
pcseq=pc_seq(items);
pcseq=[pcseq;[pcseq(:,2),pcseq(:,1)]];
pcseq=pcseq(randperm(length(pcseq(:,1))),:);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function v=pc_seq(n,r)

% PC_SEQ: returns a set of indices to use as a sequence
% in a pair comparison experiment.
%
% Example: 
% v=pc_seq(n,'r') randomly generates all the pairs for the integers 1:n
%
% v=pc_seq(n) generates a linearly spaced matrix in place of 
% a randomised one.
%
%   Colour Engineering Toolbox
%   author:    © Phil Green
%   version:   1.1
%   date:      24-08-2002
%   book:      http://www.wileyeurope.com/WileyCDA/WileyTitle/productCd-0471486884.html
%   web:       http://www.digitalcolour.org

j=(1:1:n);
k=repmat(j,n,1)-diag(j);
t=tril(k);T=t(t>0);
u=triu(k)';U=u(u>0);
v=[T,U];
if nargin>1
    if strcmp(r,'r')
        f=fliplr(v);   
        k=n*(n-1)/2;
        x=randperm(k); % set of random indices
        y=randperm(k);
        g=(2:2:2*floor(k/2));
        h=y(g);
        v(h,:)=f(h,:); % flip half the rows
        v=v(x,:);      % use x as index vector to shuffle the rows
    end   
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



