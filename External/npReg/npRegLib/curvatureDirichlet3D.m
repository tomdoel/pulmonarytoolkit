function UNew = curvatureDirichlet3D(varargin)
% curvatureDirichlet3D: solve curvature registraion in 3D with Dirichlet
%        boundary conditions
%
%
% author: Nathan D. Cahill
% affiliation: Rochester Institute of Technology
% date: January 2014
% licence: GNU GPL v3 licence.
%
% This code is copyright Nathan D. Cahill and has been distributed as part of the
% Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
%
%

% parse input arguments
[U,F,PixSize,M,N,P,RegularizerFactor] = parse_inputs(varargin{:});

% add displacement vectors to multiple of force field
FNew = F/RegularizerFactor;

% compute sine transform of new force field
FS = discreteSineTransform(FNew,M,N,P);

% construct images of coordinates scaled by pi/(N or M or P)
[a,b,c] = ndgrid(pi*(0:(M-1))/(M-1),pi*(0:(N-1))/(N-1),pi*(0:(P-1))/(P-1));

% construct LHS factor
LHSfactor = (2*cos(a) + 2*cos(b) + 2*cos(c) - 6).^2;

% if gamma is zero, set origin term to 1, as DC term does not matter
LHSfactor(1,1,1) = 1;

% solve for FFT of U
US = -cat(4,FS(:,:,:,1)./LHSfactor,FS(:,:,:,2)./LHSfactor,FS(:,:,:,3)./LHSfactor);

% perform inverse DST
UNew = discreteSineTransform(US,M,N,P);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FS = discreteSineTransform(F,M,N,P);
% compute discrete sine transform of 3-D vector field

% initialize resulting array
FS = F;

% first perform sine transform down columns
len = 2*M-2; ind = 1:M;
for p=1:P
    for n=1:N
        s = fft(FS(:,n,p,:),len,1);
        FS(:,n,p,:) = imag(s(ind,:,:,:));
    end
end
FS = sqrt(2/(M-1))*FS;

% next perform sine transform across rows
len = 2*N-2; ind = 1:N;
for p=1:P
    for m=1:M
        s = fft(FS(m,:,p,:),len,2);
        FS(m,:,p,:) = imag(s(:,ind,:,:));
    end
end
FS = sqrt(2/(N-1))*FS;

% finally perform sine transform across pages
len = 2*P-2; ind = 1:P;
for n=1:N
    for m=1:M
        s = fft(FS(m,n,:,:),len,3);
        FS(m,n,:,:) = imag(s(:,:,ind,:));
    end
end
FS = sqrt(2/(P-1))*FS;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [U,F,PixSize,M,N,P,RegularizerFactor] = parse_inputs(varargin);

% get displacement field and check size
U = varargin{1};
F = varargin{2};
PixSize = varargin{4}(1:3);
M = varargin{5};
N = varargin{6};
P = varargin{7};
RegularizerFactor = varargin{10};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%