function o = npRegGet(options,name,default,flag)
%NPREGGET Get NPREG OPTIONS parameters.
%   VAL = NPREGGET(OPTIONS,'NAME') extracts the value of the named 
%   parameter from npReg options structure OPTIONS, returning an empty
%   matrix if the parameter value is not specified in OPTIONS.  It is 
%   sufficient to type only the leading characters that uniquely identify 
%   the parameter.  Case is ignored for parameter names.  [] is a valid 
%   OPTIONS argument.
%
%   VAL = NPREGGET(OPTIONS,'NAME',DEFAULT) extracts the named parameter
%   as above, but returns DEFAULT if the named parameter is not specified 
%   (is []) in OPTIONS.  For example
%
%     val = npRegGet(opts,'UDiffTol',1e-4);
%
%   returns val = 1e-4 if the UDiffTol property is not specified in opts.
%
%   See also NPREGSET.
%
% author: Nathan D. Cahill
% affiliation: Rochester Institute of Technology
% date: January 2014
% licence: GNU GPL v3 licence.
%
% This code is copyright Nathan D. Cahill and has been distributed as part of the
% Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit

% undocumented usage for fast access with no error checking
if (nargin == 4) && isequal(flag,'fast')
    o = npRegGetFast(options,name,default);
    return
end

if nargin < 2
    error('MATLAB:npRegGet:NotEnoughInputs', 'Not enough input arguments.');
end
if nargin < 3
    default = [];
end

if ~isempty(options) && ~isa(options,'struct')
    error('MATLAB:npRegGet:Arg1NotStruct',...
        'First argument must be an options structure created with NPREGSET.');
end

if isempty(options)
    o = default;
    return;
end

allfields = {'Display'};
try
    npRegFields = npRegOptionGetFields;  
    allfields = [allfields; npRegFields];
catch
    lasterrstruct = lasterror;
    if strcmp(lasterrstruct.identifier, 'MATLAB:UndefinedFunction')
        % Function NPREGOPTIONGETFIELDS not found, so we assume npReg Toolbox not on path
        %   and use the "MATLAB only" struct.
        % clean up last error
        lasterr('');
    else
        rethrow(lasterror);
    end
end

Names = allfields;

name = deblank(name(:)'); % force this to be a row vector
j = find(strncmpi(name,Names,length(name)));
if isempty(j)               % if no matches
    error('MATLAB:npRegGet:InvalidPropName',...
        ['Unrecognized property name ''%s''.  ' ...
        'See NPREGSET for possibilities.'], name);
elseif length(j) > 1            % if more than one match
    % Check for any exact matches (in case any names are subsets of others)
    k = find(strcmpi(name,Names));
    if length(k) == 1
        j = k;
    else
        msg = sprintf('Ambiguous property name ''%s'' ', name);
        msg = [msg '(' Names{j(1),:}];
        for k = j(2:length(j))'
            msg = [msg ', ' Names{k,:}];
        end
        msg = sprintf('%s).', msg);
        error('MATLAB:npRegGet:AmbiguousPropName', msg);
    end
end

if any(strcmp(Names,Names{j,:}))
    o = options.(Names{j,:});
    if isempty(o)
        o = default;
    end
else
    o = default;
end

%------------------------------------------------------------------
function value = npRegGetFast(options,name,defaultopt)
%NPREGGETFAST Get NPREG OPTIONS parameter with no error checking.
%   VAL = NPREGGETFAST(OPTIONS,FIELDNAME,DEFAULTOPTIONS) will get the
%   value of the FIELDNAME from OPTIONS with no error checking or
%   fieldname completion. If the value is [], it gets the value of the
%   FIELDNAME from DEFAULTOPTIONS, another OPTIONS structure which is
%   probably a subset of the options in OPTIONS.
%

if isempty(options)
     value = defaultopt.(name);
     return;
end
% We need to know if name is a valid field of options, but it is faster to use 
% a try-catch than to test if the field exists and if the field name is
% correct. If the options structure is from an older version of the
% toolbox, it could be missing a newer field.
try
    value = options.(name);
catch
    value = [];
    lasterr('');  % clean up last error
end

if isempty(value)
    value = defaultopt.(name);
end


