classdef GemImage < GemPositionlessUserInterfaceObject
    % GemImage. GEM class for displaying an image object
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = protected)
        XData
        YData
    end
    
    properties (Access = private)
        CData
        AlphaData
    end
    
    methods
        
        function obj = GemImage(parent)
            obj = obj@GemPositionlessUserInterfaceObject(parent);
        end
        
        function CreateGuiComponent(obj, position)
            obj.GraphicalComponentHandle = image([], 'Parent', obj.Parent.GetContainerHandle);
            
            if ~isempty(obj.XData)
                set(obj.GraphicalComponentHandle, 'XData', obj.XData, 'YData', obj.YData);
            end
            if ~isempty(obj.CData)
                alpha_slice = obj.AlphaData;
                if isempty(alpha_slice)
                    alpha_slice = 1;
                end
                set(obj.GraphicalComponentHandle, 'CData', obj.CData, 'AlphaData', alpha_slice, 'AlphaDataMapping', 'none');
            end
        end
        
        function SetRange(obj, x_range, y_range)
            obj.XData = x_range;
            obj.YData = y_range;
            if obj.ComponentHasBeenCreated && ishandle(obj.GraphicalComponentHandle)
                set(obj.GraphicalComponentHandle, 'XData', x_range, 'YData', y_range);
            end
        end
        
        function SetImageData(obj, rgb_slice, alpha_slice)
            obj.CData = rgb_slice;
            obj.AlphaData = alpha_slice;

            if isempty(alpha_slice)
                alpha_slice = 1;
            end
            
            if obj.ComponentHasBeenCreated && ishandle(obj.GraphicalComponentHandle)
                set(obj.GraphicalComponentHandle, 'CData', rgb_slice, 'AlphaData', alpha_slice, 'AlphaDataMapping', 'none');
            end
        end
        
        function ClearImageData(obj)
            obj.CData = [];
            obj.AlphaData = [];
            if obj.ComponentHasBeenCreated && ishandle(obj.GraphicalComponentHandle)
                % You can't set the AlphaData property to an empty matrix -
                % it must be set to 1 otherwise you get weird rendering
                % artefacts
                set(obj.GraphicalComponentHandle, 'CData', [], 'AlphaData', 1);
            end
        end    
    end
    
end