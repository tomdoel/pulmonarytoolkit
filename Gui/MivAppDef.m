classdef MivAppDef < handle
    % MivAppDef. Defines application information
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        

    properties (Constant, Access = private)
        Name = 'MIV'
        Version = '0.1'
    end
    
    methods
        function [preferred_context, plugin_to_use] = GetPreferredContext(obj, modality)
            % Returns the context that should be automatically used for
            % this dataset, or [] to indicate use the oritinal image
            
            preferred_context = [];
            plugin_to_use = [];
        end
        
        function name = GetName(obj)
            name = MivAppDef.Name;
        end
        
        function name = GetVersion(obj)
            name = MivAppDef.Version;
        end
        
        function direction = GetDefaultOrientation(obj)
            direction = PTKImageOrientation.Axial;
        end
        
        function style_sheet = GetDefaultStyleSheet(obj)
            style_sheet = MivDefaultStyleSheet;
        end
        
        function logo = GetLogoFilename(obj)
            logo = 'MivLogo.jpg';
        end
        
        function plugins_path = GetPluginsPath(~)
            plugins_path = [];
        end
        
        function plugins_path = GetUserPluginsPath(~)
            plugins_path = [];
        end
    end
end
