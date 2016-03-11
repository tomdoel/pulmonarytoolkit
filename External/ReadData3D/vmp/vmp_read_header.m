function info = vmp_read_header(filename)
% function for reading header of VMP BrainVoyager ( .vmp )
% volume file
%
% info = vmp_read_header(filename);
%
% examples:
% 1,  info=vmp_read_header()
% 2,  info=vmp_read_header('volume.vmp');

if(exist('filename','var')==0)
    [filename, pathname] = uigetfile('*.vmp', 'Read vmp-file');
    filename = [pathname filename];
end

fid = fopen(filename, 'rb', 'ieee-le');

if (fid == -1)
    error('The file was not found or could not be oppened')
end

% check version type
if (fread(fid, 1, 'int16') ~= 3)
    fclose(fid);
    error('Only version 3 files are supported')
end

% check number of maps
if (fread(fid, 1, 'int32') ~= 1)
    fclose(fid);
    error('Only vmp file with one map are supported')
end

% check number of maps
stat_type = fread(fid, 1, 'int32');
if (stat_type ~= 1)&& (stat_type ~= 4)
    fclose(fid);
    error('Only F and t tests are supported')
end

% skip a few fields
fseek(fid, 17, 'cof');

info.Df1 = fread(fid, 1, 'int32');
info.Df2 = fread(fid, 1, 'int32');

% skip a few fields
fseek(fid, 21, 'cof');
while true
    if (fread(fid, 1, 'int8') == 0), break; end
end
fseek(fid, 12, 'cof');

% Store file name of volume
info.Filename=filename;

% find the dimensions
x_start = fread(fid, 1, 'int32');
x_stop  = fread(fid, 1, 'int32');
y_start = fread(fid, 1, 'int32');
y_stop  = fread(fid, 1, 'int32');
z_start = fread(fid, 1, 'int32');
z_stop  = fread(fid, 1, 'int32');
info.DimX    = (x_stop - x_start) / 3;
info.DimY    = (y_stop - y_start) / 3;
info.DimZ    = (z_stop - z_start) / 3;
info.Dimensions=[info.DimX info.DimY info.DimZ];
info.PixelDimensions=[0 0 0];
fseek(fid, 4, 'cof');
fclose(fid);
