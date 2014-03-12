function UNew = curvaturePeriodic3D(varargin);
% curvaturePeriodic3D: solve curvature registration in 3D with periodic
%        boundary conditions
%
%
% author: Nathan D. Cahill
% affiliation: Rochester Institute of Technology
% date: January 2014
% licence: GNU GPL v3
%
% This code is copyright Nathan D. Cahill and has been distributed as part of the
% Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
%
%

% parse input arguments
[U,F,PixSize,M,N,P,RegularizerFactor] = parse_inputs(varargin{:});

% add displacement vectors to multiple of force field
FNew = F/RegularizerFactor;

% compute Fourier transform of new force field
FS = discreteFourierTransform(FNew,M,N,P);

% construct images of coordinates scaled by pi/(N or M or P)
[a,b,c] = ndgrid(pi*(0:(M-1))/(M-1),pi*(0:(N-1))/(N-1),pi*(0:(P-1))/(P-1));

% construct LHS factor
LHSfactor = (2*cos(a) + 2*cos(b) + 2*cos(c) - 6).^2;

% if gamma is zero, set origin term to 1, as DC term does not matter
LHSfactor(1,1,1) = 1;

% solve for FFT of U
US = -cat(4,FS(:,:,:,1)./LHSfactor,FS(:,:,:,2)./LHSfactor,FS(:,:,:,3)./LHSfactor);

% perform inverse DFT
UNew = discreteFourierTransformInverse(US,M,N,P);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FS = discreteFourierTransformInverse(F,M,N,P);
% compute inverse DFT of 3-D vector field

% initialize resulting array
FS = F;

% first perform sine transform down columns
for p=1:P
    for n=1:N
        FS(:,n,p,:) = ifft(FS(:,n,p,:),M,1,'symmetric');
    end
end

% next perform sine transform across rows
for p=1:P
    for m=1:M
        FS(m,:,p,:) = ifft(FS(m,:,p,:),N,2,'symmetric');
    end
end

% finally perform sine transform across pages
for n=1:N
    for m=1:M
        FS(m,n,:,:) = ifft(FS(m,n,:,:),P,3,'symmetric');
    end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FS = discreteFourierTransform(F,M,N,P);
% compute DFT of 3-D vector field

% initialize resulting array
FS = complex(F);

% first perform sine transform down columns
for p=1:P
    for n=1:N
        FS(:,n,p,:) = fft(FS(:,n,p,:),M,1);
    end
end

% next perform sine transform across rows
for p=1:P
    for m=1:M
        FS(m,:,p,:) = fft(FS(m,:,p,:),N,2);
    end
end

% finally perform sine transform across pages
for n=1:N
    for m=1:M
        FS(m,n,:,:) = fft(FS(m,n,:,:),P,3);
    end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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