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
        LeftMargin = 0
        RightMargin = 0
        LabelFontSize = 12
    end
    
    methods
        function obj = GemLabelButtonGroup(parent, title, tooltip, tag)
            obj = obj@GemVirtualPanel(parent);
        end
        
        function new_control = AddControl(obj, new_control)
            
            obj.Controls{end + 1} = new_control;
            obj.AddChild(new_control);
            
            if isa(new_control, 'GemButton')
                obj.AddEventListener(new_control, 'ButtonClicked', @obj.ButtonClickedCallback);
            elseif isa(new_control, 'GemSlider')
                obj.AddEventListener(new_control, 'SliderValueChanged', @obj.SliderCallback);
            end
        end
        
        function width = GetWidth(obj)
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
            
        function Resize(obj, new_position)
            Resize@GemVirtualPanel(obj, new_position);
            
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
        
        function Update(obj, gui_app)
            % Calls each label button and updates its status.
            
            for control = obj.Controls
                enabled = control{1}.UpdateToolEnabled(gui_app);
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
        end
        
        
        function height = GetRequestedHeight(obj, width)
            height = 0;
            for control = obj.Controls
                if control{1}.Enabled
                    height = max(height, control{1}.GetRequestedHeight);
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