classdef TDDependency < handle
    % TDDependency. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     TDDependency sores a dependency object, uniquely tagging a particular 
    %     result generated from running a plugin. This dependency is stored 
    %     alongside the plugin result and stored in the
    %     dependency list of every plugin which uses this result. This allows us
    %     to determine that a result is still valid, because its dependencies
    %     still match the dependency objects in the cache.
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    properties
        PluginName
        Uid
        DatasetUid
    end
    
    methods
        function obj = TDDependency(name, uid, dataset_uid)
            obj.PluginName = name;
            obj.Uid = uid;
            obj.DatasetUid = dataset_uid;
        end
    end
end