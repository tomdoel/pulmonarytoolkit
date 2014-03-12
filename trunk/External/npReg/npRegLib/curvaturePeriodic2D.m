function UNew = curvaturePeriodic2D(varargin);
% curvaturePeriodic2D: solve curvature registraion in 2D with periodic
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

% compute Fourier transform of new force field
FnewF1 = fft2(Fnew(:,:,1));
FnewF2 = fft2(Fnew(:,:,2));

% construct images of coordinates scaled by pi/(N or M)
[alpha,beta] = ndgrid(2*pi*(0:(NumPix(1)-1))/NumPix(1),2*pi*(0:(NumPix(2)-1))/NumPix(2));

% construct LHS factor
LHSfactor = (2*cos(alpha) + 2*cos(beta) - 4).^2;

% set origin term to 1, as DC term does not matter
LHSfactor(1,1) = 1;

% solve for FFT of U
UF1 = -FnewF1./LHSfactor;
UF2 = -FnewF2./LHSfactor;

% perform inverse fft and concatenate
UNew = cat(3,ifft2(UF1,'symmetric'),ifft2(UF2,'symmetric'));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [U,F,PixSize,NumPix,RegularizerFactor] = parse_inputs(varargin);

% get displacement field and check size
U = varargin{1};
F = varargin{2};
PixSize = varargin{4}(1:2);
NumPix = [varargin{5} varargin{6}];
RegularizerFactor = varargin{10};
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%