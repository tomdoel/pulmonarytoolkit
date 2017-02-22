classdef MimConnectionCacheMap < CoreBaseClass

    properties
        ConnectionCacheDictionary
    end
    
    methods
        function obj = MimConnectionCacheMap()
            obj.ConnectionCacheDictionary = containers.Map;
        end
        
        function addConnection(obj, connection)
            if ~obj.ConnectionCacheDictionary.isKey(connection.HashCode)
                obj.ConnectionCacheDictionary(connection.HashCode) = MimModelCache();
            end
        end
        
        function deleteConnection(obj, connection)
            if obj.ConnectionCacheDictionary.isKey(connection.HashCode)
                obj.ConnectionCacheDictionary.remove(connection.HashCode);
            end
        end
        
        function connectionCache = getConnection(obj, connection)
            if ~obj.ConnectionCacheDictionary.isKey(connection.HashCode)
                obj.ConnectionCacheDictionary(connection.HashCode) = MimConnectionCache();
            end
            connectionCache = obj.ConnectionCacheDictionary(connection.HashCode);
        end
    end
end