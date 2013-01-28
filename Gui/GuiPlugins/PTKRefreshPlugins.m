classdef PTKRefreshPlugins < PTKGuiPlugin
    % PTKRefreshPlugins. Gui Plugin for reloading plugins in the gui
    %
    %     You should not use this class within your own code. It is intended to
    %     be used by the gui of the Pulmonary Toolkit.
    %
    %     PTKRefreshPlugins is a Gui Plugin for the TD Pulmonary Toolkit.
    %     The gui will create a button for the user to run this plugin.
    %     Running this plugin will re-load all plugins and gui plugins from
    %     disk, adding any new plugins and deleting any which are no longer
    %     there.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
    
    properties
        ButtonText = 'Check for new plugins'
        ToolTip = 'Check for new plugins'
        Category = 'File'
        Visibility = 'Always'

        HidePluginInDisplay = false
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 1
    end
    
    methods (Static)
        function RunGuiPlugin(ptk_gui_app)
            ptk_gui_app.RefreshPlugins;
        end
    end
end