function UNew = fluidPeriodic2D(varargin);
% fluidPeriodic2D: solve fluid registraion in 2D with Periodic
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
[DU,F,mu,lambda,PixSize,NumPix,HX,HY] = parse_inputs(varargin{:});

% construct filters that implement discretized Navier-Lame equations
d1 = [1;-2;1]/(PixSize(1)^2);
d2 = [1 -2 1]/(PixSize(2)^2);
d12 = [1 0 -1;0 0 0;-1 0 1]/(4*PixSize(1)*PixSize(2));

[A11,A22] = deal(zeros(3,3));
A11(:,2) = A11(:,2) + (lambda+2*mu)*d1;
A11(2,:) = A11(2,:) + mu*d2;
A22(:,2) = A22(:,2) + mu*d1;
A22(2,:) = A22(2,:) + (lambda+2*mu)*d2;

A12 = d12*(lambda+mu)/4;
A21 = A12;

% multiply force field by adjoint of Navier-Lame equations
Fnew = zeros(NumPix(1),NumPix(2),2);
Fnew(:,:,1) = imfilter(F(:,:,1),A22,'replicate') - imfilter(F(:,:,2),A12,'replicate');
Fnew(:,:,2) = imfilter(F(:,:,2),A11,'replicate') - imfilter(F(:,:,1),A21,'replicate');

% compute Fourier transform of new force field
FnewF1 = fft2(Fnew(:,:,1));
FnewF2 = fft2(Fnew(:,:,2));

% construct images of coordinates scaled by pi/(N or M)
[alpha,beta] = ndgrid(2*pi*(0:(NumPix(1)-1))/NumPix(1),2*pi*(0:(NumPix(2)-1))/NumPix(2));

% construct LHS factor
T = 2*cos(alpha) + 2*cos(beta) - 4;
LHSfactor = mu.*(lambda+2*mu).*(2*cos(alpha) + 2*cos(beta) - 4).^2;

% set origin term to 1, as DC term does not matter
LHSfactor(1,1) = 1;

% solve for FFT of V
VF1 = FnewF1./LHSfactor;
VF2 = FnewF2./LHSfactor;

% perform inverse fft and concatenate
V = cat(3,ifft2(VF1,'symmetric'),ifft2(VF2,'symmetric'));

% construct estimate of transformation Jacobian
J = zeros(NumPix(1),NumPix(2),2,2);
J(:,:,1,1) = 1 - imfilter(V(:,:,1),HX,'replicate','same');
J(:,:,2,1) = -imfilter(V(:,:,1),HY,'replicate','same');
J(:,:,1,2) = -imfilter(V(:,:,2),HX,'replicate','same');
J(:,:,2,2) = 1 - imfilter(V(:,:,2),HY,'replicate','same');

% now perform Euler integration to construct new displacements
UNew = zeros(NumPix(1),NumPix(2),2);
UNew(:,:,1) = J(:,:,1,1).*V(:,:,1) + J(:,:,1,2).*V(:,:,2);
UNew(:,:,2) = J(:,:,2,1).*V(:,:,1) + J(:,:,2,2).*V(:,:,2);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [DU,F,mu,lambda,PixSize,NumPix,HX,HY] = parse_inputs(varargin);

% get arguments
F = varargin{2};
PixSize = varargin{4}(1:2);
NumPix = [varargin{5} varargin{6}];
mu = varargin{8};
lambda = varargin{9};
DU = varargin{11};
HX = varargin{12};
HY = varargin{13};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%