classdef WebSocketServer < handle
    %WEBSOCKETSERVER WebSocketServer is an ABSTRACT class that allows 
    %MATLAB to start a java-websocket server instance. It then becomes 
    %possible to send messages to any client that connect to it.
    %
    %   In order to make a valid implementation of the class, some methods
    %   must be defined in the superclass:
    %    onOpen(obj,conn,message)
    %    onTextMessage(obj,conn,message)
    %    onBinaryMessage(obj,conn,bytearray)
    %    onError(obj,conn,message)
    %    onClose((obj,conn,message)
    %   The "callback" behaviour of the server can be defined there. If
    %   the server needs to perform actions that are not responses to a
    %   client-caused event, these actions must be performed outside of
    %   these callback methods.
    
    properties (SetAccess = private)
        Port % Server port
        Secure % True if the server is a secure websocket server (wss)
        Status % Server status
        Connections % Stores active connections' hash and address as well as their java websocket object
        ServerObj % Java-WebSocket server object
    end
    
    properties (Access = private)
        KeyStore % Location of the keystore
        StorePassword % Keystore password
        KeyPassword % Key password
    end
    
    methods
        function obj = WebSocketServer(port,keyStore,storePassword,keyPassword)
            % Constructor
            obj.Port = port;
            if nargin>1
                obj.Secure = true;
                obj.KeyStore = keyStore;
                obj.StorePassword = storePassword;
                obj.KeyPassword = keyPassword;
            end
            % Start server
            obj.start();
        end
        
        function conns = get.Connections(obj)
            % Get current connections as a struct, listing HashCode, 
            % Address and Port, use the struct2table method on the returned
            % struct for a better display
            N = size(obj.ServerObj.connections);
            connsObj = obj.ServerObj.connections.toArray;
            codes = num2cell(int32(zeros(N,1)));
            adds = repmat(cellstr(''),N,1);
            ports = codes;
            for n = 1:N
                codes{n} = int32(connsObj(n).hashCode());
                adds{n} = char(connsObj(n).getRemoteSocketAddress.getHostName());
                ports{n} = int32(connsObj(n).getRemoteSocketAddress.getPort());
            end
            conns = struct('HashCode',codes,'Address',adds,'Port',ports);
        end
        
        function start(obj)
            % Start the WebSocket server
            if obj.Status; error('The server is already running'); end
            % Create the java server object in with specified port
            if obj.Secure
                import io.github.jebej.matlabwebsocket.*;
%                 import io.github.jebej.matlabwebsocket.MatlabWebSocketSSLServer;
                obj.ServerObj = handle(MatlabWebSocketSSLServer(obj.Port,obj.KeyStore,obj.StorePassword,obj.KeyPassword),'CallbackProperties');
            else
%                 import io.github.jebej.matlabwebsocket.MatlabWebSocketServer;
                import io.github.jebej.matlabwebsocket.*;
                obj.ServerObj = handle(MatlabWebSocketServer(obj.Port),'CallbackProperties');
            end
            % Set callbacks
            set(obj.ServerObj,'OpenCallback',@(~,e)obj.openCallback(e));
            set(obj.ServerObj,'TextMessageCallback',@(~,e)obj.textMessageCallback(e));
            set(obj.ServerObj,'BinaryMessageCallback',@(~,e)obj.binaryMessageCallback(e));
            set(obj.ServerObj,'ErrorCallback',@(~,e)obj.errorCallback(e));
            set(obj.ServerObj,'CloseCallback',@(~,e)obj.closeCallback(e));
            % Start the server
            obj.ServerObj.start();
            obj.Status = true;
        end
        
        function stop(obj,timeout)
            % Stop the server with a timeout to close connections
            if ~obj.Status; error('The server is not running!'); end
            if nargin<2; timeout=5000; end;
            obj.ServerObj.stop(int32(timeout));
            % Explicitely delete the server object
            delete(obj.ServerObj); obj.ServerObj=[];
            obj.Status = false;
        end
        
        function delete(obj)
            % Destructor
            if obj.Status
                % Stop the server if it is running
                obj.stop();
            end
        end
        
        function conn = getConnection(obj,hashCode)
            % Get a WebSocketConnection to the client identified by the
            % HashCode
            if ~obj.Status; error('The server is not running!'); end
            try
                conn = WebSocketConnection(obj.ServerObj.getConnection(hashCode));
            catch err
                error(char(err.ExceptionObject.getMessage));
            end
        end
        
        function sendTo(obj,hashCode,message)
            % Directly send a message to a particular client, as identified
            % by its HashCode
            if ~obj.Status; error('The server is not running!'); end
            if ~isa(message,'char') && ~isa(message,'int8');
                error('You can only send character arrays or int8 arrays!');
            end
            try
                obj.ServerObj.sendTo(hashCode,message);
            catch err
                error(char(err.ExceptionObject.getMessage));
            end
        end
        
        function sendToAll(obj,message)
            % Send a message to all connected clients
            if ~obj.Status; error('The server is not running!'); end
            if ~isa(message,'char') && ~isa(message,'int8');
                error('You can only send character arrays or int8 arrays!');
            end
            obj.ServerObj.sendToAll(message);
        end
        
        function close(obj,hashCode)
            % Directly close connection to a particular client, as 
            % identified by its HashCode
            if ~obj.Status; error('The server is not running!'); end
            try
                obj.ServerObj.close(hashCode);
            catch err
                error(char(err.ExceptionObject.getMessage));
            end
        end
        
        function closeAll(obj)
            % Close connection to all connected clients
            if ~obj.Status; error('The server is not running!'); end
            obj.ServerObj.closeAll();
        end
    end
    
    % Implement these methods in a subclass.
    methods (Abstract, Access = protected)
        onOpen(obj,conn,message)
        onTextMessage(obj,conn,message)
        onBinaryMessage(obj,conn,bytearray)
        onError(obj,conn,message)
        onClose(obj,conn,message)
    end
    
    % Private methods triggered by the callbacks defined above. This is
    % where the reactive behaviour of the server is defined.
    methods (Access = private)
        function openCallback(obj,e)
            % Define behavior in an onOpen method of a subclass
            obj.onOpen(WebSocketConnection(e.conn),char(e.message));
        end
        
        function textMessageCallback(obj,e)
            % Define behavior in an onTextMessage method of a subclass
            obj.onTextMessage(WebSocketConnection(e.conn),char(e.message));
        end
        
        function binaryMessageCallback(obj,e)
            % Define behavior in an onBinaryMessage method of a subclass
            obj.onBinaryMessage(WebSocketConnection(e.conn),e.blob.array);
        end
        
        function errorCallback(obj,e)
            % Define behavior in an onError method of a subclass
            obj.onError(WebSocketConnection(e.conn),char(e.message));
        end
        
        function closeCallback(obj,e)
            % Define behavior in an onClose method of a subclass
            obj.onClose(WebSocketConnection(e.conn),char(e.message));
        end
    end
end
