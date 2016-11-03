classdef MimPluginButton < GemButton
    % MimPluginButton. Part of the gui for the Pulmonary Toolkit.
    %
    %     This class is used internally within the Pulmonary Toolkit to help
    %     build the user interface.
    %
    %     MimPluginButton is used to build a button control representing a plugin,
    %     with a backgroud image preview of the plugin result
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        RootButtonWidth = 20;
        RootButtonHeight = 20;
    end
    
    methods
        function obj = MimPluginButton(parent, callback, plugin_wrapper)
            plugin_info = plugin_wrapper.ParsedPluginInfo;
            tooltip_string = ['<HTML>' plugin_info.ToolTip];
            
            if (plugin_info.AlwaysRunPlugin)
                font_angle = 'italic';
                tooltip_string = [tooltip_string ' <BR><I>(this plugin has been set to Always Run)'];
            else
                font_angle = 'normal';
            end
            
            button_text = ['<HTML><P ALIGN = RIGHT>', plugin_info.ButtonText];
            tag = plugin_info.PluginName;
            
            obj = obj@GemButton(parent, button_text, tooltip_string, tag, callback);
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
            
            if isempty(obj.Position)
                button_size = [obj.ButtonWidth, obj.ButtonHeight];
            else
                button_size = obj.Position(3:4);
            end
            preview_image_raw = MimImageUtilities.GetButtonImage(preview_image, button_size(1), button_size(2), window, level, 1, obj.BackgroundColour, obj.UnSelectedColour);
            obj.ChangeImage(preview_image_raw);
        end
        
        function height = GetRequestedHeight(obj, width)
            % Returns a value for the height of the object
            
            height = obj.ButtonHeight;
        end
        
    end
end