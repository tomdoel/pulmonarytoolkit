function info=hdr_read_header(filename)
% function for reading header of HDR/IMG Analyze ( .hdr ) volume file
%
% info = hdr_read_header(filename);
%
% examples:
% 1,  info=hdr_read_header()
% 2,  info=hdr_read_header('volume.hdr');

if(exist('filename','var')==0)
    [filename, pathname] = uigetfile('*.hdr', 'Read hdr-file');
    filename = [pathname filename];
end
if(exist('analyze75info','file')>0)
    info=analyze75info(filename);
else
    info=get_info_analyze_hdr(filename);
end

function info=get_info_analyze_hdr(filename)
% Strings for data type (compatible names with analyze75info)
strImgData{1}.ImgDataType = 'DT_UNKNOWN';
strImgData{1}.ColorType = 'unknown';
strImgData{2}.ImgDataType = 'DT_BINARY';
strImgData{2}.ColorType = 'grayscale';
strImgData{3}.ImgDataType = 'DT_UNSIGNED_CHAR';
strImgData{3}.ColorType = 'grayscale';
strImgData{5}.ImgDataType = 'DT_SIGNED_SHORT';
strImgData{5}.ColorType = 'grayscale';
strImgData{9}.ImgDataType = 'DT_SIGNED_INT';
strImgData{9}.ColorType = 'grayscale';
strImgData{17}.ImgDataType = 'DT_FLOAT';
strImgData{17}.ColorType = 'grayscale';
strImgData{33}.ImgDataType = 'DT_COMPLEX';
strImgData{33}.ColorType = 'grayscale';
strImgData{65}.ImgDataType = 'DT_DOUBLE';
strImgData{65}.ColorType = 'grayscale';
strImgData{129}.ImgDataType = 'DT_RGB';
strImgData{129}.ColorType = 'truecolor';
strImgData{256}.ImgDataType = 'DT_ALL';
strImgData{256}.ColorType = 'unknown';
strOriData{1} = 'Transverse unflipped';
strOriData{2} = 'Coronal unflipped';
strOriData{3} = 'Sagittal unflipped';
strOriData{4} = 'Transverse flipped';
strOriData{5} = 'Coronal flipped';
strOriData{6} = 'Sagittal flipped';
strOriData{7} = 'Orientation unavailable';
            
% Open the HDR-file, change MachineFormat if not the right
% header size
info.Filename=filename;
fid = fopen(filename,'rb','l'); fseek(fid,0,'bof');
info.ByteOrder='ieee-le';
info.HdrFileSize = fread(fid, 1,'int32');
if(info.HdrFileSize>2000);
    fclose(fid);
    fid = fopen(filename,'rb','b'); fseek(fid,0,'bof');
    info.ByteOrder='ieee-be';
    info.HdrFileSize = fread(fid, 1,'int32');
end

% Read the Whole Analyze Header
info.Format='Analyze';
info.HdrDataType = fread(fid,10,'char=>char')';
info.DatabaseName = fread(fid,18,'char=>char')';
info.Extents = fread(fid, 1,'int32');
info.SessionError = fread(fid, 1,'int16');
info.Regular = fread(fid, 1,'char=>char')';
unused= fread(fid, 1,'uint8')';
dim = fread(fid,8,'int16')';
if (dim(1) < 3), dim(1) = 4; end
info.Dimensions=dim(2:dim(1)+1);
info.Width=info.Dimensions(1);
info.Height=info.Dimensions(2);
info.VoxelUnits = fread(fid,4,'char=>char')';
info.CalibrationUnits = fread(fid,8,'char=>char')';
unused = fread(fid,1,'int16');
ImgDataType = fread(fid,1,'int16');
info.ImgDataType=strImgData{ImgDataType+1}.ImgDataType;
info.ColorType=strImgData{ImgDataType+1}.ColorType;
info.BitDepth = fread(fid,1,'int16');
unused = fread(fid,1,'int16');
PixelDimensions = fread(fid,8,'float')';
info.PixelDimensions=PixelDimensions(2:length(info.Dimensions)+1);
info.VoxelOffset = fread(fid,1,'float');
info.RoiScale = fread(fid,1,'float');
unused = fread(fid,1,'float');
unused = fread(fid,1,'float');
info.CalibrationMax = fread(fid,1,'float');
info.CalibrationMin = fread(fid,1,'float');
info.Compressed = fread(fid,1,'int32');
info.Verified = fread(fid,1,'int32');
info.GlobalMax = fread(fid,1,'int32');
info.GlobalMin = fread(fid,1,'int32');
info.Descriptor = fread(fid,80,'char=>char')';
info.AuxFile = fread(fid,24,'char=>char')';
Orientationt = fread(fid, 1,'uint8');
if((Orientationt>=48)&&(Orientationt<=53)), Orientationt = Orientationt -48; end
info.Orientationt=strOriData{min(Orientationt,5)+1};
info.Originator = fread(fid,10,'char=>char')';
info.Generated = fread(fid,10,'char=>char')';
info.Scannumber = fread(fid,10,'char=>char')';
info.PatientID = fread(fid,10,'char=>char')';
info.ExposureDate = fread(fid,10,'char=>char')';
info.ExposureTime = fread(fid,10,'char=>char')';
unused = fread(fid, 3,'char=>char')';
info.Views = fread(fid, 1,'int32');
info.VolumesAdded = fread(fid, 1,'int32');
info.StartField = fread(fid, 1,'int32');
info.FieldSkip = fread(fid, 1,'int32');
info.Omax = fread(fid, 1,'int32');
info.Omin = fread(fid, 1,'int32');
info.Smax = fread(fid, 1,'int32');
info.Smin = fread(fid, 1,'int32');
fclose(fid);

% Remove empty string parts from the info struct
names = fieldnames(info);
for i=1:length(names)
    value=info.(names{i});
    if(ischar(value))
        value(uint8(value)==0)=[];
        if(isempty(value)), info.(names{i})=''; else info.(names{i})=value; end
    end
end





