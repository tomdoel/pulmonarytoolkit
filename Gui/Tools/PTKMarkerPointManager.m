classdef PTKMarkerPointManager < CoreBaseClass
    % PTKMarkerPointManager. Part of the internal gui for the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the gui of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties (SetAccess = private)
    end
    
    properties (Access = private)
        MarkerLayer
        MarkerPointImage
        MarkerDisplayParameters
        ViewerPanel
        Gui
    end
    
    methods
        function obj = PTKMarkerPointManager(marker_layer, marker_image_source, marker_display_parameters, viewer_panel, gui)
            obj.MarkerLayer = marker_layer;
            obj.MarkerPointImage = marker_image_source;
            obj.MarkerDisplayParameters = marker_display_parameters;
            obj.ViewerPanel = viewer_panel;
            obj.Gui = gui;
        end
    end
end

