classdef GemAxesPanel < GemPanel
    % GemAxesPanel GEM control for Matlab panel containing axes
    %
    %     GemAxesPanel inherits from GemPanel, and inclues a GemAxes object
    %
    %
    %     Licence
    %     -------
    %     Part of GEM. https://github.com/tomdoel/gem
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (Access = protected)
        Axes
    end
    
    properties (SetAccess = protected)
        VisualisationLabel
    end
    
    methods
        function obj = GemAxesPanel(parent)
            obj = obj@GemPanel(parent);
            
            obj.Axes = GemAxes(obj);
            obj.AddChild(obj.Axes);
            obj.BackgroundColour = 'white';
        end
        
        function CreateGuiComponent(obj, position)
            CreateGuiComponent@GemPanel(obj, position);
        end

        function Resize(obj, position)
            Resize@GemPanel(obj, position);
            obj.Axes.Resize(position);
        end
        
        function handle = GetRenderAxes(obj)
            % Returns a handle to the GEM Axes
            handle = obj.Axes;
        end

        function Clear(obj)
            % Clears the axes and resets the render panel
            obj.GetRenderAxes.Clear;
            obj.VisualisationLabel = [];
        end
        
        function SetVisualisationLabel(obj, label)
            obj.VisualisationLabel = label;
        end

        function frame = Capture(obj, image_size, orientation)
            drawnow;
            
            origin = [0.5, 0.5, 0.5];
            image_limit = origin + image_size;
            xlim_image = [min(origin), max(image_limit)];
            ylim_image = xlim_image;

            frame = obj.Axes.Capture(xlim_image, ylim_image);
        end        
    end
end