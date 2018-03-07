classdef MimGuiPluginEditBox < MimGuiPlugin
    % MimGuiPluginEditBox. 
    %
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
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