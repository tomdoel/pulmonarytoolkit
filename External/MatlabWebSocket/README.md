MatlabWebSocket
===============

MatlabWebSocket is a simple library consisting of a websocket server and client for Matlab built on [Java-WebSocket](https://github.com/TooTallNate/Java-WebSocket), a java implementation of the websocket protocol by Nathan Rajlich. It currently does support encryption, but there appears to be a bug that make the server crash once a client disconnects. This bug might not exist on Linux/macOS.

The non-secure server and client work fine, although there is a bug on Windows which prevents servers from being restarted on the same port. The workaround is to restart MATLAB, or change port.

Installation
------------
The required java library is a jar file located in the `/jar/` folder. It must be placed on the static java class path in Matlab. See the [Matlab Documentation](http://www.mathworks.com/help/matlab/matlab_external/bringing-java-classes-and-methods-into-matlab-workspace.html).

You must also add the `/src/` folder to the Matlab path.

Usage
------------

The `WebSocketServer.m` file is an abstract Matlab class. The behaviour of the server must therefore be defined by creating a subclass that implements the following methods:

```matlab
        onOpen(obj,conn,message)
        onTextMessage(obj,conn,message)
        onBinaryMessage(obj,conn,message)
        onError(obj,conn,message)
        onClose(obj,conn,message)
```

`obj` is the object instance of the subclass, it is implicitly passed by MATLAB (see the object-oriented programming documentation of MATLAB).

`message` is the message received by the server.

`conn` is a WebSocketConnection object representing the client connection that cause the event. For example, if a message is received, the `conn` object will represent the client that sent this message.

The `WebSocketCLient.m` is very similar to the server, except that no `conn` object is passed to the `onSomething` methods.

The server supports a variety of methods to help talk to clients, look in the MATLAB class file to see what methods are available.

See the `EchoServer.m` and `SimpleClient.m` files in the `examples` folder for an implementation example.

Example
------
The example is an echo server, it returns to the client whatever was received.

Run the echo server by making sure that the file is on the MATLAB path and executing:
```matlab
server = EchoServer(30000)
```
to start the server on port 30000.

To test the server, make a client object from the `SimpleClient.m` class:
```matlab
client = SimpleClient('ws://localhost:30000')
```

You can now connect and send messages (`client.send('hi!')`). If the server is working properly, you will receive messages identical to the ones you send.

The server can enumerate clients that are connected, just type:
```matlab
server.Connections % you can also view the result as a table: struct2table(server.Connections)
```

This allows you to send a message to the client via its identifying HashCode:
```matlab
clientCode = server.Connections(1).HashCode
server.sendTo(clientCode,'hi, this is the server!')
```

To close the server, go back to Matlab and type:
```matlab
stop(server); % or server.stop()
clear server;
```

Acknowledgments
-------

This work was inspired by a websocket client matlab implementation [matlab-websockets](https://github.com/mingot/matlab-websockets).

It relies on the [Java-WebSocket](https://github.com/TooTallNate/Java-WebSocket) library.

License
-------

The code in this repository is licensed under the MIT license. See the `LICENSE` file for details.
