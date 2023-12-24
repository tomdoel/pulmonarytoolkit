classdef MimOutputInfo
    % A structure for holding information related to output files.
    % Typically created by MimClassFactory()
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %        
    
    properties
        Filenames
        Description
        DateCreated
        PluginName
    end
    
    methods
        function obj = MimOutputInfo(plugin_name, description, filenames, date)
            if nargin > 0
                obj.Filenames = filenames;
                obj.Description = description;
                obj.DateCreated = date;
                obj.PluginName = plugin_name;
            end
        end
    end
end
