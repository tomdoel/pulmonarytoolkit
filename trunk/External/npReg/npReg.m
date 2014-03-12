function [BNEW,U,EXITFLAG,OUTPUT] = npReg(A,B,options,varargin)
%NPREG solves nonparametric image registration problems.
%
%   BNEW=NPREG(A,B) estimates a deformation field that is applied to
%   the floating image B in order to bring it into alignment with reference
%   image A.  The default registration algorithm is fluid registration,
%   wherein the deformation field is found by minimizing the sum of
%   squared difference (SSD) similarity measure, subject to a regularizer
%   based on the linearized elastic potential of the velocity field (known)
%   as the fluid regularizer).
%
%   BNEW=NPREG(A,B,OPTIONS) estimates the deformation field with the
%   default parameters replaced by values in the structure OPTIONS, an
%   argument created with the NPREGSET function.  See NPREGSET for
%   details.  Used options are Display, SimilarityMeasure, Regularizer, 
%   BoundaryCond, MaxIter, UDiffTol, VDiffTol, BodyForceTol, SimMeasTol, 
%   BodyForceDiffTol, SimMeasDiffTol, SimMeasPercentDiffTol, 
%   FixedPointMaxFlowDistance, RegridTol, and StabilityConstant.
%
%   [BNEW,U]=NPREG(A,B,...) returns the estimated deformation field U
%   that is applied to the floating image B in order to produce deformed
%   image BNEW.
%
%   [BNEW,U,EXITFLAG]=NPREG(A,B,...) returns an EXITFLAG that
%   describes the exit condition of NPREG. Possible values of 
%   EXITFLAG and the corresponding exit conditions are 
%
%     1  NPREG converged to a solution BNEW.
%     0  Maximum number of iterations reached.
%    -1  Error.
%
%   [BNEW,U,EXITFLAG,OUTPUT]=NPREG(A,B,...) returns a structure 
%   OUTPUT with the number of fixed point iterations taken in
%   OUTPUT.fixedPointIterations, and the exit message in OUTPUT.message.
%
% author: Nathan D. Cahill
% affiliation: Rochester Institute of Technology
% date: January 2014
% licence: GNU GPL v3 licence.
%
% This code is copyright Nathan D. Cahill and has been distributed as part of the
% Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit

% ------------Initialization----------------


defaultopt = struct('Display','final','SimilarityMeasure','SSD', ...
    'Regularizer','fluid','BoundaryCond','Dirichlet','VoxSizeX',1, ...
    'VoxSizeY',1,'VoxSizeZ',1,'MaxIter',100,'UDiffTol',1e-2, ...
    'VDiffTol',1e-2,'BodyForceTol',1e-2,'SimMeasTol',1e-2, ...
    'BodyForceDiffTol',1e-2,'SimMeasDiffTol',1e-2, ...
    'SimMeasPercentDiffTol',1e-2,'FixedPointMaxFlowDistance',5, ...
    'RegridTol',0.0025,'Mu',1,'Lambda',0,'ForceFactor',1, ...
    'RegularizerFactor',1,'StabilityConstant',0); 

% If just 'defaults' passed in, return the default options in X
if nargin==1 && nargout <= 1 && isequal(A,'defaults')
   BNEW = defaultopt;
   return
end
if nargin < 2
  error('npReg:npReg:NotEnoughInputs', ...
        'NPREG requires two input arguments.')
end
if nargin < 3, options=[]; end

% Determine class of images, then cast to double
Bclass = class(B);
if ~isequal(Bclass,class(A))
    error('npReg:npReg:ImagesNotSameClass', ...
        'NPREG requires both images to be of the same class.')
end
if ~isequal(Bclass,'double')
    A = double(A);
    B = double(B);
end

% Check that images are of the same size and are 2D or 3D
regDim = ndims(A);
if ~isequal(regDim,ndims(B))
    error('npReg:npReg:ImagesNotSameDimensions',...
        'NPREG requires both images to be of the same dimension.')
end
if ~isequal(regDim,2) & ~isequal(regDim,3)
    error('npReg:npReg:ImagesNot3D',...
        'NPREG requires both images to be 2-dimensional or 3-dimensional arrays.')
end
if ~isequal(size(A),size(B))
    error('npReg:npReg:ImagesNotSameSize',...
        'NPREG requires both images to be the same size.')
end

% scale to maximum image range
Imax = max(max(A(:)),max(B(:)));
Imin = min(min(A(:)),min(B(:)));
A(:) = (A-Imin)/(Imax-Imin);
B(:) = (B-Imin)/(Imax-Imin);

% Call general nonparametric registration routine
[BNEW,U,EXITFLAG,OUTPUT] = genNpReg(A,B,options,defaultopt,...
    regDim,varargin{:});
          
% Cast resulting image back to the same class as input images
% scale BNEW back to original range
BNEW(:) = BNEW*(Imax-Imin) + Imin;
if ~isequal(Bclass,'double')
    BNEW = feval(Bclass,BNEW);
end
