function [BNEW,U,EXITFLAG,OUTPUT] = genNpReg2(A,B,options,defaultopt,regDim,varargin);
%GENNPREG2 solves general nonparametric image registration problems
%using a fixed point iteration
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

% check whether the combination of options is supported
[SimMeasFlag,RegularizerFlag,BoundCondFlag] = checkOptions(options,defaultopt);

% initialize similarity measure value and type of comparison
[SimMeas,simMeasComparison] = initializeSimilarityMeasure(SimMeasFlag);
SimMeasNew = SimMeas;

% get appropriate function handle for computing body force
computeBodyForce = getBodyForceFunction(SimMeasFlag);

% get appropriate function handle for solving core PDE based on regularizer
% and boundary conditions
solveCorePDE = getCorePDESolverFunction(RegularizerFlag,BoundCondFlag,regDim);

% get various fields from options structure
DisplayFlag = npRegGet(options,'Display',defaultopt,'fast');
VoxSize = [npRegGet(options,'VoxSizeX',defaultopt,'fast') ...
    npRegGet(options,'VoxSizeY',defaultopt,'fast') ...
    npRegGet(options,'VoxSizeZ',defaultopt,'fast')];
MaxIter = npRegGet(options,'MaxIter',defaultopt,'fast');
UDiffTol = npRegGet(options,'UDiffTol',defaultopt,'fast');
VDiffTol = npRegGet(options,'VDiffTol',defaultopt,'fast');
BodyForceTol = npRegGet(options,'BodyForceTol',defaultopt,'fast');
SimMeasTol = npRegGet(options,'SimMeasTol',defaultopt,'fast');
BodyForceDiffTol = npRegGet(options,'BodyForceDiffTol',defaultopt,'fast');
SimMeasDiffTol = npRegGet(options,'SimMeasDiffTol',defaultopt,'fast');
SimMeasPercentDiffTol = npRegGet(options,'SimMeasPercentDiffTol',defaultopt,'fast');
FixedPointMaxFlowDistance = npRegGet(options,'FixedPointMaxFlowDistance',defaultopt,'fast');
RegridTol = npRegGet(options,'RegridTol',defaultopt,'fast');
Mu = npRegGet(options,'Mu',defaultopt,'fast');
Lambda = npRegGet(options,'Lambda',defaultopt,'fast');
ForceFactor = npRegGet(options,'ForceFactor',defaultopt,'fast');
RegularizerFactor = npRegGet(options,'RegularizerFactor',defaultopt,'fast');
StabilityConstant = npRegGet(options,'StabilityConstant',defaultopt,'fast');

% get size of images
[NumRows,NumCols,NumPages] = size(A);

% initialize various variables
if regDim == 2 % 2-D case
    [U,V,BodyForce,BodyForceNew,DU,X,BGrad] = deal(zeros(NumRows,NumCols,2));
    DefGrad = zeros(NumRows,NumCols,2,2);
    DefJac = zeros(NumRows,NumCols);
else % 3-D case
    [U,V,BodyForce,BodyForceNew,DU,X,BGrad] = deal(zeros(NumRows,NumCols,NumPages,3));
    DefGrad = zeros(NumRows,NumCols,NumPages,3,3);
    DefJac = zeros(NumRows,NumCols,NumPages);
end
MaxDUNorm = inf;
MeanDUNorm = inf;
MedDUNorm = inf;

% initialize vectors of grid positions
if regDim == 2 % 2-D case
    [X(:,:,1),X(:,:,2)] = ndgrid((0:(NumRows-1))*VoxSize(1),...
        (0:(NumCols-1))*VoxSize(2));
else % 3-D case
    [X(:,:,:,1),X(:,:,:,2),X(:,:,:,3)] = ndgrid((0:(NumRows-1))*VoxSize(1),...
        (0:(NumCols-1))*VoxSize(2),(0:(NumPages-1))*VoxSize(3));
end

% compute gradient of floating image, as this will be needed repeatedly
% within incremental updating
[HX,HY,HZ] = constructGradientFilters(VoxSize);
if regDim == 2 % 2-D case
    %HX = imfilter(HX,fspecial('gaussian',7,2),'full');
    %HY = imfilter(HY,fspecial('gaussian',7,2),'full');
    BGrad(:,:,1) = imfilter(B,HX,'replicate','same');
    BGrad(:,:,2) = imfilter(B,HY,'replicate','same');
else % 3-D case
    BGrad(:,:,:,1) = imfilter(B,HX,'replicate','same');
    BGrad(:,:,:,2) = imfilter(B,HY,'replicate','same');
    BGrad(:,:,:,3) = imfilter(B,HZ,'replicate','same');
end

% follow general framework of Bro-Nielsen and Gramkow, but allowing for
% different body force and regularizers

if isequal(DisplayFlag,'iter')
    displayString = sprintf('Iteration\tSimilarity\tBodyForceMax\tDisplaceMax\tMean\tMedian');
    disp(displayString);
end
    
% fixed point iteration loop
i = 1;
while i <= MaxIter
    
    % compute body force
    [BodyForceNew(:),SimMeasNew(:)] = computeBodyForce(A,B,BGrad,U,X,NumRows,NumCols,NumPages,VoxSize,regDim,HX,HY,HZ);
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%%%% try to make robust
    %if SimMeasNew > SimMeas
    %    ForceFactor = ForceFactor./((1+sqrt(5))/2);
    %    disp('Force Factor reduced.');
    %end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    BodyForceNew(:) = BodyForceNew*ForceFactor;
    
    % solve PDE at current iteration
    %DU(:) = solveCorePDE(U,BodyForceNew,StabilityConstant,VoxSize,NumRows,NumCols,NumPages,Mu,Lambda,RegularizerFactor,DU,HX,HY,HZ);  % why not -U?
    DU(2:end-1,2:end-1,:) = RegularizerFactor.*imfilter(U(2:end-1,2:end-1,:),[0 1 0;1 -4 1;0 1 0],0) - BodyForceNew(2:end-1,2:end-1,:);
    %keyboard
    % compute time step based on maximum flow distance
    [TimeStep,MaxDUNorm(:),MeanDUNorm(:),MedDUNorm(:)] = ...
        computeTimeStep(DU,FixedPointMaxFlowDistance);
   
    % now add back to displacement field
    U(:) = U + TimeStep.*DU;
    
    % display information
    if isequal(DisplayFlag,'iter')
       displayString = sprintf('%5d\t\t%g\t\t%g\t\t%g\t\t%g\t\t%g',i,SimMeasNew,max(BodyForceNew(:)),MaxDUNorm,MeanDUNorm,MedDUNorm);
       disp(displayString);
    end
    
    % check tolerances for convergence
    [BreakCond,BreakMsg] = checkThresholds(BodyForce,BodyForceNew,SimMeas,...
        SimMeasNew,MaxDUNorm,UDiffTol,VDiffTol,BodyForceTol,SimMeasTol,...
        BodyForceDiffTol,SimMeasDiffTol,SimMeasPercentDiffTol,simMeasComparison);
    if BreakCond
        disp(BreakMsg);
        break;
    end
    
    % update similarity measure and body force
    SimMeas(:) = SimMeasNew;
    BodyForce(:) = BodyForceNew;
    
    % finally increment counter
    i = i+1;
    
end

% update image B to final deformation grid
if regDim == 2 % 2-D case
    BNEW = interp2(X(:,:,2),X(:,:,1),B,X(:,:,2)-U(:,:,2),...
        X(:,:,1)-U(:,:,1),'*linear',0);
else % 3-D case
    BNEW = interp3(X(:,:,:,2),X(:,:,:,1),X(:,:,:,3),B,...
        X(:,:,:,2)-U(:,:,:,2),X(:,:,:,1)-U(:,:,:,1),...
        X(:,:,:,3)-U(:,:,:,3),'*linear',0);
end    

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% need to add some code to return collection of deformation fields
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set EXITFLAG
if i==(MaxIter+1) % maximum number of iterations reached
    EXITFLAG = 0;
else % solution found in fewer than maximum number of iterations
    EXITFLAG = 1;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% need to add some code to catch errors thrown by any called function
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% set OUTPUT
OUTPUT.fixedPointIterations = i;
switch EXITFLAG
    case 1
        OUTPUT.message = 'NPREG2D converged to a solution.';
        if isequal(DisplayFlag,'iter') | isequal(DisplayFlag,'final')
            displayString = sprintf(OUTPUT.message);
            disp(displayString);
        end
    case 0
        OUTPUT.message = 'Maximum number of iterations reached.';
        if isequal(DisplayFlag,'iter') | isequal(DisplayFlag,'final')
            displayString = sprintf('%s%s',OUTPUT.message,' Terminating.');
            disp(displayString);
        end
    otherwise
        OUTPUT.message = 'If you see this message, you''re fucked.';
end

%-----------------------------------------------------------------------------------------
function [BreakCond,BreakMsg] = checkThresholds(BodyForce,BodyForceNew,SimMeas,SimMeasNew,MaxDUNorm,UDiffTol,VDiffTol,BodyForceTol,SimMeasTol,BodyForceDiffTol,SimMeasDiffTol,SimMeasPercentDiffTol,simMeasComparison);

% initialize break condition to zero
BreakCond = false;
BreakMsg = '';

% if body force is below a threshold for all points, then stop
MaxBodyForce = max(abs(BodyForceNew(:)));
if MaxBodyForce < BodyForceTol
    BreakMsg = 'Body force threshold met.';
    BreakCond = true;
end

% if body force difference is below a threshold for all points, then stop
MaxBodyForceDiff = max(abs(BodyForceNew(:)-BodyForce(:)));
if MaxBodyForceDiff < BodyForceDiffTol
    BreakMsg = 'Body force difference threshold met.';
    BreakCond = true;
end

% if similarity measure is beneath its threshold, then stop
if simMeasComparison(SimMeasNew,SimMeasTol)
    BreakMsg = 'Similarity Measure threshold met.';
    BreakCond = true;
end

% if similarity measure difference is beneath its threshold, then stop
SimMeasDiff = SimMeasNew - SimMeas;
if simMeasComparison(SimMeasNew,SimMeas)
    if abs(SimMeasDiff) < SimMeasDiffTol
        BreakMsg = 'Similarity measure difference threshold met.';
        BreakCond = true;
    end
end

% if similarity measure percentage decrease is beneath its threshold,
% then stop
if abs(SimMeas) < eps
    SimMeasPercentDiff = inf;
else
    SimMeasPercentDiff = SimMeasDiff./SimMeas;
end
if simMeasComparison(SimMeasNew,SimMeas)
    if abs(SimMeasPercentDiff) < SimMeasPercentDiffTol
        BreakMsg = 'Similarity measure percentage decrease threshold met.';
        BreakCond = true;
    end
end

% if maximum flow (velocity or displacement) is less than tolerance, then
% stop
if MaxDUNorm < UDiffTol
    BreakMsg = 'Maximum displacement threshold met.';
    BreakCond = true;
elseif MaxDUNorm < VDiffTol % this is wrong - needs to be changed
    BreakMsg = 'Maximum velocity threshold met.';
    BreakCond = true;
end

%-----------------------------------------------------------------------------------------
function [TimeStep,MaxDUNorm,MeanDUNorm,MedDUNorm] = computeTimeStep(DU,MaxFlow);

DUNorm = sqrt(sum(DU.^2,3));
MaxDUNorm = max(DUNorm(:));
MeanDUNorm = mean(DUNorm(:));
MedDUNorm = median(DUNorm(:));

if MaxDUNorm < MaxFlow
    TimeStep = 1;
else
    TimeStep = MaxFlow/MaxDUNorm;
end

%-----------------------------------------------------------------------------------------
function [HX,HY,HZ] = constructGradientFilters(VoxSize);

HX = [-1;0;1]/(2*VoxSize(1));
HY = [-1 0 1]/(2*VoxSize(2));
HZ = cat(3,-1,0,1)/(2*VoxSize(3));

%-----------------------------------------------------------------------------------------
function Y = getCorePDESolverFunction(Regularizer,BoundCond,regDim);

RegName = lower(Regularizer);
switch lower(BoundCond)
    case 'dirichlet'
        BoundCondName = 'Dirichlet';
    case 'periodic'
        BoundCondName = 'Periodic';
    case 'neumann'
        BoundCondName = 'Neumann';
end

Y = eval(['@',RegName,BoundCondName,int2str(regDim),'D']);

%-----------------------------------------------------------------------------------------
function Y = getBodyForceFunction(SimMeasFlag);

switch SimMeasFlag
    case 'SSD'
        Y = @bodyForceSSD;
    case 'NCC'
        Y = @bodyForceNCC;
    case 'CR'
        Y = @bodyForceCR;
    case 'MI'
        Y = @bodyForceMI;
    case 'NMI'
        Y = @bodyForceNMI;
end

%-----------------------------------------------------------------------------------------
function [S,comp] = initializeSimilarityMeasure(Flag);

switch Flag
    case 'SSD'
        S = inf;
        comp = @lt; % set comparison function to less than, as we are minimizing
    case {'NCC','CR','MI','NMI'}
        S = -inf;
        comp = @gt; % set comparison function to greater than, as we are maximizing
end

%-----------------------------------------------------------------------------------------
function [simMeasFlag,regularizerFlag,boundaryCondFlag] = checkOptions(options,defaultopt);

simMeasFlag = npRegGet(options,'SimilarityMeasure',defaultopt,'fast');
regularizerFlag = npRegGet(options,'Regularizer',defaultopt,'fast');
boundaryCondFlag = npRegGet(options,'BoundaryCond',defaultopt,'fast');

% test similarity measure support
if isequal(simMeasFlag,'NCC')
    errid = 'npRegLib:genNpReg:checkOptions:NCCNotSupported';
    errmsg = 'Normalized Cross Correlation not currently supported as similarity measure.';
elseif isequal(simMeasFlag,'CR')
    errid = 'npRegLib:genNpReg:checkOptions:CRNotSupported';
    errmsg = 'Correlation ratio not currently supported as similarity measure.';
elseif isequal(simMeasFlag,'MI')
    errid = 'npRegLib:genNpReg:checkOptions:MINotSupported';
    errmsg = 'Mutual information not currently supported as similarity measure.';
elseif isequal(simMeasFlag,'NMI')
    errid = 'npRegLib:genNpReg:checkOptions:NMINotSupported';
    errmsg = 'Normalized mututal information not currently supported as similarity measure.';
else
    errid = '';
    errmsg = '';
end

% report error
error(errid,errmsg);


