classdef GemSeparator < GemPanel
    % GemSeparator GEM class for a separator line and label between panels
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties
        TitleLeftPadding = 5
        TitleHeight = 15
        SeparatorHeight = 20
        TitleWidth = 80
        TitleFontSize = 11
        Bold = true
    end
    
    properties (Access = protected)
        TitlePanel
    end
    
    methods
        function obj = GemSeparator(parent_handle, title_text)
            obj = obj@GemPanel(parent_handle);
            obj.TopBorder = true;
            obj.TitlePanel = GemText(obj, upper(title_text), title_text, title_text);
            obj.TitlePanel.FontSize = obj.TitleFontSize;
            obj.TitlePanel.Bold = obj.Bold;
            obj.AddChild(obj.TitlePanel);
        end
        
        function Resize(obj, position)
            Resize@GemPanel(obj, position);            
            title_panel_position = [1 + obj.TitleLeftPadding, 1, position(3) - obj.TitleLeftPadding, obj.TitleHeight];
            obj.TitlePanel.Resize(title_panel_position);            
        end
        
        function height = GetRequestedHeight(obj, width)
            height = obj.SeparatorHeight;
        end

    end    
end