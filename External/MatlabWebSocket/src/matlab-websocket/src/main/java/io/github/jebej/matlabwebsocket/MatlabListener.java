package io.github.jebej.matlabwebsocket;
// Interface that defines the callbacks in MATLAB.
// Inside MATLAB, they need to be referenced, for example as 'OpenCallback'
public interface MatlabListener extends java.util.EventListener {
    void Open( MatlabEvent event );
    void TextMessage( MatlabEvent event );
    void BinaryMessage( MatlabEvent event );
    void Error( MatlabEvent event );
    void Close( MatlabEvent event );
}
