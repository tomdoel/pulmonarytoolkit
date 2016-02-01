function output = gzipdecode(input)
%GZIPDECODE Decompress input bytes using GZIP.
%
%    output = gzipdecode(input)
%
% The function takes a compressed byte array INPUT and returns inflated
% bytes OUTPUT. The INPUT is a result of GZIPENCODE function. The OUTPUT
% is always an 1-by-N uint8 array. JAVA must be enabled to use the function.
%
% See also gzipencode typecast

error(nargchk(1, 1, nargin));
error(javachk('jvm'));
if ischar(input)
  warning('gzipdecode:inputTypeMismatch', ...
          'Input is char, but treated as uint8.');
  input = uint8(input);
end
if ~isa(input, 'int8') && ~isa(input, 'uint8')
    error('Input must be either int8 or uint8.');
end

gzip = java.util.zip.GZIPInputStream(java.io.ByteArrayInputStream(input));
buffer = java.io.ByteArrayOutputStream();
org.apache.commons.io.IOUtils.copy(gzip, buffer);
gzip.close();
output = typecast(buffer.toByteArray(), 'uint8')';

end
