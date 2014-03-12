function U = biharmonic2DSolve(varargin)
% biharmonic2DSolve: solve Biharmonic equation in 2D
% usage: U = biharmonic2DSolve(F);
%    or: U = biharmonic2DSolve(F,BoundCond);
%
% Biharmonic equation is given by:
%        (del^4) U = F
%
% arguments:
%   F (MxNx2) - force field
%   BoundCond - boundary conditions, can be one of:
%        'Dirichlet' (default)
%        'Neumann'   
%        'Periodic'
%
% Note: Dirichlet and Neumann boundary conditions are assumed to be
% homogeneous.
%
%
% author: Nathan D. Cahill
% affiliation: Rochester Institute of Technology
% date: January 2014
% licence: GNU GPL v3 licence.
%
% This code is copyright Nathan D. Cahill and has been distributed as part of the
% Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit



% parse input arguments
[F,BoundCond,NumPix] = parseInputs(varargin{:});

% compute transform of force field, and create arrays for subsequent
% eigenvalue calculation
switch BoundCond
    
    case 'dirichlet'
        
        s = 2/sqrt((NumPix(1)-1)*(NumPix(2)-1));
        
        % discrete sine transform
        FF1 = imag(fft(imag(fft(F(:,:,1),2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
        FF2 = imag(fft(imag(fft(F(:,:,2),2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
        FF1 = s*FF1(1:NumPix(1),1:NumPix(2));
        FF2 = s*FF2(1:NumPix(1),1:NumPix(2));
        
        % arrays for eigenvalues
        [alpha,beta] = ndgrid(pi*(0:(NumPix(1)-1))/(NumPix(1)-1),pi*(0:(NumPix(2)-1))/(NumPix(2)-1));
        
    case 'neumann'
        
        s = 2/sqrt((NumPix(1)-1)*(NumPix(2)-1));

        % discrete cosine transform
        FF1 = real(fft(real(fft(F(:,:,1),2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
        FF2 = real(fft(real(fft(F(:,:,2),2*NumPix(1)-2,1)),2*NumPix(2)-2,2));

        FF1 = s*FF1(1:NumPix(1),1:NumPix(2));
        FF2 = s*FF2(1:NumPix(1),1:NumPix(2));
        
        % arrays for eigenvalues
        [alpha,beta] = ndgrid(pi*(0:(NumPix(1)-1))/(NumPix(1)-1),pi*(0:(NumPix(2)-1))/(NumPix(2)-1));
        
    case 'periodic'
        
        FF1 = zeros(NumPix(1),NumPix(2));
        FF1(1:NumPix(1)-1,:) = fft(F(:,:,1),NumPix(1)-1,1);
        FF1(:,1:NumPix(2)-1) = fft(FF1,NumPix(2)-1,2);
        
        FF2 = zeros(NumPix(1),NumPix(2));
        FF2(1:NumPix(1)-1,:) = fft(F(:,:,2),NumPix(1)-1,1);
        FF2(:,1:NumPix(2)-1) = fft(FF2,NumPix(2)-1,2);        

        % arrays for eigenvalues
        [alpha,beta] = ndgrid(2*pi*(0:(NumPix(1)-1))/(NumPix(1)-1),2*pi*(0:(NumPix(2)-1))/(NumPix(2)-1));
end

% construct eigenvalues
LHSfactor = (2*cos(alpha) + 2*cos(beta) - 4).^2;

% set origin term to 1, as DC term does not matter
LHSfactor(1,1) = 1;

% if periodic bc, set other corners to zero
if isequal(BoundCond,'periodic')
    LHSfactor(1,end) = 1;
    LHSfactor(end,1) = 1;
    LHSfactor(end,end) = 1;
end

% solve for transformed version of U
UF1 = FF1./LHSfactor;
UF2 = FF2./LHSfactor;

switch BoundCond
    
    case 'dirichlet'
        
        % discrete sine transform
        U1 = s*imag(fft(imag(fft(UF1,2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
        U2 = s*imag(fft(imag(fft(UF2,2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
        
    case 'neumann'
        
        % discrete cosine transform
        U1 = s*real(fft(real(fft(UF1,2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
        U2 = s*real(fft(real(fft(UF2,2*NumPix(1)-2,1)),2*NumPix(2)-2,2));
        
    case 'periodic'
        
        U1 = zeros(NumPix(1),NumPix(2));
        U1(1:NumPix(1)-1,:) = ifft(UF1,NumPix(1)-1,1);
        U1(:,1:NumPix(2)-1) = ifft(U1,NumPix(2)-1,2);
        U1 = real(U1);
        U1(:,end) = U1(:,1); U1(end,:) = U1(1,:);
        
        U2 = zeros(NumPix(1),NumPix(2));
        U2(1:NumPix(1)-1,:) = ifft(UF2,NumPix(1)-1,1);
        U2(:,1:NumPix(2)-1) = ifft(U2,NumPix(2)-1,2);
        U2 = real(U2);
        U2(:,end) = U2(:,1); U2(end,:) = U2(1,:);

end

% crop and concatenate
U = cat(3,U1(1:NumPix(1),1:NumPix(2)),U2(1:NumPix(1),1:NumPix(2)));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [F,BoundCond,NumPix] = parseInputs(varargin);

% get displacement field and check size
F = varargin{1};
NumPix = [size(F,1) size(F,2)];
if ~isequal([NumPix 2],size(F))
    error('npReg:poisson2DSolve:parseInputs:ForceFieldWrongSize',...
        'Force field must be MxNx2.');
end

% get boundary conditions
BoundCondValid = {'dirichlet','neumann','periodic'};
if length(varargin)<2
    BoundCond = '';
else
    BoundCond = lower(varargin{2});
end
if isempty(BoundCond)
    BoundCond = 'dirichlet';
end
ind = strmatch(BoundCond,BoundCondValid);
if isempty(ind)
    error('npReg:poisson2DSolve:parseInputs:BoundCondNotRecognized',...
        'Boundary condition not recognized.');
else
    BoundCond = BoundCondValid{ind};
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%