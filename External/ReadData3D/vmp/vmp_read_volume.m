function V = vmp_read_volume(info)
% function for readingV MP BrainVoyager ( .vmp ) volume file
% 
% volume = vmp_read_volume(file-header)
%
% examples:
% 1: info = vmp_read_volumegipl_read_header()
%    V = gvmp_read_volume(info);
%    imshow(squeeze(V(:,:,round(end/2))),[]);
%
% 2: V = vmp_read_volume('test.vmp');

if(~isstruct(info)), info=vmp_read_header(info); end

fp = fopen(info.Filename, 'rb', 'ieee-le');
if (fp == -1)
    error('The file was not found or could not be oppened')
end
% check version type
if fread(fp, 1, 'int16') ~= 3
    fclose(fp);
    error('Only version 3 files are supported')
end

% check number of maps
if fread(fp, 1, 'int32') ~= 1
    fclose(fp);
    error('Only vmp file with one map are supported')
end

% check number of maps
stat_type = fread(fp, 1, 'int32');
if stat_type ~= 1 & stat_type ~= 4
    fclose(fp);
    error('Only F and t tests are supported')
end


% skip a few fields
fseek(fp, 17, 'cof');

df1 = fread(fp, 1, 'int32');
df2 = fread(fp, 1, 'int32');

% skip a few fields
fseek(fp, 21, 'cof');
while true
    if fread(fp, 1, 'int8') == 0
        break
    end
end
fseek(fp, 12, 'cof');

% find the dimensions
x_start = fread(fp, 1, 'int32');
x_stop  = fread(fp, 1, 'int32');
DimX    = (x_stop - x_start) / 3;

y_start = fread(fp, 1, 'int32');
y_stop  = fread(fp, 1, 'int32');
DimY    = (y_stop - y_start) / 3;

z_start = fread(fp, 1, 'int32');
z_stop  = fread(fp, 1, 'int32');
DimZ    = (z_stop - z_start) / 3;

fseek(fp, 4, 'cof');

% read the data
len = (3*DimX+1) * (3*DimY+1) * (3*DimZ+1);
V = fread(fp, len, 'float');

fclose(fp);
