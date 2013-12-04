classdef PTKCapture2DImage < PTKGuiPlugin
    % PTKCapture2DImage. Gui Plugin for exporting the image currently in the
    % visualisation window to a file
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKSaveImage is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will raise a Save dialog allowing the user to
    %     choose a filename and format, and then save the image currently in the
    %     visualisation panel.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = 'Capture Image'
        ToolTip = 'Save image and overlay view to files'
        Category = 'File'
        Visibility = 'Dataset'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            viewer_panel = ptk_gui_app.ImagePanel;
%             viewer_panel.Orientation = PTKImageOrientation.Coronal;
%             drawnow;
            
            % For capturing watershed countour around vessels on Patient 14 
%             viewer_panel.ZoomTo([300, 368], [131, 222], [150, 236]);
%             viewer_panel.ZoomTo([300, 370], [131+30, 222], [150, 220]);
            
%             viewer_panel.ZoomTo([250, 350], [125, 210], [150, 250]);
            drawnow;
            ptk_gui_app.Capture;
        end
    end
    
    methods (Static, Access = private)
    end
end