classdef MimPluginWrapper < MimPluginWrapperBase
    % MimPluginWrapper. Part of the internal framework of the TD MIM Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    methods
        function obj = MimPluginWrapper(name, plugin_object, parsed_plugin_info, gui_app)
            obj = obj@MimPluginWrapperBase(name, plugin_object, parsed_plugin_info, gui_app);
        end

        function RunPlugin(obj, plugin_name)
            obj.GuiApp.RunPluginCallback(plugin_name)
        end
    end
end