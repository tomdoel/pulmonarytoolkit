classdef PTKLineAxes < PTKAxes
    % PTKLineAxes. Used to draw a line on a GUI
    %
    %     This class is a PTK graphical user interface component
    %
    %     PTKLineAxes is used to add a line to a GUI, by creating axes and attaching
    %     the line to the axes.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (Access = private)
        LineObject
    end
    
    methods
        function obj = PTKLineAxes(parent)
            obj = obj@PTKAxes(parent);
        end
        
        function CreateGuiComponent(obj, position, reporting)
            CreateGuiComponent@PTKAxes(obj, position, reporting);
            obj.LineObject = line('parent', obj.GraphicalComponentHandle, 'XData', [position(3), position(3)], 'YData', [1+position(2), 1+position(2) + position(4)], 'color', 'white');
        end

        function Resize(obj, position)
            Resize@PTKAxes(obj, position);
            obj.SetLimits([1, position(3)], [1, position(4)]);
            set(obj.LineObject, 'XData', [position(3), position(3)], 'YData', [position(2), position(2) + position(4)]);
        end
        
    end
end