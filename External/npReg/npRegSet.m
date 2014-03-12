function options = npRegSet(varargin)
%NPREGSET Create/alter npReg OPTIONS structure.
%   OPTIONS = npRegSet('PARAM1',VALUE1,'PARAM2',VALUE2,...) creates a
%   npable registration options structure OPTIONS in which the named 
%   parameters have the specified values.  Any unspecified parameters are 
%   set to [] (parameters with value [] indicate to use the default value 
%   for that parameter when OPTIONS is passed to the npable registration 
%   function). It is sufficient to type only the leading characters that 
%   uniquely identify the parameter.  Case is ignored for parameter names.
%   NOTE: For values that are strings, the complete string is required.
%
%   OPTIONS = NPREGSET(OLDOPTS,'PARAM1',VALUE1,...) creates a copy of 
%   OLDOPTS with the named parameters altered with the specified values.
%
%   OPTIONS = NPREGSET(OLDOPTS,NEWOPTS) combines an existing options 
%   structure OLDOPTS with a new options structure NEWOPTS.  Any parameters
%   in NEWOPTS with non-empty values overwrite the corresponding old 
%   parameters in OLDOPTS.
%
%   NPREGSET with no input arguments and no output arguments displays 
%   all parameter names and their possible values, with defaults shown in {}
%   when the default is the same for all functions that use that option -- use
%   npRegSet(NPREGFUNCTION) to see options for a specific function.).
%
%   OPTIONS = npRegSet (with no input arguments) creates an options 
%   structure OPTIONS where all the fields are set to [].
%
%   OPTIONS = npRegSet(NPREGFUNCTION) creates an options structure
%   with all the parameter names and default values relevant to the npable
%   registration function named in NPREGFUNCTION. For example,
%           npRegSet('npReg2D')
%   or
%           npRegSet(@npReg2D)
%   returns an options structure containing all the parameter names and
%   default values relevant to the function 'npReg'.
%
%npRegSet PARAMETERS for MATLAB
%Display - Level of display [ off | iter | notify | {final} ]
%SimilarityMeasure - Similarity measure between images 
%           [ {SSD} | NCC | CR | MI | NMI ]
%Regularizer - Choice of regularizer for deformation field
%           [ elastic | {fluid} | diffusion | curvature ]
%BoundaryCond - Boundary conditions for deformation field
%           [ {Dirichlet} | Periodic | Neumann ]
%VoxSizeX - Physical size of X-dimension of image voxel (X-axis is defined
%           to be down the columns of the image) [ positive scalar {1.0} ]
%VoxSizeY - Physical size of Y-dimension of image voxel (Y-axis is defined
%           to be across the rows of the image) [ positive scalar {1.0} ]
%VoxSizeZ - Physical size of Z-dimension of image voxel (Z-axis is defined
%           to be across the pages of the image) [ positive scalar {1.0} ]
%MaxIter - Maximum number of fixed point iterations allowed 
%           [ positive scalar {100} ]
%UDiffTol - Fixed point iteration termination tolerance on the maximum sum 
%       of squared differences between successive displacement field 
%       estimates [ positive scalar {1e-2} ]
%UDiffTol - Fixed point iteration termination tolerance on the maximum sum 
%       of squared differences between successive velocity field estimates
%           [ positive scalar {1e-2} ]
%BodyForceTol - Fixed point iteration termination tolerance on the body
%       force [ positive scalar {1e-2} ]
%SimMeasTol - Fixed point iteration termination tolerance on the similarity
%       measure [ positive scalar {1e-2} ]
%BodyForceDiffTol - Fixed point iteration termination tolerance on the
%       difference between successive body force estimates 
%           [ positive scalar {1e-2} ]
%SimMeasDiffTol - Fixed point iteration termination tolerance on the
%       difference between successive similarity measure estimates
%           [ positive scalar {1e-2} ]
%SimMeasPercentDiffTol - Fixed point iteration termination tolerance on
%       the percentage difference between successive similarity measure
%       estimates [ positive scalar {1e-2} ]
%FixedPointMaxFlowDistance - Maximum distance (in voxels) that the
%       deformation field is allowed to flow during each fixed point
%       iteration [ positive scalar {5.0} ]
%RegridTol - Tolerance on the Jacobian of the deformation field, below which
%       regridding will take place [ positive scalar {0.0025} ]
%Mu - Lame constant for use with elastic or fluid regularizers
%           [ positive scalar {1.0} ]
%Lambda - Lame constant for use with elastic or fluid regularizers
%           [ nonnegative scalar {0.0} ]
%ForceFactor - multiplicative factor applied to body force
%           [ positive scalar {1.0} ]
%RegularizerFactor - multiplicative factor applied to regularizer
%           [ positive scalar {1.0} ]
%StabilityConstant - Constant added to linear PDE system to enforce
%       stability [ nonpositive scalar {0.0} ]
%
%   Note: To see npRegSet parameters for the NPREG TOOLBOX
%         (if you have the npReg Toolbox installed), type
%             help npRegOptions
%
%   Examples
%     To create options with the default options for npReg2D
%       options = npRegSet('npReg');
%     To create an options structure with FixedPointTolDisplacement equal 
%     to 1e-3
%       options = npRegSet('FixedPointTolDisplacement',1e-3);
%     To change the Display value of options to 'iter'
%       options = npRegSet(options,'Display','iter');
%
%   See also NPREGGET, NPREG2D, NPREG3D, NPREG2D3D.
%
%
%
% author: Nathan D. Cahill
% affiliation: Rochester Institute of Technology
% date: January 2014
% licence: GNU GPL v3 licence.
%
% This code is copyright Nathan D. Cahill and has been distributed as part of the
% Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit





% Print out possible values of properties.
if (nargin == 0) && (nargout == 0)
    fprintf('                  Display: [ off | iter | notify | {final} ]\n');
    fprintf('        SimilarityMeasure: [ {SSD} | NCC | CR | MI | NMI ]\n');
    fprintf('              Regularizer: [ elastic | {fluid} | diffusion | curvature ]\n');
    fprintf('             BoundaryCond: [ {Dirichlet} | periodic | Neumann ]\n');
    fprintf('                 VoxSizeX: [ positive scalar ]\n');
    fprintf('                 VoxSizeY: [ positive scalar ]\n');
    fprintf('                 VoxSizeZ: [ positive scalar ]\n');
    fprintf('                  MaxIter: [ positive integer ]\n');
    fprintf('                 UDiffTol: [ positive scalar ]\n');
    fprintf('                 VDiffTol: [ positive scalar ]\n');
    fprintf('             BodyForceTol: [ positive scalar ]\n');
    fprintf('               SimMeasTol: [ positive scalar ]\n');
    fprintf('         BodyForceDiffTol: [ positive scalar ]\n');
    fprintf('           SimMeasDiffTol: [ positive scalar ]\n');
    fprintf('    SimMeasPercentDiffTol: [ positive scalar ]\n');
    fprintf('FixedPointMaxFlowDistance: [ positive scalar ]\n');
    fprintf('                RegridTol: [ positive scalar ]\n');
    fprintf('                       Mu: [ positive scalar ]\n');
    fprintf('                   Lambda: [ positive scalar ]\n');
    fprintf('              ForceFactor: [ positive scalar ]\n');
    fprintf('        RegularizerFactor: [ positive scalar ]\n');
    fprintf('        StabilityConstant: [ negative scalar ]\n');
    
    try
        npRegoptions;
    catch
        lasterrstruct = lasterror;
        if strcmp(lasterrstruct.identifier, 'MATLAB:UndefinedFunction')
            % Function NPREGOPTIONS not found, so we assume npReg Toolbox not on path
            %   and print the "MATLAB only" fields.
            % clean up last error
            lasterr('');
        else
            rethrow(lasterror);
        end
    end

    fprintf('\n');
    return;
end

% Create a struct of all the fields with all values set to 
allfields = {'Display';'SimilarityMeasure';'Regularizer';'BoundaryCond'; ...
    'VoxSizeX';'VoxSizeY';'VoxSizeZ';'MaxIter';'UDiffTol';'VDiffTol'; ...
    'BodyForceTol';'SimMeasTol';'BodyForceDiffTol';'SimMeasDiffTol'; ...
    'SimMeasPercentDiffTol';'FixedPointMaxFlowDistance';'RegridTol'; ...
    'Mu';'Lambda';'ForceFactor';'RegularizerFactor';'StabilityConstant'};
try 
    % assume we have the npReg Toolbox
    npRegtbx = true;
    npRegfields = npRegOptionGetFields;  
    allfields = [allfields; optimfields];
catch
    lasterrstruct = lasterror;
    if strcmp(lasterrstruct.identifier, 'MATLAB:UndefinedFunction')
        % Function NPREGOPTIONGETFIELDS not found, so we assume npReg Toolbox not on path
        %   and use the "MATLAB only" struct.
        npRegtbx = false;
        % clean up last error
        lasterr('');
    else
        rethrow(lasterror);
    end
end
% create cell array
structinput = cell(2,length(allfields));
% fields go in first row
structinput(1,:) = allfields';
% []'s go in second row
structinput(2,:) = {[]};
% turn it into correctly ordered comma separated list and call struct
options = struct(structinput{:});

numberargs = nargin; % we might change this value, so assign it
% If we pass in a function name then return the defaults.
if (numberargs==1) && (ischar(varargin{1}) || isa(varargin{1},'function_handle') )
    if ischar(varargin{1})
        funcname = lower(varargin{1});
        if ~exist(funcname)
            msg = sprintf(...
                'No default options available: the function ''%s'' does not exist on the path.',funcname);
            error('MATLAB:npRegSet:FcnNotFoundOnPath', msg)
        end
    elseif isa(varargin{1},'function_handle')
        funcname = func2str(varargin{1});
    end
    try 
        optionsfcn = feval(varargin{1},'defaults');
    catch
        msg = sprintf(...
            'No default options available for the function ''%s''.',funcname);
        error('MATLAB:npRegSet:NoDefaultsForFcn', msg)
    end
    % The defaults from the optim functions don't include all the fields
    % typically, so run the rest of npregset as if called with
    % npRegSet(options,optionsfcn)
    % to get all the fields.
    varargin{1} = options;
    varargin{2} = optionsfcn;
    numberargs = 2;
end

Names = allfields;
m = size(Names,1);
names = lower(Names);

i = 1;
while i <= numberargs
    arg = varargin{i};
    if ischar(arg)                         % arg is an option name
        break;
    end
    if ~isempty(arg)                      % [] is a valid options argument
        if ~isa(arg,'struct')
            error('MATLAB:npRegSet:NoParamNameOrStruct',...
                ['Expected argument %d to be a string parameter name ' ...
                'or an options structure\ncreated with npRegSet.'], i);
        end
        for j = 1:m
            if any(strcmp(fieldnames(arg),Names{j,:}))
                val = arg.(Names{j,:});
            else
                val = [];
            end
            if ~isempty(val)
                if ischar(val)
                    val = lower(deblank(val));
                end
                checkfield(Names{j,:},val,npRegtbx);
                options.(Names{j,:}) = val;
            end
        end
    end
    i = i + 1;
end

% A finite state machine to parse name-value pairs.
if rem(numberargs-i+1,2) ~= 0
    error('MATLAB:npRegSet:ArgNameValueMismatch',...
        'Arguments must occur in name-value pairs.');
end
expectval = 0;                          % start expecting a name, not a value
while i <= numberargs
    arg = varargin{i};

    if ~expectval
        if ~ischar(arg)
            error('MATLAB:npRegSet:InvalidParamName',...
                'Expected argument %d to be a string parameter name.', i);
        end

        lowArg = lower(arg);
        j = strmatch(lowArg,names);
        if isempty(j)                       % if no matches
            [wasinmatlab, optionname] = checknpRegonlylist(lowArg);
            if ~wasinmatlab
                error('MATLAB:npRegSet:InvalidParamName',...
                    'Unrecognized parameter name ''%s''.', arg);
            else
                warning('MATLAB:npRegSet:InvalidParamName',...
                    ['The option ''%s'' is a npReg Toolbox option and is not\n', ...
                     'used by any MATLAB functions. This option will be ignored and not included\n', ...
                     'in the options returned by npRegSet. Please change your code to not use \n', ...
                     'this option as it will error in a future release.'], ...
                     optionname);
                i = i + 2; % skip this parameter and its value; go to next parameter
                continue; % skip the rest of this loop
            end
        elseif length(j) > 1                % if more than one match
            % Check for any exact matches (in case any names are subsets of others)
            k = strmatch(lowArg,names,'exact');
            if length(k) == 1
                j = k;
            else
                msg = sprintf('Ambiguous parameter name ''%s'' ', arg);
                msg = [msg '(' Names{j(1),:}];
                for k = j(2:length(j))'
                    msg = [msg ', ' Names{k,:}];
                end
                msg = sprintf('%s).', msg);
                error('MATLAB:npRegSet:AmbiguousParamName', msg);
            end
        end
        expectval = 1;                      % we expect a value next

    else
        if ischar(arg)
            arg = lower(deblank(arg));
        end
        checkfield(Names{j,:},arg,npRegtbx);
        options.(Names{j,:}) = arg;
        expectval = 0;
    end
    i = i + 1;
end

if expectval
    error('MATLAB:npRegSet:NoValueForParam',...
        'Expected value for parameter ''%s''.', arg);
end

%-------------------------------------------------
function checkfield(field,value,npRegtbx)
%CHECKFIELD Check validity of structure field contents.
%   CHECKFIELD('field',V,NPREGTBX) checks the contents of the specified
%   value V to be valid for the field 'field'. NPREGTBX indicates if 
%   the npReg Toolbox is on the path.
%

% empty matrix is always valid
if isempty(value)
    return
end

% See if it is one of the valid MATLAB fields.  It may be both a npReg
% and MATLAB field, e.g. MaxFunEvals, in which case the MATLAB valid
% test may fail and the npReg one may pass.
validfield = true;
switch field
    case {'Display'} % off,none,iter,final,notify,testing
        [validvalue, errmsg, errid] = displayType(field,value);
    otherwise
        validfield = false;  
        validvalue = false;
        errmsg = sprintf('Unrecognized parameter name ''%s''.', field);
        errid = 'MATLAB:npRegSet:checkfield:InvalidParamName';
end

if validvalue 
    return;
elseif ~npRegtbx && validfield  
    % Throw the MATLAB invalid value error
    error(errid, errmsg);
else % Check if valid for npReg Tbx
    [optvalidvalue, opterrmsg, opterrid, optvalidfield] = npRegOptionCheckField(field,value);
    if optvalidvalue
        return;
    elseif optvalidfield
        % Throw the npReg invalid value error
        error(opterrid, opterrmsg)
    else % Neither field nor value is valid for npReg
        % Throw the MATLAB invalid value error (can't be invalid field for
        % MATLAB & npReg or would have errored already in npRegSet).
        error(errid, errmsg)
    end
end

%-----------------------------------------------------------------------------------------

function [valid, errmsg, errid] = nonNegReal(field,value,string)
% Any nonnegative real scalar or sometimes a special string
valid =  isreal(value) && isscalar(value) && (value >= 0) ;
if nargin > 2
    valid = valid || isequal(value,string);
end

if ~valid
    if ischar(value)
        errid = 'MATLAB:funfun:npRegset:NonNegReal:negativeNum';
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real non-negative scalar (not a string).',field);
    else
        errid = 'MATLAB:funfun:npRegset:NonNegReal:negativeNum';
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real non-negative scalar.',field);
    end
else
    errid = '';
    errmsg = '';
end

%-----------------------------------------------------------------------------------------

function [valid, errmsg, errid] = nonPosReal(field,value,string)
% Any nonpositive real scalar or sometimes a special string
valid =  isreal(value) && isscalar(value) && (value <= 0) ;
if nargin > 2
    valid = valid || isequal(value,string);
end

if ~valid
    if ischar(value)
        errid = 'MATLAB:funfun:npRegset:NonPosReal:positiveNum';
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real non-positive scalar (not a string).',field);
    else
        errid = 'MATLAB:funfun:npRegset:NonPosReal:positiveNum';
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real non-positive scalar.',field);
    end
else
    errid = '';
    errmsg = '';
end
%-----------------------------------------------------------------------------------------

function [valid, errmsg, errid] = nonNegInteger(field,value,string)
% Any nonnegative real integer scalar or sometimes a special string
valid =  isreal(value) && isscalar(value) && (value >= 0) && value == floor(value) ;
if nargin > 2
    valid = valid || isequal(value,string);
end
if ~valid
    if ischar(value)
        errid = 'MATLAB:funfun:npRegSet:nonNegInteger:notANonNegInteger';
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real non-negative integer (not a string).',field);
    else
        errid = 'MATLAB:funfun:npRegSet:nonNegInteger:notANonNegInteger';
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real non-negative integer.',field);
    end
else
    errid = '';
    errmsg = '';
end

%-----------------------------------------------------------------------------------------

function [valid, errmsg, errid] = displayType(field,value)
% One of these strings: on, off, none, iter, final, notify
valid =  ischar(value) && any(strcmp(value,{'on';'off';'none';'iter';'final';'notify';'testing'}));
if ~valid
    errid = 'MATLAB:funfun:npRegSet:displayType:notADisplayType';
    errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be ''off'',''on'',''iter'',''notify'', or ''final''.',field);
else
    errid = '';
    errmsg = '';
end

%-----------------------------------------------------------------------------------------

function [valid, errmsg, errid] = onOffType(field,value)
% One of these strings: on, off
valid =  ischar(value) && any(strcmp(value,{'on';'off'}));
if ~valid
    errid = 'MATLAB:funfun:npRegSet:onOffType:notOnOffType';
    errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be ''off'' or ''on''.',field);
else
    errid = '';
    errmsg = '';
end

%-----------------------------------------------------------------------------------------

function [valid, errmsg, errid] = functionType(field,value)
% Any function handle or string (we do not test if the string is a function name)
valid =  ischar(value) || isa(value, 'function_handle');
if ~valid
    errid = 'MATLAB:funfun:npRegSet:functionType:notAFunction';
    errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a function.',field);
else
    errid = '';
    errmsg = '';
end

%--------------------------------------------------------------------------------

function [wasinmatlab, optionname] = checknpRegonlylist(lowArg);
% Check if the user is trying to set an option that is only used by
% npReg Toolbox functions -- this used to have no effect.
% Now it will warn. In a future release, it will error.  
names =  {};
lowernames = lower(names);
k = strmatch(lowArg,lowernames);
wasinmatlab = ~isempty(k);
if wasinmatlab
    optionname = names{k};
else
    optionname = '';
end
