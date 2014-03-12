function [validvalue, errmsg, errid, validfield] = npRegOptionCheckField(field,value)
%NPREGOPTIONCHECKFIELD Check validity of structure field contents.
%
% This is a helper function for NPREGSET and NPREGGET.

%   [VALIDVALUE, ERRMSG, ERRID, VALIDFIELD] = NPREGOPTIONCHECKFIELD('field',V)
%   checks the contents of the specified value V to be valid for the field 'field'.
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

% empty matrix is always valid
if isempty(value)
    validvalue = true;
    errmsg = '';
    errid = '';
    validfield = true;
    return
end

% Some fields are checked in npRegSet/checkfield: Display.
validfield = true;
switch field
    case {'VoxSizeX','VoxSizeY','VoxSizeZ','UDiffTol','VDiffTol', ...
            'BodyForceTol','SimMeasTol','BodyForceDiffTol', ...
            'SimMeasDiffTol','SimMeasPercentDiffTol', ...
            'FixedPointMaxFlowDistance','RegridTol','Mu','Lambda', ...
            'ForceFactor','RegularizerFactor'}
        % real scalar
        [validvalue, errmsg, errid] = nonNegReal(field,value);
    case {'StabilityConstant'}
        % real non-positive scalar
        [validvalue, errmsg, errid] = nonPosReal(field,value);
    case {'MaxIter'}
        [validvalue, errmsg, errid] = nonNegInteger(field,value,{'100000*numberofvariables'});
    case {'SimilarityMeasure'}
        % SSD, NCC, CR, MI, NMI
        [validvalue, errmsg, errid] = stringsType(field,value,{'ssd';'ncc';'cr';'mi';'nmi'});
    case {'Regularizer'}
        % elastic, fluid, diffusion, curvature
        [validvalue, errmsg, errid] = stringsType(field,value,{'elastic';'fluid';'diffusion';'curvature'});
    case {'BoundaryCond'}
        % dirichlet, neumann, periodic
        [validvalue, errmsg, errid] = stringsType(field,value,{'dirichlet';'periodic';'neumann'});
    otherwise
        validfield = false;
        validvalue = false;
        % No need to set an error. If the field isn't valid for MATLAB or npReg,
        % will have already errored in npRegSet. If field is valid for MATLAB,
        % then the error will be an invalid value for MATLAB.
        errid = '';
        errmsg = '';
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
        errid = 'npRegLib:npRegOptionCheckField:NonNegReal:negativeNum';
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real non-negative scalar (not a string).',field);
    else
        errid = 'npRegLib:npRegOptionCheckField:NonNegReal:negativeNum';
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
        errid = 'npRegLib:npRegOptionCheckField:NonPosReal:positiveNum';
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real non-positive scalar (not a string).',field);
    else
        errid = 'npRegLib:npRegOptionCheckField:NonPosReal:positiveNum';
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real non-positive scalar.',field);
    end
else
    errid = '';
    errmsg = '';
end

%-----------------------------------------------------------------------------------------

function [valid, errmsg, errid] = nonNegInteger(field,value,strings)
% Any nonnegative real integer scalar or sometimes a special string
valid =  isreal(value) && isscalar(value) && (value >= 0) && value == floor(value) ;
if nargin > 2
    valid = valid || any(strcmp(value,strings));
end
if ~valid
    if ischar(value)
        errid = 'npRegLib:npRegOptionCheckField:notANonNegInteger';
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real non-negative scalar (not a string).',field);
    else
        errid = 'npRegLib:npRegOptionCheckField:notANonNegInteger';
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a real non-negative scalar.',field);
    end
else
    errid = '';
    errmsg = '';
end

%-----------------------------------------------------------------------------------------

function [valid, errmsg, errid] = matrixType(field,value,strings)
% Any matrix
valid =  isa(value,'double');
if nargin > 2
    valid = valid || any(strcmp(value,strings));
end
if ~valid
    if ischar(value)
        errid = 'npRegLib:npRegOptionCheckField:notANonNegInteger';
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a matrix (not a string).',field);
    else
        errid = 'npRegLib:npRegOptionCheckField:posMatrixType:notAPosMatrix';
        errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a matrix.',field);
    end
else
    errid = '';
    errmsg = '';
end

%-----------------------------------------------------------------------------------------

function [valid, errmsg, errid] = posMatrixType(field,value)
% Any positive scalar or all positive vector
valid =  isa(value,'double') && all(value > 0) && isvector(value);
if ~valid
    errid = 'npRegLib:npRegOptionCheckField:posMatrixType:notAPosMatrix';
    errmsg = sprintf('Invalid value for OPTIONS parameter %s: \n must be a positive scalar or a vector with positive entries.',field);
else
    errid = '';
    errmsg = '';
end

%-----------------------------------------------------------------------------------------

function [valid, errmsg, errid] = functionType(field,value)
% Any function handle or string (we do not test if the string is a function name)
valid =  ischar(value) || isa(value, 'function_handle');
if ~valid
    errid = 'npRegLib:npRegOptionCheckField:functionType:notAFunction';
    errmsg = sprintf('Invalid value for OPTIONS parameter %s: must be a function handle.',field);
else
    errid = '';
    errmsg = '';
end
%-----------------------------------------------------------------------------------------
function [valid, errmsg, errid] = stringsType(field,value,strings)
% One of the strings in cell array strings
valid =  ischar(value) && any(strcmp(value,strings));

% To print out the error message beautifully, need to get the commas and "or"s
% in all the correct places while building up the string of possible string values.
if ~valid
    allstrings = ['''',strings{1},''''];
    for index = 2:(length(strings)-1)
        % add comma and a space after all but the last string
        allstrings = [allstrings, ', ''', strings{index},''''];
    end
    if length(strings) > 2
        allstrings = [allstrings,', or ''',strings{end},''''];
    elseif length(strings) == 2
        allstrings = [allstrings,' or ''',strings{end},''''];
    end
    errid = 'npRegLib:npRegOptionCheckField:stringsType:notAStringsType';
    errmsg = sprintf('Invalid value for OPTIONS parameter %s:\n must be %s.',field, allstrings);
else
    errid = '';
    errmsg = '';
end

%-----------------------------------------------------------------------------------------
function [valid, errmsg, errid] = boundedReal(field,value,bounds)
% Scalar in the bounds
valid =  isa(value,'double') && isscalar(value) && ...
    (value >= bounds(1)) && (value <= bounds(2));
if ~valid
    errid = 'npRegLib:npRegOptionCheckField:boundedReal:notAboundedReal';
    errmsg = sprintf('Invalid value for OPTIONS parameter %s: \n must be a scalar in the range [%6.3g, %6.3g].', ...
        field, bounds(1), bounds(2));
else
    errid = '';
    errmsg = '';
end


