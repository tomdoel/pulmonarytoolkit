Matlab encoding utilities
=========================

Matlab utilities to encode/decode a byte sequence. The package supports the
following features.

 * Base64 encode
 * ZLIB compression
 * GZIP compression
 * Image compression (image processing toolbox required)

The package internally uses JAVA functions. JAVA must be enabled in Matlab.

Usage
-----

### Base64 encode

Use `base64encode` and `base64decode` for encoding/decoding.

    >> x = 'foo bar';
    >> z = base64encode(x)

    z =

    Zm9vIGJhcg==

    >> x2 = char(base64decode(z))

    x2 =

    foo bar

### ZLIB compression

Use `zlibencode` and `zlibdecode`.

    >> x = zeros(1, 1000, 'uint8');
    >> z = zlibencode(x);
    >> whos
      Name      Size              Bytes  Class    Attributes

      x         1x1000             1000  uint8
      z         1x17                 17  uint8

    >> x == zlibdecode(z)

### GZIP compression

Use `gzipencode` and `gzipdecode`.

    >> x = zeros(1, 1000, 'uint8');
    >> z = gzipencode(x);
    >> whos
      Name      Size              Bytes  Class    Attributes

      x         1x1000             1000  uint8
      z         1x29                 29  uint8

    >> x == gzipdecode(z)

### Image compression

Use `imencode` and `imdecode`. Both functions take image format in the second
argument. See `imformats` for the list of available formats on the platform.

    >> im = imread('cat.jpg');
    >> z = imencode(im, 'jpg');
    >> whos
      Name        Size                Bytes  Class    Attributes

      im        500x375x3            562500  uint8
      z           1x24653             24653  uint8
    >> im2 = imdecode(z, 'jpg');

License
-------

The code may be redistributed under the BSD clause 3 license.
