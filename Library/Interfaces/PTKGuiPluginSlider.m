classdef PTKGuiPluginSlider < PTKGuiPlugin
    % PTKGuiPluginSlider. Base class for a slider Gui-level plugin used by the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    properties (Abstract = true)
        MinValue
        MaxValue
        SmallStep
        LargeStep
        DefaultValue
    end
    
    methods (Static)
        function [instance_handle, property_name] = GetHandleAndProperty(ptk_gui_app)
            instance_handle = @ptk_gui_app.ImagePanel;
            property_name = 'OverlayOpacity';
        end
    end        
end