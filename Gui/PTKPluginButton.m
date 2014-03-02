classdef PTKPluginButton < PTKButton
    % PTKPluginButton. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     PTKPluginButton is used to build a button control representing a plugin,
    %     with a backgroud image preview of the plugin result
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        RootButtonWidth = 20;
        RootButtonHeight = 20;
    end
    
    methods
        function obj = PTKPluginButton(parent, callback, plugin_info)
            tooltip_string = ['<HTML>' plugin_info.ToolTip];
            
            if (plugin_info.AlwaysRunPlugin)
                font_angle = 'italic';
                tooltip_string = [tooltip_string ' <BR><I>(this plugin has been set to Always Run)'];
            else
                font_angle = 'normal';
            end
            
            button_text = ['<HTML><P ALIGN = RIGHT>', plugin_info.ButtonText];
            tag = plugin_info.PluginName;
            
            obj = obj@PTKButton(parent, button_text, tooltip_string, tag, callback);
            obj.FontAngle = font_angle;
            
            % Calculate the button size, based on plugin properties
            obj.ButtonWidth = plugin_info.ButtonWidth*obj.RootButtonWidth;
            obj.ButtonHeight = plugin_info.ButtonHeight*obj.RootButtonHeight;
        end
        
        function AddPreviewImage(obj, current_dataset, window, level)
            if ~isempty(current_dataset)
                preview_image = current_dataset.GetPluginPreview(obj.Tag);
            else
                preview_image = [];
            end
            obj.ChangeImage(preview_image, window, level);
        end
        
        function height = GetRequestedHeight(obj, width)
            % Returns a value for the height of the object
            
            height = obj.ButtonHeight;
        end
        
    end
end