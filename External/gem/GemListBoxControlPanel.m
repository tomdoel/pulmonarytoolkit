classdef GemListBoxControlPanel < GemPanel
    % GemListBoxControlPanel. A title panel and controls used with a GemListbox
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %    
    
    properties
        TitleLeftPadding = 5
        ButtonFontSize = 12
        TitleFontSize = 11
        ButtonSize = 16
        ButtonSpacing = 4
        Bold = true
    end
    
    properties (Access = private)
        TitleText
        AddButton
        DeleteButton
    end
    
    events
        AddButtonEvent
        DeleteButtonEvent
    end
    
    methods
        function obj = GemListBoxControlPanel(parent, title_text, add_button_tooltip, delete_button_tooltip)
            obj = obj@GemPanel(parent);
            
            % Construct the title panel
            obj.TitleText = GemText(obj, title_text, '', 'ListTitle');
            obj.TitleText.FontSize = obj.TitleFontSize;
            obj.TitleText.Bold = obj.Bold;
            obj.AddChild(obj.TitleText);
            
            obj.AddButton = GemButton(obj, '+', add_button_tooltip, 'Add', @obj.AddButtonClicked);
            obj.AddButton.FontSize = obj.ButtonFontSize;
            obj.AddButton.BackgroundColour = obj.StyleSheet.BackgroundColour;
            obj.AddChild(obj.AddButton);
            
            obj.DeleteButton = GemButton(obj, '-', delete_button_tooltip, 'Delete', @obj.DeleteButtonClicked);
            obj.DeleteButton.BackgroundColour = obj.StyleSheet.BackgroundColour;
            obj.DeleteButton.FontSize = obj.ButtonFontSize;
            obj.AddChild(obj.DeleteButton);            
        end
        
        function Resize(obj, panel_position)
            Resize@GemPanel(obj, panel_position);
            
            panel_width = panel_position(3);
            panel_height = panel_position(4);
            
            text_width = panel_width; % Text is full width of control to ensure scrolling list box is blocked out
            text_position = [1 + obj.TitleLeftPadding, 0, text_width, panel_height];
            obj.TitleText.Resize(text_position);
            
            delete_button_position = [text_width - 2*obj.ButtonSize - obj.ButtonSpacing, obj.ButtonSpacing, obj.ButtonSize, obj.ButtonSize];
            add_button_position = [panel_width - obj.ButtonSize, obj.ButtonSpacing, obj.ButtonSize, obj.ButtonSize];
            
            obj.AddButton.Resize(add_button_position);
            obj.DeleteButton.Resize(delete_button_position);            
        end
        
    end
    
    methods (Access = private)        
        function AddButtonClicked(obj, tag)
            notify(obj, 'AddButtonEvent');
        end
        
        function DeleteButtonClicked(obj, tag)
            notify(obj, 'DeleteButtonEvent');
        end
    end
end