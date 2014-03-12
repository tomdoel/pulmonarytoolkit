function UNew = curvatureNeumann2D(varargin);
% curvatureNeumann2D: solve curvature registraion in 2D with Neumann
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
[U,F,PixSize,NumPix,RegularizerFactor] = parse_inputs(varargin{:});

% divide by regularizer factor
Fnew = F/RegularizerFactor;

% compute dct of new force field
FnewF1 = real(fft(real(fft(Fnew(:,:,1),2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
FnewF2 = real(fft(real(fft(Fnew(:,:,2),2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
FnewF1 = FnewF1(1:NumPix(1),1:NumPix(2));
FnewF2 = FnewF2(1:NumPix(1),1:NumPix(2));

% construct images of coordinates scaled by pi/(N or M)
[alpha,beta] = ndgrid(pi*(0:(NumPix(1)-1))/(NumPix(1)-1),pi*(0:(NumPix(2)-1))/(NumPix(2)-1));

% construct LHS factor
LHSfactor = (2*cos(alpha) + 2*cos(beta) - 4).^2;

% set origin term to 1, as DC term does not matter
LHSfactor(1,1) = 1;

% solve for FFT of U
UF1 = -FnewF1./LHSfactor;
UF2 = -FnewF2./LHSfactor;

% if gamma is zero, set DC term to 0
UF1(1,1) = 0;
UF2(1,1) = 0;

% perform inverse dct
U1 = real(ifft(real(ifft(UF1,2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
U2 = real(ifft(real(ifft(UF2,2*NumPix(1)-2,1)),2*NumPix(2)-2,2));

% crop and concatenate
UNew = cat(3,U1(1:NumPix(1),1:NumPix(2)),U2(1:NumPix(1),1:NumPix(2)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [U,F,PixSize,NumPix,RegularizerFactor] = parse_inputs(varargin);

% get displacement field and check size
U = varargin{1};
F = varargin{2};
PixSize = varargin{4}(1:2);
NumPix = [varargin{5} varargin{6}];
RegularizerFactor = varargin{10};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%