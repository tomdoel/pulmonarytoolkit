package io.github.jebej.matlabwebsocket;

import java.io.File;
import java.io.FileInputStream;
import java.security.KeyStore;

import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.TrustManagerFactory;

import org.java_websocket.WebSocketImpl;
import org.java_websocket.server.DefaultSSLWebSocketServerFactory;

public class MatlabWebSocketSSLServer extends MatlabWebSocketServer {
    // The constructor creates a new SSL WebSocketServer with the wildcard IP,
    // accepting all connections on the specified port
    public MatlabWebSocketSSLServer( int port, String keystore, String storePassword, String keyPassword ) throws Exception {
        super( port );

        WebSocketImpl.DEBUG = true;

        // Load up the key store
        String STORETYPE = "JKS";
        String KEYSTORE = keystore;
        String STOREPASSWORD = storePassword;
        String KEYPASSWORD = keyPassword;

        KeyStore ks = KeyStore.getInstance( STORETYPE );
        File kf = new File( KEYSTORE );
        ks.load( new FileInputStream( kf ), STOREPASSWORD.toCharArray() );

        KeyManagerFactory kmf = KeyManagerFactory.getInstance( "SunX509" );
        kmf.init( ks, KEYPASSWORD.toCharArray() );
        TrustManagerFactory tmf = TrustManagerFactory.getInstance( "SunX509" );
        tmf.init( ks );

        SSLContext sslContext = null;
        sslContext = SSLContext.getInstance( "TLS" );
        sslContext.init( kmf.getKeyManagers(), tmf.getTrustManagers(), null );

        this.setWebSocketFactory( new DefaultSSLWebSocketServerFactory( sslContext ) );
    }
}
