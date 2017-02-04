classdef MimGuiPlugin < handle
    % MimGuiPlugin. Base class for a Gui-level plugin used by the Pulmonary Toolkit.
    %
    %     Gui Plugins are classes you create to run gui-related routines from
    %     the Pulmonary Toolkit user interface. Like plugins, gui plugins each
    %     have a button on the user interface. Unlike plugins, gui plugins do
    %     not generate results and cannot be called from outside of the gui.
    %     They are intended for operations related to the gui application such
    %     as importing and exporting of data, and visualising data such as 3D
    %     images and movies.
    %
    %     Gui Plugins must reside in the GuiPlugins folder, and
    %     inherit from this class, MimGuiPlugin. Provided that the properties have
    %     been correctly set, the plugin will automatically appear in the
    %     Pulmonary Toolkit gui.
    %
    %     Gui plugins are given a handle to the MimGuiApp object so they can
    %     access gui methods and obtain dataset results if necessary
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    properties (Abstract = true)

        % Interface version
        PTKVersion
        
        % Set to the panel name in the gui under which you wish the gui plugin
        % to appear. Examples include "File" or you can create your own.
        Category

        % Should normally be set to false.
        % If true, this plugin will not have a button in the gui window        
        HidePluginInDisplay
        
        % Controls when the button will be visible. Can be set to 'Always',
        % 'Dataset' (only when a dataset is loaded) or 'Overlay' (only when an
        % overlay image is present)
        Visibility
        
        % Should normally be set to 6.
        % The width (in units defined by the gui) of the button for this plugin        
        ButtonWidth
        
        % Should normally be set to 2.
        % The height (in units defined by the gui) of the button for this plugin
        ButtonHeight
        
        % The text to appear in the gui when the user hovers the mouse over the
        % button for this plugin
        ToolTip
        
        % The text to appear on the button in the gui when the button is not selected. Also used in reporting of
        % progress. Note that HTML tags are allowed - use <BR> for a newline in 
        % the button text
        ButtonText
        
        % The text that appears on the button when the tool is selected
        SelectedText
    end
    
    methods (Abstract, Static)

        % Called when the user has clicked the button for this gui plugin.
        % Implement this method with the code you with to run.
        RunGuiPlugin(mim_gui_app)
        
    end
    
    methods (Static)
        function enabled = IsEnabled(mim_gui_app)
            enabled = true;
        end
        
        function is_selected = IsSelected(mim_gui_app)
            is_selected = false;
        end
    end
end