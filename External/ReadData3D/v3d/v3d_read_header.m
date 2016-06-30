function [info] = v3d_read_header(filename)
% function for reading header of V3D Philips Scanner ( .v3d )
% volume file
%
% info = v3d_read_header(filename);
%
% examples:
% 1,  info=v3d_read_header()
% 2,  info=v3d_read_header('volume.v3d');

if(exist('filename','var')==0)
    [filename, pathname] = uigetfile('*.v3d', 'Read v3d-file');
    filename = [pathname filename];
end

fid=fopen(filename,'rb');
if(fid<0)
    fprintf('could not open file %s\n',filename);
    return
end

%get the file size
fseek(fid,0,'eof');
fsize = ftell(fid); 
fseek(fid,0,'bof');
fform=fread(fid, 5, 'uint8=>char')';
fseek(fid,7,'bof');
version=fread(fid, 3, 'uint8=>char')';
fseek(fid,40,'bof');
sizes=fread(fid,3,'int')';
scales=fread(fid,3,'double')';
fseek(fid,100,'bof');
bits=fread(fid,1,'int');
if (bits==0), bits=16; end
par1=fread(fid,1,'int');
par2=fread(fid,1,'int');
offset=fsize-prod(sizes)*(bits/8);
 
fclose('all');

info=struct('Filename',filename,'Format',fform,'Version',version,'Filesize',fsize,'Dimensions',sizes,'PixelDimensions',scales,'Voxelbits',bits,'Par1',par1,'Par2',par2,'Header',offset);
