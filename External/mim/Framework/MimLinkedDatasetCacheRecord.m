classdef MimLinkedDatasetCacheRecord < CoreBaseClass
    % MimLinkedDatasetCacheRecord. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     MimLinkedDatasetCacheRecord is used by MimLinkedDatasetRecorder to store
    %     details of a particular set of links between datasets.
    %     
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2014.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    properties
        LinkMap
    end
    
    methods
        function obj = MimLinkedDatasetCacheRecord
            obj.LinkMap = containers.Map;
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