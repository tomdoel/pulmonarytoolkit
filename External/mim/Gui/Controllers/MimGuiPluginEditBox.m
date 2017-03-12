classdef MimGuiPluginEditBox < MimGuiPlugin
    % MimGuiPluginEditBox. 
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    properties (Abstract = true)
        MinValue
        MaxValue
        DefaultValue        
        EditBoxPosition
        EditBoxWidth
    end
    
    methods (Static)
        function [value_instance_handle, value_property_name, limits_instance_handle, limits_property_name] = GetHandleAndProperty(mim_gui_app)
            value_instance_handle = @mim_gui_app.ImagePanel;
            value_property_name = [];
            limits_instance_handle = [];
            limits_property_name = [];
        end
    end        
end