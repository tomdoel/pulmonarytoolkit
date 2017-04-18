classdef GemLabelButton < GemVirtualPanel
    % GemLabelButton GEM class for a button image with label text below
    %
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = protected)
        Button
        Text
    end

    properties
        DefaultButtonWidth = 50
        DefaultButtonHeight = 50
        TextHeight = 25
        VerticalSpacing = 2
        ButtonHorizontalSpacing = 0
        LabelFontSize = 9
    end
    
    properties (Dependent)
        ButtonWidth
        ButtonHeight
    end
    
    events
        ButtonClicked
    end
    
    methods
        function obj = GemLabelButton(parent, text, tooltip, tag, icon)
            obj = obj@GemVirtualPanel(parent);
            obj.Button = GemButton(parent, text, tooltip, tag, @obj.ButtonClickedCallback);
            obj.Button.ButtonWidth = obj.DefaultButtonWidth;
            obj.Button.ButtonHeight = obj.DefaultButtonHeight;
            obj.Button.UnSelectedColour = [50, 50, 50];
            obj.Button.ShowTextOnButton = false;
            obj.Button.AddAndResizeImageWithHighlightMask(icon, [0, 0, 0]);
            obj.Button.AutoUpdateStatus = true;
            
            obj.Button.UnSelectedColour = uint8(255*(obj.StyleSheet.BackgroundColour));
            obj.Button.SelectedColour = uint8(255*(obj.StyleSheet.IconSelectedColour));
            obj.Button.HighlightColour = uint8(255*(obj.StyleSheet.IconHighlightColour));
            obj.Button.HighlightSelectedColour = uint8(255*(obj.StyleSheet.IconHighlightSelectedColour));            

            obj.AddChild(obj.Button);
            obj.Text = GemText(parent, text, tooltip, tag);
            obj.Text.HorizontalAlignment = 'center';
            obj.Text.FontSize = obj.LabelFontSize;
            obj.AddChild(obj.Text);
        end

        function Resize(obj, new_position)
            Resize@GemVirtualPanel(obj, new_position);
            
            button_x_pos = new_position(1) + obj.ButtonHorizontalSpacing;
            button_width = obj.Button.ButtonWidth;
            text_width = button_width + 2*obj.ButtonHorizontalSpacing;
            button_y_pos = new_position(2) + obj.TextHeight + obj.VerticalSpacing;
            button_height = obj.Button.ButtonHeight;
            obj.Button.Resize([button_x_pos, button_y_pos, button_width, button_height]);
            obj.Text.Resize([new_position(1), new_position(2), text_width, obj.TextHeight]);
        end
       
        function set.ButtonWidth(obj, width)
            obj.Button.ButtonWidth = width;
        end
        
        function width = get.ButtonWidth(obj)
            width = obj.Button.ButtonWidth;
        end

        function set.ButtonHeight(obj, height)
            obj.Button.ButtonHeight = height;
        end
        
        function height = get.ButtonHeight(obj)
            height = obj.Button.ButtonHeight;
        end

        function width = GetWidth(obj)
            width = obj.Button.ButtonWidth + 2*obj.ButtonHorizontalSpacing;
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.Button.ButtonHeight + obj.TextHeight + obj.VerticalSpacing;
        end

        function Enable(obj)
            Enable@GemVirtualPanel(obj);
            obj.Button.Enable;
            obj.Text.Enable;
        end
        
        function Disable(obj)
            Disable@GemVirtualPanel(obj);
            obj.Button.Disable;
            obj.Text.Disable;
        end
        
        function Select(obj, is_selected)
            obj.Button.Select(is_selected);
        end
    end
    
    methods (Access = protected)
        function ButtonClickedCallback(obj, tag)
            notify(obj, 'ButtonClicked', CoreEventData(tag));
        end
    end
end