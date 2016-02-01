classdef GemLabelButtonGroup < GemVirtualPanel
    % GemLabelButtonGroup GEM class for a group of label buttons
    %
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = private)
        Controls
        Title
    end

    properties
        ButtonHorizontalSpacing = 0
        ButtonVerticalSpacing = 0
        LeftMargin = 0
        RightMargin = 0
        LabelFontSize = 12
        VerticalMode = false
    end
    
    methods
        function obj = GemLabelButtonGroup(parent, title, tooltip, tag)
            obj = obj@GemVirtualPanel(parent);
        end
        
        function new_control = AddControl(obj, new_control)
            
            obj.Controls{end + 1} = new_control;
            obj.AddChild(new_control);
            
            if isa(new_control, 'GemButton') || isa(new_control, 'GemLabelButton')
                obj.AddEventListener(new_control, 'ButtonClicked', @obj.ButtonClickedCallback);
            elseif isa(new_control, 'GemSlider') || isa(new_control, 'GemLabelSlider')
                obj.AddEventListener(new_control, 'SliderValueChanged', @obj.SliderCallback);
                if new_control.StackVertically
                    obj.VerticalMode = true;
                end
            end
        end
        
        function width = GetWidth(obj)
            if obj.VerticalMode
                width = 0;
                for button = obj.Controls
                    if button{1}.Enabled
                        width = max(width, button{1}.GetWidth);
                    end
                end
                width = width + obj.LeftMargin + obj.RightMargin;
            else
                width = obj.LeftMargin + obj.RightMargin;
                number_of_enabled_buttons = 0;
                for button = obj.Controls
                    if button{1}.Enabled
                        width = width + button{1}.GetWidth;
                        number_of_enabled_buttons = number_of_enabled_buttons + 1;
                    end
                end
                width = width + max(0, number_of_enabled_buttons-1)*obj.ButtonHorizontalSpacing;
            end
        end
            
        function Resize(obj, new_position)
            Resize@GemVirtualPanel(obj, new_position);
            
            if obj.VerticalMode
                control_x = new_position(1) + obj.LeftMargin;
                total_height = obj.GetRequestedHeight;
                y_margin = max(0, round((new_position(4) - total_height)/2));
                y_top = new_position(2) + new_position(4) - y_margin;
                
                for control = obj.Controls
                    if control{1}.Enabled
                        control_height = control{1}.GetRequestedHeight;
                        y_start = y_top - control_height;
                        button_width = control{1}.GetWidth;
                        control{1}.Resize([control_x, y_start, button_width, control{1}.GetRequestedHeight]);
                        y_top = y_top - control_height - obj.ButtonVerticalSpacing;
                    end
                end
            else
                control_x = new_position(1) + obj.LeftMargin;
                
                control_height = 0;
                
                for control = obj.Controls
                    if control{1}.Enabled
                        y_start = new_position(2) + max(0, round((new_position(4) - control{1}.GetRequestedHeight)/2));
                        button_width = control{1}.GetWidth;
                        control{1}.Resize([control_x, y_start, button_width, control{1}.GetRequestedHeight]);
                        control_x = control_x + button_width + obj.ButtonHorizontalSpacing;
                        control_height = max(control_height, control{1}.GetRequestedHeight);
                    end
                end
            end
        end
        
        function Update(obj, gui_app)
            % Calls each label button and updates its status.
            any_enabled = false;
            for control = obj.Controls
                enabled = control{1}.UpdateToolEnabled(gui_app);
                any_enabled = any_enabled || enabled;
                if enabled ~= control{1}.Enabled
                    if enabled
                        if isempty(control{1}.Position)
                            control{1}.Resize([0 0 1 1]);
                        end
                        control{1}.Enable;
                    else
                        control{1}.Disable;
                    end
                end
            end
            if any_enabled
                obj.Enable;
            else
                obj.Disable;
            end
        end
        
        
        function height = GetRequestedHeight(obj, width)
            if obj.VerticalMode
                height = 0;
                number_of_enabled_buttons = 0;
                for control = obj.Controls
                    if control{1}.Enabled
                        height = height + control{1}.GetRequestedHeight;
                        number_of_enabled_buttons = number_of_enabled_buttons + 1;
                    end
                end
                height = height + max(0, number_of_enabled_buttons-1)*obj.ButtonVerticalSpacing;            
            else
                height = 0;
                for control = obj.Controls
                    if control{1}.Enabled
                        height = max(height, control{1}.GetRequestedHeight);
                    end
                end
            end
        end
    end
    
    methods (Access = private)
        function ButtonClickedCallback(obj, src, event)
            for control = obj.Controls
                if src ~= control{1}
                    control{1}.Select(false);
                end
            end
        end
        
        function SliderCallback(obj, hObject, ~)
        end        
    end
end