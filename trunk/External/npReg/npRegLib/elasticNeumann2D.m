function UNew = elasticNeumann2D(varargin);
% elasticNeumann2D: solve elastic registraion in 2D with Neumann
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
[U,F,mu,lambda,gamma,PixSize,NumPix] = parse_inputs(varargin{:});

% construct filters that implement discretized Navier-Lame equations
d1 = [1;-2;1]/(PixSize(1)^2);
d2 = [1 -2 1]/(PixSize(2)^2);
d12 = [1 0 -1;0 0 0;-1 0 1]/(4*PixSize(1)*PixSize(2));

[A11,A22] = deal(zeros(3,3));
A11(2,2) = gamma;
A11(:,2) = A11(:,2) + (lambda+2*mu)*d1;
A11(2,:) = A11(2,:) + mu*d2;
A22(2,2) = gamma;
A22(:,2) = A22(:,2) + mu*d1;
A22(2,:) = A22(2,:) + (lambda+2*mu)*d2;

A12 = d12*(lambda+mu)/4;
A21 = A12;

% add displacement vectors to multiple of force field
F = gamma*U + F;

% multiply force field by adjoint of Navier-Lame equations
Fnew = zeros(NumPix(1),NumPix(2),2);
Fnew(:,:,1) = imfilter(F(:,:,1),A22,'replicate') - imfilter(F(:,:,2),A12,'replicate');
Fnew(:,:,2) = imfilter(F(:,:,2),A11,'replicate') - imfilter(F(:,:,1),A21,'replicate');

% compute dct of new force field
FnewF1 = real(fft(real(fft(Fnew(:,:,1),2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
FnewF2 = real(fft(real(fft(Fnew(:,:,2),2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
FnewF1 = FnewF1(1:NumPix(1),1:NumPix(2));
FnewF2 = FnewF2(1:NumPix(1),1:NumPix(2));

% construct images of coordinates scaled by pi/(N or M)
[alpha,beta] = ndgrid(pi*(0:(NumPix(1)-1))/(NumPix(1)-1),pi*(0:(NumPix(2)-1))/(NumPix(2)-1));

% construct LHS factor
T = 2*cos(alpha) + 2*cos(beta) - 4;
LHSfactor = (gamma + (lambda+2*mu).*T).*(gamma + mu.*T);

% set origin term to 1, as DC term does not matter
LHSfactor(1,1) = 1;

% solve for FFT of U
UF1 = FnewF1./LHSfactor;
UF2 = FnewF2./LHSfactor;

% perform inverse dct
U1 = real(ifft(real(ifft(UF1,2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
U2 = real(ifft(real(ifft(UF2,2*NumPix(1)-2,1)),2*NumPix(2)-2,2));

% crop and concatenate
UNew = cat(3,U1(1:NumPix(1),1:NumPix(2)),U2(1:NumPix(1),1:NumPix(2)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [U,F,mu,lambda,gamma,PixSize,NumPix] = parse_inputs(varargin);

% get displacement field and check size
U = varargin{1};
F = varargin{2};
gamma = varargin{3};
PixSize = varargin{4}(1:2);
NumPix = [varargin{5} varargin{6}];
mu = varargin{8};
lambda = varargin{9};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%