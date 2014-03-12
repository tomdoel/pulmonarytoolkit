function UNew = elasticPeriodic3D(varargin);
% elasticPeriodic3D: solve elastic registraion in 3D with periodic
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
[U,F,mu,lambda,gamma,PixSize,M,N,P,RegularizerFactor] = parse_inputs(varargin{:});

% add displacement vectors to multiple of force field
F = gamma*U + F/RegularizerFactor;

% multiply F by adjoint of Navier-Lame equations
FNew = adjointNL(F,mu,lambda,gamma,M,N,P);

% compute DFT of new force field
FS = discreteFourierTransform(FNew,M,N,P);

% construct images of coordinates scaled by pi/(N or M or P)
[a,b,c] = ndgrid(pi*(0:(M-1))/(M-1),pi*(0:(N-1))/(N-1),pi*(0:(P-1))/(P-1));

% construct LHS factor
T = 2*cos(a) + 2*cos(b) + 2*cos(c) - 6;
LHSfactor = (gamma + (lambda+2*mu).*T).*(gamma + mu.*T);

% if gamma is zero, set origin term to 1, as DC term does not matter
LHSfactor(1,1,1) = 1;

% solve for FFT of U
US = cat(4,FS(:,:,:,1)./LHSfactor,FS(:,:,:,2)./LHSfactor,FS(:,:,:,3)./LHSfactor);

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
function FNew = adjointNL(F,mu,lambda,gamma,M,N,P);
% multiply vector field F by adjoint Navier-Lame equations

% initialize FNew
FNew = zeros(M,N,P,3);

% construct filter that implements 3-D Laplacian
L = (lambda+2*mu)*cat(3,[0 0 0;0 1 0;0 0 0],[0 1 0;1 -6 1;0 1 0],[0 0 0;0 1 0;0 0 0]);

% we will need to use L to form two different filters
% L1 = -(lambda+2*mu)*L; L1(2,2,2) = gamma + L1(2,2,2);
% L2 = -mu*L; L2(2,2,2) = gamma + L2(2,2,2);

% construct grad div filters
GD11 = (lambda+mu)*cat(3,zeros(3,3),[0 1 0;0 -2 0;0 1 0],zeros(3,3));
GD22 = ipermute(GD11,[2 1 3]);
GD33 = ipermute(GD11,[3 2 1]);
GD23 = zeros(3,3,3);
GD23(2,1,1) = 1; GD23(2,3,3) = 1; GD23(2,1,3) = -1; GD23(2,3,1) = -1;
GD23 = GD23*(lambda+mu)/4;
GD12 = ipermute(GD23,[3 1 2]);
GD13 = ipermute(GD23,[2 3 1]);

% perform filtering
FNew(:,:,:,1) = imfilter(F(:,:,:,1),L-GD11,'replicate') + ...
    imfilter(F(:,:,:,2),-GD12,'replicate') + ...
    imfilter(F(:,:,:,3),-GD13,'replicate');
FNew(:,:,:,2) = imfilter(F(:,:,:,1),-GD12,'replicate') + ...
    imfilter(F(:,:,:,2),L-GD22,'replicate') + ...
    imfilter(F(:,:,:,3),-GD23,'replicate');
FNew(:,:,:,3) = imfilter(F(:,:,:,1),-GD13,'replicate') + ...
    imfilter(F(:,:,:,2),-GD23,'replicate') + ...
    imfilter(F(:,:,:,3),L-GD33,'replicate');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [U,F,mu,lambda,gamma,PixSize,M,N,P,RegularizerFactor] = parse_inputs(varargin);

% get displacement field and check size
U = varargin{1};
F = varargin{2};
gamma = varargin{3};
PixSize = varargin{4}(1:2);
M = varargin{5};
N = varargin{6};
P = varargin{7};
mu = varargin{8};
lambda = varargin{9};
RegularizerFactor = varargin{10};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%