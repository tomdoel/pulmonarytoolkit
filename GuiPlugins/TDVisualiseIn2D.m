classdef TDVisualiseIn2D < TDGuiPlugin
    % TDVisualiseIn2D. Gui Plugin for showing the current 2D image slice in a
    % separate figure.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     TDVisualiseIn2D is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will create a new figure and display the current
    %     image slice.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties
        ButtonText = '2D'
        ToolTip = 'Opens a new window showing the current 2D background image'
        Category = 'View'

        HidePluginInDisplay = false
        TDPTKVersion = '1'
        ButtonWidth = 4
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            direction = ptk_gui_app.ImagePanel.Orientation;
            slice_number = ptk_gui_app.ImagePanel.SliceNumber(ptk_gui_app.ImagePanel.Orientation);
            image_slice = ptk_gui_app.ImagePanel.BackgroundImage.GetSlice(slice_number, direction);
            figure;
            if (direction == 1) || (direction == 2)
                image_slice = image_slice';
            end
            imagesc(image_slice);
            colormap gray;
            axis equal;
            axis off;
        end
    end
end