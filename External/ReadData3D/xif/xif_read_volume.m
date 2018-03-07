function V = xif_read_volume(info)
% function for reading volume of XIF HDllab/ATL ultrasound ( .xif )
% data file
%
% volume = xif_read_volume(file-header)
%
% examples:
% 1: info = xif_read_header()
%    V = xif_read_volume(info);
%    imshow(squeeze(V(:,:,round(end/2))),[]);
%
% 2: V = xif_read_volume('test.xif');

if(~isstruct(info)), info=xif_read_header(info); end

fid=fopen(info.Filename,'rb');
if(fid<0)
    fprintf('could not open file %s\n',info.Filename);
    return
end

%Run through the XML header, reading in scanlines, samples etc.
s = [];
while (size(strfind(s, '#SOH')) == 0); s = fgets(fid);  end
%Read throuh C-style header.
s = [];
while (size(strfind(s, '#EOH')) == 0); s = fgets(fid); end

%Now filepointer is at start of data. We simply read them in.
%Initializing X first, to allocate memory in a sane fashion.
V = uint8(zeros(uint16([info.Samples, info.Scanlines, info.Frames])));
for i = 1:info.Frames
    V(:,:,i) = fread(fid, [info.Samples, info.Scanlines], 'uchar');
end

fclose(fid);