classdef PTKLabelButtonGroup < PTKVirtualPanel
    % PTKLabelButtonGroup. Part of the gui for the Pulmonary Toolkit.
    %
    %     PTKLabelButtonGroup is used to display a group of label buttons
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        Buttons
        Title
    end

    properties
        TitleTextHeight = 15
        VerticalSpacing = 3
        ButtonHorizontalSpacing = 0
        LeftMargin = 0
        RightMargin = 0
        LabelFontSize = 12
    end
    
    methods
        function obj = PTKLabelButtonGroup(parent, title, tooltip, tag, reporting)
            obj = obj@PTKVirtualPanel(parent, reporting);
            obj.Title = PTKText(parent, title, tooltip, tag);
            obj.Title.HorizontalAlignment = 'center';
            obj.Title.FontSize = obj.LabelFontSize;
            obj.Title.Bold = true;
            obj.AddChild(obj.Title, reporting);
        end
        
        function new_button = AddButton(obj, new_button, reporting)
            
            if isempty(obj.Buttons)
                obj.Buttons = new_button;
            else
                obj.Buttons(end + 1) = new_button;
            end
            obj.AddChild(new_button, reporting);
            obj.AddEventListener(new_button, 'ButtonClicked', @obj.ButtonClickedCallback);
        end
        
        function width = GetWidth(obj)
            width = obj.LeftMargin + obj.RightMargin;
            number_of_enabled_buttons = 0;
            for button = obj.Buttons
                if button.Enabled
                    width = width + button.GetWidth;
                    number_of_enabled_buttons = number_of_enabled_buttons + 1;
                end
            end
            width = width + max(0, number_of_enabled_buttons-1)*obj.ButtonHorizontalSpacing;
        end
            
        function Resize(obj, new_position)
            Resize@PTKVirtualPanel(obj, new_position);
            
            button_x = new_position(1) + obj.LeftMargin;
            total_width = obj.GetWidth;

            button_height = 0;
            
            for button = obj.Buttons
                if button.Enabled
                    y_start = new_position(2) + max(0, round((new_position(4) - obj.VerticalSpacing - obj.TitleTextHeight - button.GetRequestedHeight)/2));
                    button_width = button.GetWidth;
                    button.Resize([button_x, y_start, button_width, button.GetRequestedHeight]);
                    button_x = button_x + button_width + obj.ButtonHorizontalSpacing;
                    button_height = max(button_height, button.GetRequestedHeight);
                end
            end
            
            vertical_gap = max(0, new_position(4) - obj.VerticalSpacing - obj.TitleTextHeight - button_height);
            vertical_gap = round(vertical_gap/2);
            button_y = new_position(2) + vertical_gap;
            text_y = button_y + button_height + obj.VerticalSpacing;
            text_width = total_width;
            
            obj.Title.Resize([new_position(1), text_y, text_width, obj.TitleTextHeight]);
        end
        
        function Update(obj, gui_app)
            % Calls each label button and updates its status.
            
            for button = obj.Buttons
                enabled = button.UpdateToolEnabled(gui_app);
                if enabled ~= button.Enabled
                    if enabled
                        if isempty(button.Position)
                            button.Resize([0 0 1 1]);
                        end
                        button.Enable(obj.Reporting);
                    else
                        button.Disable;
                    end
                end
            end
        end
        
        
        function height = GetRequestedHeight(obj, width)
            height = 0;
            for button = obj.Buttons
                if button.Enabled
                    height = max(height, button.GetRequestedHeight);
                end
            end
            height = height + obj.TitleTextHeight + obj.VerticalSpacing;
        end
    end
    
    methods (Access = private)
        function ButtonClickedCallback(obj, src, event)
            for button = obj.Buttons
                if src ~= button
                    button.Select(false);
                end
            end
        end
    end
end