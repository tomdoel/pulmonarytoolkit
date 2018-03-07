classdef WebSocketClient < handle
    %WEBSOCKETCLIENT WebSocketClient is an ABSTRACT class that allows
    %MATLAB to start a java-websocket client instance and connect to a
    %WebSocket server.
    %
    %   In order to make a valid implementation of the class, some methods
    %   must be defined in the superclass:
    %    onOpen(obj,message)
    %    onTextMessage(obj,message)
    %    onBinaryMessage(obj,bytearray)
    %    onError(obj,message)
    %    onClose((obj,message)
    %   The "callback" behavior of the client can be defined there. If
    %   the client needs to perform actions that are not responses to a
    %   server-caused event, these actions must be performed outside of the
    %   callback methods.
    
    properties (SetAccess = private)
        URI % The URI of the server
        Secure
        Status % Status of the connection, true if the connection is open
        ClientObj % Java-WebSocket client object
    end
    
    properties (Access = private)
        KeyStore % Location of the keystore
        StorePassword % Keystore password
        KeyPassword % Key password
    end
    
    methods
        function obj = WebSocketClient(URI,keyStore,storePassword,keyPassword)
            % Constructor, create a client to connect to the deisgnated
            % server, the URI must be of the form 'ws://localhost:30000'
            obj.URI = URI;
            if nargin>1
                obj.Secure = true;
                obj.KeyStore = keyStore;
                obj.StorePassword = storePassword;
                obj.KeyPassword = keyPassword;
            end
            % Connect the client to the server
            obj.open();
        end
        
        function status = get.Status(obj)
            % Get the status of the connection
            if isempty(obj.ClientObj)
                status = false;
            else
                status = obj.ClientObj.isOpen();
            end
        end
        
        function open(obj)
            % Open the connection to the server
            % Create the java client object in with specified URI
            if obj.Status; warning('Connection is already open!');return; end
            uri = handle(java.net.URI(obj.URI));
            if obj.Secure
                import io.github.jebej.matlabwebsocket.MatlabWebSocketSSLClient;
                obj.ClientObj = handle(MatlabWebSocketSSLClient(uri,obj.KeyStore,obj.StorePassword,obj.KeyPassword),'CallbackProperties');
            else
                import io.github.jebej.matlabwebsocket.MatlabWebSocketClient;
                obj.ClientObj = handle(MatlabWebSocketClient(uri),'CallbackProperties');
            end
            % Set callbacks
            set(obj.ClientObj,'OpenCallback',@(~,e)obj.openCallback(e));
            set(obj.ClientObj,'TextMessageCallback',@(~,e)obj.textMessageCallback(e));
            set(obj.ClientObj,'BinaryMessageCallback',@(~,e)obj.binaryMessageCallback(e));
            set(obj.ClientObj,'ErrorCallback',@(~,e)obj.errorCallback(e));
            set(obj.ClientObj,'CloseCallback',@(~,e)obj.closeCallback(e));
            % Connect to the websocket server
            obj.ClientObj.connectBlocking();
        end
        
        function close(obj)
            % Close the websocket connection and explicitely delete the
            % java client object
            if ~obj.Status; warning('Connection is already closed!');return; end
            obj.ClientObj.closeBlocking()
            delete(obj.ClientObj);
            obj.ClientObj = [];
        end
        
        function delete(obj)
            % Destructor
            % Closes the websocket if it's open.
            if obj.Status
                obj.close();
            end
        end
        
        function send(obj,message)
            % Send a message to the server
            if ~obj.Status; warning('Connection is closed!');return; end
            if ~isa(message,'char') && ~isa(message,'int8');
                error('You can only send character arrays or int8 arrays!');
            end
            obj.ClientObj.send(message);
        end
    end
    
    % Implement these methods in a subclass.
    methods (Abstract, Access = protected)
        onOpen(obj,message)
        onTextMessage(obj,message)
        onBinaryMessage(obj,bytearray)
        onError(obj,message)
        onClose(obj,message)
    end
    
    % Private methods triggered by the callbacks defined above.
    methods (Access = private)
        function openCallback(obj,e)
            % Define behavior in an onOpen method of a subclass
            obj.onOpen(char(e.message));
        end
        
        function textMessageCallback(obj,e)
            % Define behavior in an onTextMessage method of a subclass
            obj.onTextMessage(char(e.message));
        end
        
        function binaryMessageCallback(obj,e)
            % Define behavior in an onBinaryMessage method of a subclass
            obj.onBinaryMessage(e.blob.array);
        end
        
        function errorCallback(obj,e)
            % Define behavior in an onError method of a subclass
            obj.onError(char(e.message));
        end
        
        function closeCallback(obj,e)
            % Define behavior in an onClose method of a subclass
            obj.onClose(char(e.message));
            % Delete java client object if needed
            if ~isvalid(obj); return; end
            delete(obj.ClientObj);
            obj.ClientObj = [];
        end
    end
end