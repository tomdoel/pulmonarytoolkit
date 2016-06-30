function info = xif_read_header(filename)
% function for reading header of XIF HDllab/ATL ultrasound ( .xif )
% volume file
%
% info = xif_read_header(filename);
%
% examples:
% 1,  info=xif_read_header()
% 2,  info=xif_read_header('volume.xif');

if(exist('filename','var')==0)
    [filename, pathname] = uigetfile('*.xif', 'Read xif-file');
    filename = [pathname filename];
end

%Open file.
fid = fopen(filename, 'r');

%Abort if error opening file (does not exist, etc.)
if (fid == -1)
    error('Error opening file: %s, aborting...', filename);
end

% Store file name of volume
info.Filename=filename;

%Run through the XML header, reading in scanlines, samples etc.
s = [];
while (size(strfind(s, '#SOH')) == 0)
    s = fgets(fid);
    if (strfind(s, 'echoNumLines'))
       % <dataItem
       %   name="echoNumLines"
       %   type="INT"
       %   value="105"/>
        s = fgets(fid);
        s = fgets(fid);
        info.Scanlines = str2num(cell2mat(regexp(s, '(\d+)', 'match')));
    end
    if (strfind(s, 'echoNumDisplaySamples'))
        s = fgets(fid);
        s = fgets(fid);
        info.Samples = str2num(cell2mat(regexp(s, '(\d+)', 'match')));
    end
    if (strfind(s, 'numFrames'))
        s = fgets(fid);
        s = fgets(fid);
        info.Frames = str2num(cell2mat(regexp(s, '(\d+)', 'match')));
    end
    if (strfind(s, 'frameRate'))
        s = fgets(fid);
        s = fgets(fid);
        info.Framerate = str2num(cell2mat(regexp(s, '(\d+)', 'match')));
    end
    if (strfind(s, 'echoScan_linearWidth'))
        s = fgets(fid);
        s = fgets(fid);
        %Different regexp, as we need to match a decimal number.
        info.Width = str2num(cell2mat(regexp(s, '(\d+\.\d+)', 'match')));
    end
    if (strfind(s, 'echoDepth_twodDepth'))
        s = fgets(fid);
        s = fgets(fid);
        %Same as above.
        info.Height = str2num(cell2mat(regexp(s, '(\d+\.\d+)', 'match')));
    end
end
info.Dimensions=[info.Samples, info.Scanlines, info.Frames];
info.PixelDimensions=[0 0 0];
fclose(fid);