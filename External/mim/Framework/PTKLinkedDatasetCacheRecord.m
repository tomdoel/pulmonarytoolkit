classdef PTKLinkedDatasetCacheRecord < CoreBaseClass
    % Used by PTKLinkedDatasetRecorder to store
    % details of a particular set of links between datasets.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %

    properties
        LinkMap
    end
    
    methods
        function obj = PTKLinkedDatasetCacheRecord()
            obj.LinkMap = containers.Map();
        end
        
        function AddLink(obj, name, uid)
            obj.LinkMap(uid) = name;
        end
        
        function RemoveLink(obj, uid)
            if obj.LinkMap.isKey(uid)
                obj.LinkMap.remove(uid);
            end
        end
        
        function is_empty = IsEmpty(obj)
            is_empty = obj.LinkMap.Count == 0;
        end
    end
end