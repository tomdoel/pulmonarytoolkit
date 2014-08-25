classdef PTKGuiPluginWrapper < PTKPluginWrapperBase
    % PTKGuiPluginWrapper. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    methods
        function obj = PTKGuiPluginWrapper(name, plugin_object, parsed_plugin_info, gui_app)
            obj = obj@PTKPluginWrapperBase(name, plugin_object, parsed_plugin_info, gui_app);
        end
        
        function RunPlugin(obj, plugin_name)
            obj.GuiApp.RunGuiPluginCallback(plugin_name)
        end
    end
end