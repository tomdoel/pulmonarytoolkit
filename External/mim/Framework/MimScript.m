classdef MimScript < handle
    % Base class for an API script used by the Pulmonary Toolkit.
    %
    % MimScript are classes you create to run routines using the
    % Pulmonary Toolkit API. Whereas Plugins execute for a single
    % dataset and produce a deterministic result, Scripts can load and
    % operate over multiple datasets. Unike Gui Plugins, Scripts do not
    % access the user interface, so they can be run from the command
    % window using the API's RunScript method.    
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
        
    properties (Abstract = true)

        % This specifies the version of Script interface implemented by this script
        InterfaceVersion

        % A version number for this script implementation
        Version
        
        % Set to an apropriate value for grouping related scripts
        Category        
    end
    
    methods (Abstract, Static)

        % Called when the user has clicked the button for this gui plugin.
        % Implement this method with the code you with to run.
        output = RunScript(ptk_obj, parameters)
    end
end