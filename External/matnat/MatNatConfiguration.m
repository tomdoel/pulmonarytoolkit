classdef MatNatConfiguration < handle
    % MatNatConfiguration An object for providing details of the host, username, password etc for an XNAT server
    %
    %     Licence
    %     -------
    %     Part of MatNat. https://github.com/tomdoel/matnat
    %     Author: Tom Doel, 2015.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %        
    
    properties (Access = private)
        applicationDirectory
        serverName
        baseUrl
        userName
        password
    end
    
    methods
        function baseUrl = getBaseUrl(obj)
            baseUrl = obj.baseUrl;
        end
        
        function serverName = getServerName(obj)
            serverName = obj.serverName;
        end
        
        function userName = getUserName(obj)
            userName = obj.userName;
        end
        
        function password = getPassword(obj)
            password = obj.password;
        end
        
        function applicationDirectory = getApplicationDirectory(obj)
            applicationDirectory = obj.applicationDirectory;
        end
        
        function setBaseUrl(obj, baseUrl)
            obj.baseUrl = baseUrl;
        end
        
        function setServerName(obj, serverName)
            obj.serverName = serverName;
        end
        
        function setUserName(obj, userName)
            obj.userName = userName;
        end
        
        function setPassword(obj, password)
            obj.password = password;
        end
        
        function setApplicationDirectory(obj, applicationDirectory)
            obj.applicationDirectory = applicationDirectory;
        end        
    end
end

