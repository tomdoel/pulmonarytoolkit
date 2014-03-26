classdef PTKOutputInfo
    % PTKOutputInfo. A structure for holding information related to output files
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    properties
        Filenames
        Description
        DateCreated
        PluginName
    end
    
    methods
        function obj = PTKOutputInfo(plugin_name, description, filenames, date)
            if nargin > 0
                obj.Filenames = filenames;
                obj.Description = description;
                obj.DateCreated = date;
                obj.PluginName = plugin_name;
            end
        end
    end
end

