classdef PTKDependency < handle
    % PTKDependency. Part of the internal framework of the TD MIM Toolkit.
    %
    % PTKDependency sores a dependency object, uniquely tagging a particular 
    % result generated from running a plugin. This dependency is stored 
    % alongside the plugin result and stored in the
    % dependency list of every plugin which uses this result. This allows us
    % to determine that a result is still valid, because its dependencies
    % still match the dependency objects in the cache.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %
    
    properties
        PluginName
        Context
        Uid
        DatasetUid
        Attributes
    end
    
    methods
        function obj = PTKDependency(name, context, uid, dataset_uid, attributes)
            obj.PluginName = name;
            obj.Context = context;
            obj.Uid = uid;
            obj.DatasetUid = dataset_uid;
            obj.Attributes = attributes;
        end
    end
end