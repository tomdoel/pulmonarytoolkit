package io.github.jebej.matlabwebsocket;

import java.nio.ByteBuffer;
import java.util.Set;
import org.java_websocket.WebSocket;

// Object given to MATLAB when an event occur. The "this.something" assignments
// define which arguments are passed to MATLAB.
public class MatlabEvent extends java.util.EventObject {
    private static final long serialVersionUID = -4346315089398115565L;
    public WebSocket conn;
    public String message;
    public ByteBuffer blob;
    // Constructor for text message client event
    public MatlabEvent( Object obj, String message ) {
        super( obj );
        this.message = message;
    }
    // Constructor for binary message client event
    public MatlabEvent( Object obj, ByteBuffer blob ) {
        super( obj );
        this.blob = blob;
    }
    // Constructor for text message server event
    public MatlabEvent( Object obj, WebSocket conn, String message ) {
        super( obj );
        this.conn = conn;
        this.message = message;
    }
    // Constructor for binary message server event
    public MatlabEvent( Object obj, WebSocket conn, ByteBuffer blob ) {
        super( obj );
        this.conn = conn;
        this.blob = blob;
    }
}
