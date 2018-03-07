classdef WebSocketConnection < handle
    %WEBSOCKETCONNECTION WebSocketConnection represents a WebSocket
    %connection to a single client, from the point of view of the server.
    %Use it to send messages to that client.
    %
    %   A WebSocket connection object cannot be instantiated manually, it
    %   will be created for you either automatically in a callback method
    %   of a WebSocketServer, or manually if you call the getConnection
    %   method of a server.
    %   
    %   The WebSocketConnection object allows you to send a message to the
    %   client it represents, or to close the connection to that client.
    
    properties (SetAccess = private)
        HashCode % The HashCode identifying this client
        Status % Status of the connection, true if the connection is open
        Address % The IP address of the client
        Port % The port of the client
        WebSocketObj % Java-WebSocket connection object
    end
    
    methods (Access = ?WebSocketServer)
        function obj = WebSocketConnection(conn)
            % Instantiate a connection object from the java object, this
            % method can only be used by a WebSocketServer
            obj.WebSocketObj = handle(conn);
        end
    end
    
    methods
        function close(obj)
            % Close the connection to that client
            if ~obj.Status; error('Connection is already closed!'); end
            obj.WebSocketObj.close();
        end
        
        function delete(obj)
            % Delete the connection object, this does NOT close the
            % connection with the client
            delete(obj.WebSocketObj);
            obj.WebSocketObj = [];
        end
        
        function code = get.HashCode(obj)
            % Get the HashCode identifying this connection
            code = int32(obj.WebSocketObj.hashCode());
        end
        
        function status = get.Status(obj)
            % Get the status of the connection to this client
            status = obj.WebSocketObj.isOpen();
        end
        
        function ad = get.Address(obj)
            % Get the IP address of the client
            ad = char(obj.WebSocketObj.getRemoteSocketAddress.getHostName());
        end
        
        function ad = get.Port(obj)
            % Get the port of the client
            ad = int32(obj.WebSocketObj.getRemoteSocketAddress.getPort());
        end
        
        function send(obj,message)
            % Send a message to that WebSocket client.
            if ~obj.Status; error('Connection is closed!'); end
            if ~isa(message,'char') && ~isa(message,'int8');
                error('You can only send character arrays or int8 arrays!');
            end
            obj.WebSocketObj.send(message);
        end
    end
    
end

