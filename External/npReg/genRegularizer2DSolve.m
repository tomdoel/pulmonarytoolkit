function U = genRegularizer2DSolve(varargin)
% genRegularizer2DSolve: solve registration equation in 2D using general
%       regularizer
% usage: U = genRegularizer2DSolve(F);
%    or: U = genRegularizer2DSolve(F,Alpha);
%    or: U = genRegularizer2DSolve(F,Alpha,BoundCond);
%
% arguments:
%   F (MxNx2) - force field
%   Alpha (1x4) - weights pertaining to the following components of the
%           regularizer (default Alpha = [1 1 1 1]):
%               Alpha(1): (div U)^2
%               Alpha(2): (curl U)^2
%               Alpha(3): (norm(grad div U))^2
%               Alpha(4): (norm(grad curl U))^2
%   BoundCond - boundary conditions, can be one of:
%               'Dirichlet' (default)
%               'Neumann'   
%               'Periodic'
%
% Note: Standard regularizers in the literature can be used according to
% the following choices of Alpha:
%               Elastic:   Alpha = [2 1 0 0];
%               Diffusion: Alpha = [1 1 0 0];
%               Curvature: Alpha = [0 0 1 1];
%
% Note: Dirichlet and Neumann boundary conditions are assumed to be
% homogeneous.
%

% author: Nathan D. Cahill
% affiliation: Rochester Institute of Technology
% date: January 2014
% licence: GNU GPL v3 licence.
%
% This code is copyright Nathan D. Cahill and has been distributed as part of the
% Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit

% parse input arguments
[F,Alpha,BoundCond,NumPix] = parseInputs(varargin{:});

% construct filters that implement Laplacian and grad div
d11 = zeros(3,3); d11(:,2) = [1;-2;1];
d22 = zeros(3,3); d22(2,:) = [1 -2 1];
d12 = [1 0 -1;0 0 0;-1 0 1]/4;
delta = [0 0 0;0 1 0;0 0 0];
L = d11 + d22;

K = imfilter(Alpha(1)*L,delta,'full') - imfilter(Alpha(3)*L,L,'full');
A11 = K - imfilter((Alpha(1)-Alpha(2))*d11,delta,'full') + ...
    imfilter((Alpha(3)-Alpha(4))*L,d11,'full');
A22 = K - imfilter((Alpha(1)-Alpha(2))*d22,delta,'full') + ...
    imfilter((Alpha(3)-Alpha(4))*L,d22,'full');
A12 = -imfilter((Alpha(1)-Alpha(2))*d12,delta,'full') + ...
    imfilter((Alpha(3)-Alpha(4))*L,d12,'full');
A21 = A12;

% filter force field
Fnew = zeros(NumPix(1),NumPix(2),2);
Fnew(:,:,1) = imfilter(F(:,:,1),A11,'replicate') + imfilter(F(:,:,2),A12,'replicate');
Fnew(:,:,2) = imfilter(F(:,:,1),A21,'replicate') + imfilter(F(:,:,2),A22,'replicate');

% compute sine transform of new force field
s = 2/sqrt((NumPix(1)-1)*(NumPix(2)-1));
FnewF1 = imag(fft(imag(fft(Fnew(:,:,1),2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
FnewF2 = imag(fft(imag(fft(Fnew(:,:,2),2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
FnewF1 = s*FnewF1(1:NumPix(1),1:NumPix(2));
FnewF2 = s*FnewF2(1:NumPix(1),1:NumPix(2));

% construct images of coordinates scaled by pi/(N or M)
[alpha,beta] = ndgrid(pi*(0:(NumPix(1)-1))/(NumPix(1)-1),pi*(0:(NumPix(2)-1))/(NumPix(2)-1));

% construct LHS factor
W = 2*cos(alpha) + 2*cos(beta) - 4;
LHSfactor = (Alpha(2) - Alpha(4).*W).*(Alpha(1) - Alpha(3).*W).*(W.^2);
LHSfactor(1,1) = 1;

% solve for FFT of U
UF1 = FnewF1./LHSfactor;
UF2 = FnewF2./LHSfactor;

% perform inverse DST
U1 = s*imag(fft(imag(fft(UF1,2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
U2 = s*imag(fft(imag(fft(UF2,2*NumPix(1)-2,1)),2*NumPix(2)-2,2));

% crop and concatenate
U = cat(3,U1(1:NumPix(1),1:NumPix(2)),U2(1:NumPix(1),1:NumPix(2)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [F,Alpha,BoundCond,NumPix] = parseInputs(varargin);

nargs = length(varargin);
error(nargchk(1,3,nargs));

% get displacement field and check size
F = varargin{1};
NumPix = [size(F,1) size(F,2)];
if ~isequal([NumPix 2],size(F))
    error('npReg:genRegularizer2DSolve:parseInputs:ForceFieldWrongSize',...
        'Force field must be MxNx2.');
end

% get alpha
if nargs<2
    Alpha = [];
else
    Alpha = varargin{2};
end
if isempty(Alpha)
    Alpha = [1 1 1 1];
end
if ~isequal(length(Alpha(:)),4)
    error('npReg:genRegularizer2DSolve:parseInputs:AlphaInvalid',...
        'Alpha must be 1x4.');
end

% get boundary conditions
BoundCondValid = {'dirichlet','neumann','periodic'};
if nargs<3
    BoundCond = '';
else
    BoundCond = lower(varargin{3});
end
if isempty(BoundCond)
    BoundCond = 'dirichlet';
end
ind = strmatch(BoundCond,BoundCondValid);
if isempty(ind)
    error('npReg:genRegularizer2DSolve:parseInputs:BoundCondNotRecognized',...
        'Boundary condition not recognized.');
else
    BoundCond = BoundCondValid{ind};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%