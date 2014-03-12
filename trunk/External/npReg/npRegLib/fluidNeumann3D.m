function UNew = fluidNeumann3D(varargin);
% fluidNeumann3D: solve fluid registraion in 3D with Neumann
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
[DU,F,mu,lambda,PixSize,M,N,P,RegularizerFactor,HX,HY,HZ] = parse_inputs(varargin{:});

% multiply F by adjoint of Navier-Lame equations
FNew = adjointNL(F/RegularizerFactor,mu,lambda,0,M,N,P);

% compute sine transform of new force field
FS = discreteCosineTransform(FNew,M,N,P);

% construct images of coordinates scaled by pi/(N or M or P)
[a,b,c] = ndgrid(pi*(0:(M-1))/(M-1),pi*(0:(N-1))/(N-1),pi*(0:(P-1))/(P-1));

% construct LHS factor
LHSfactor = mu.*(lambda+2*mu).*(2*cos(a) + 2*cos(b) + 2*cos(c) - 6).^2;

% if gamma is zero, set origin term to 1, as DC term does not matter
LHSfactor(1,1,1) = 1;

% solve for FFT of U
VS = cat(4,FS(:,:,:,1)./LHSfactor,FS(:,:,:,2)./LHSfactor,FS(:,:,:,3)./LHSfactor);

% perform inverse DST
V = discreteCosineTransform(VS,M,N,P);

% now perform Euler integration to construct new displacements
UNew = zeros(M,N,P,3);
UNew(:,:,:,1) = (1 - imfilter(V(:,:,:,1),HX,'replicate','same')).*V(:,:,:,1) - ...
    imfilter(V(:,:,:,2),HY,'replicate','same').*V(:,:,:,2) - ...
    imfilter(V(:,:,:,3),HZ,'replicate','same').*V(:,:,:,3);
UNew(:,:,:,2) = -imfilter(V(:,:,:,1),HY,'replicate','same').*V(:,:,:,1) + ...
    (1 - imfilter(V(:,:,:,2),HY,'replicate','same')).*V(:,:,:,2) - ...
    imfilter(V(:,:,:,3),HY,'replicate','same').*V(:,:,:,3);
UNew(:,:,:,3) = -imfilter(V(:,:,:,1),HZ,'replicate','same').*V(:,:,:,1) - ...
    imfilter(V(:,:,:,2),HZ,'replicate','same').*V(:,:,:,2) + ...
    (1 - imfilter(V(:,:,:,3),HZ,'replicate','same')).*V(:,:,:,3);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function FS = discreteCosineTransform(F,M,N,P);
% compute discrete cosine transform of 3-D vector field

% initialize resulting array
FS = F;

% first perform cosine transform down columns
len = 2*M-2; ind = 1:M;
for p=1:P
    for n=1:N
        s = fft(FS(:,n,p,:),len,1);
        FS(:,n,p,:) = real(s(ind,:,:,:));
    end
end
FS = sqrt(2/(M-1))*FS;

% next perform cosine transform across rows
len = 2*N-2; ind = 1:N;
for p=1:P
    for m=1:M
        s = fft(FS(m,:,p,:),len,2);
        FS(m,:,p,:) = real(s(:,ind,:,:));
    end
end
FS = sqrt(2/(N-1))*FS;

% finally perform cosine transform across pages
len = 2*P-2; ind = 1:P;
for n=1:N
    for m=1:M
        s = fft(FS(m,n,:,:),len,3);
        FS(m,n,:,:) = real(s(:,:,ind,:));
    end
end
FS = sqrt(2/(P-1))*FS;
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
function [DU,F,mu,lambda,PixSize,M,N,P,RegularizerFactor,HX,HY,HZ] = parse_inputs(varargin);

% get displacement field and check size
F = varargin{2};
PixSize = varargin{4}(1:3);
M = varargin{5};
N = varargin{6};
P = varargin{7};
mu = varargin{8};
lambda = varargin{9};
RegularizerFactor = varargin{10};
DU = varargin{11};
HX = varargin{12};
HY = varargin{13};
HZ = varargin{14};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%