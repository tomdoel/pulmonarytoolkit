classdef MimSuggestEditException < MException
    % MimSuggestEditException. Error that can be overcome using a manual edit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the TD MIM Toolkit.
    %
    %     MimSuggestEditException is raised when an error occurs in certain
    %     Plugins. Normally a plugin failure would mean that no clients of
    %     the Plugin can be used. However, if a manual edit can be created
    %     to replace the plugin call, clients of the Plugin can continue.
    %     This exception is used to indicate to the caller (the GUI or the
    %     caller of the API) that it might be possible to create a manual
    %     edit for this purpose, and indicates the Plugin for which the
    %     manual edit should occur. While it is possible to create a manual
    %     edit for any Plugin, it is simpler from a user perspective to
    %     only allow creation of manual edits for certain meaningful Plugins
    %    
    %
    %     Licence
    %     -------
    %     Part of the TD MIM Toolkit. https://github.com/tomdoel
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the MIT licence. Please see website for details.
    %
    
    properties (SetAccess = private)
        PluginToEdit
        PluginContext
        PluginVisibleName
    end
    
    methods
        function obj = MimSuggestEditException(plugin_to_edit, context, exception, plugin_visible_name)
            obj = obj@MException(exception.identifier, exception.message);
            obj.addCause(exception);
            obj.PluginToEdit = plugin_to_edit;
            obj.PluginContext = context;
            obj.PluginVisibleName = plugin_visible_name;
        end
    end
end