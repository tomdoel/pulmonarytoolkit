package io.github.jebej.matlabwebsocket;

import java.net.URI;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.Iterator;
import java.util.List;

import org.java_websocket.WebSocket;
import org.java_websocket.client.WebSocketClient;
import org.java_websocket.handshake.ServerHandshake;

public class MatlabWebSocketClient extends WebSocketClient {
    // This open a websocket connection as specified by RFC6455
    public MatlabWebSocketClient( URI serverURI ) {
        super( serverURI );
    }

    // This function gets executed when the connection is opened
    @Override
    public void onOpen( ServerHandshake handshakedata ) {
        String openMessage = "Connected to server at " + getURI();
        MatlabEvent matlab_event = new MatlabEvent( this, openMessage );
        Iterator<MatlabListener> listeners = _listeners.iterator();
        while (listeners.hasNext() ) {
            ( (MatlabListener) listeners.next() ).Open( matlab_event );
        }
    }

    // This function gets executed on text message receipt
    @Override
    public void onMessage( String message ) {
        MatlabEvent matlab_event = new MatlabEvent( this, message );
        Iterator<MatlabListener> listeners = _listeners.iterator();
        while (listeners.hasNext() ) {
            ( (MatlabListener) listeners.next() ).TextMessage( matlab_event );
        }
    }

    // Method handler when a byte message has been received from the client
    @Override
    public void onMessage( ByteBuffer blob ) {
        MatlabEvent matlab_event = new MatlabEvent( this, blob );
        Iterator<MatlabListener> listeners = _listeners.iterator();
        while (listeners.hasNext() ) {
            ( (MatlabListener) listeners.next() ).BinaryMessage( matlab_event );
        }
    }

    // This method gets executed on error
    @Override
    public void onError( Exception ex ) {
        MatlabEvent matlab_event = new MatlabEvent( this, ex.getMessage() );
        Iterator<MatlabListener> listeners = _listeners.iterator();
        while (listeners.hasNext() ) {
            ( (MatlabListener) listeners.next() ).Error( matlab_event );
        }
        // If the error is fatal, onClose will be called automatically
    }

    // This function gets executed when the websocket connection is closed,
    // close codes are documented in org.java_websocket.framing.CloseFrame
    @Override
    public void onClose( int code, String reason, boolean remote ) {
        String closeMessage = "Disconnected from server at " + getURI();
        MatlabEvent matlab_event = new MatlabEvent( this, closeMessage );
        Iterator<MatlabListener> listeners = _listeners.iterator();
        while (listeners.hasNext() ) {
            ( (MatlabListener) listeners.next() ).Close( matlab_event );
        }
    }

    // Methods for handling MATLAB as a listener, automatically managed.
    private List<MatlabListener> _listeners = new ArrayList<MatlabListener>();
    public synchronized void addMatlabListener( MatlabListener lis ) {
        _listeners.add( lis );
    }
    public synchronized void removeMatlabListener( MatlabListener lis ) {
        _listeners.remove( lis );
    }
}
