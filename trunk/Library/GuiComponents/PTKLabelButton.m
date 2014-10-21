classdef PTKLabelButton < PTKVirtualPanel
    % PTKLabelButton. Part of the gui for the Pulmonary Toolkit.
    %
    %     PTKLabelButton is used to display a button image with label text below
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = protected)
        Button
        Text
    end

    properties
        ButtonWidth = 50
        ButtonHeight = 50
        TextHeight = 25
        VerticalSpacing = 2
        ButtonHorizontalSpacing = 0
        LabelFontSize = 9
    end
    
    events
        ButtonClicked
    end
    
    methods
        function obj = PTKLabelButton(parent, text, tooltip, tag, icon, reporting)
            obj = obj@PTKVirtualPanel(parent, reporting);
            obj.Button = PTKButton(parent, text, tooltip, tag, @obj.ButtonClickedCallback);
            obj.Button.ButtonWidth = obj.ButtonWidth;
            obj.Button.ButtonHeight = obj.ButtonHeight;
            obj.Button.UnSelectedColour = [50, 50, 50];
            obj.Button.ShowTextOnButton = false;
            obj.Button.AddAndResizeImageWithHighlightMask(icon, [0, 0, 0]);
            obj.Button.AutoUpdateStatus = true;
            
            obj.Button.UnSelectedColour = uint8(255*(PTKSoftwareInfo.BackgroundColour));
            obj.Button.SelectedColour = uint8(255*(PTKSoftwareInfo.IconSelectedColour));
            obj.Button.HighlightColour = uint8(255*(PTKSoftwareInfo.IconHighlightColour));
            obj.Button.HighlightSelectedColour = uint8(255*(PTKSoftwareInfo.IconHighlightSelectedColour));            

            obj.AddChild(obj.Button, reporting);
            obj.Text = PTKText(parent, text, tooltip, tag);
            obj.Text.HorizontalAlignment = 'center';
            obj.Text.FontSize = obj.LabelFontSize;
            obj.AddChild(obj.Text, reporting);
        end
       
        function Resize(obj, new_position)
            Resize@PTKVirtualPanel(obj, new_position);
            
            button_x_pos = new_position(1) + obj.ButtonHorizontalSpacing;
            button_width = obj.Button.ButtonWidth;
            text_width = button_width + 2*obj.ButtonHorizontalSpacing;
            button_y_pos = new_position(2) + obj.TextHeight + obj.VerticalSpacing;
            button_height = obj.Button.ButtonHeight;
            obj.Button.Resize([button_x_pos, button_y_pos, button_width, button_height]);
            obj.Text.Resize([new_position(1), new_position(2), text_width, obj.TextHeight]);
        end
        
        function width = GetWidth(obj)
            width = obj.Button.ButtonWidth + 2*obj.ButtonHorizontalSpacing;
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.Button.ButtonHeight + obj.TextHeight + obj.VerticalSpacing;
        end

        function Enable(obj, reporting)
            Enable@PTKVirtualPanel(obj, reporting);
            obj.Button.Enable(reporting);
            obj.Text.Enable(reporting);
        end
        
        function Disable(obj)
            Disable@PTKVirtualPanel(obj);
            obj.Button.Disable;
            obj.Text.Disable;
        end
        
        function Select(obj, is_selected)
            obj.Button.Select(is_selected);
        end
    end
    
    methods (Access = protected)
        function ButtonClickedCallback(obj, tag)
            notify(obj, 'ButtonClicked', PTKEventData(tag));
        end
    end
end