function info =par_read_header(filename)
% Function for reading the header of a Philips Par / Rec  MR V4.* file 
%
% info  = par_read_header(filename);
%
% examples:
% 1,  info=par_read_header()
% 2,  info=par_read_header('volume.par');

if(exist('filename','var')==0)
    [filename, pathname] = uigetfile('*.par', 'Read par-file');
    filename = [pathname filename];
end

fid=fopen(filename,'rb');
if(fid<0)
    fprintf('could not open file %s\n',filename);
    return
end
info.Filename=filename;


mode = -1; nHC=0; nIC=0; nSC=0;
while(true)
    str=fgetl(fid);
    if ~ischar(str), break, end
    if(isempty(str)), continue, end
    
    if(strfind(str,'= DATA DESCRIPTION FILE =')), mode=0; end
    if(strfind(str,'= GENERAL INFORMATION =')), mode=1; end
    if(strfind(str,'= PIXEL VALUES =')), mode=2; end
    if(strfind(str,'= IMAGE INFORMATION DEFINITION =')), 
        mode=3; fgetl(fid);  str=fgetl(fid); 
        % Skip a line
    end
    if(strfind(str,'= IMAGE INFORMATION =')), mode=4; end
    
    if(strfind(str,'= END OF DATA DESCRIPTION FILE =')), mode=5; end
    
    switch(mode)
        case -1;
        case 0
            nHC=nHC+1; HeaderComment{nHC}=str;
        case 1
            if(str(1)=='.')
                [type data]=General_Information_Line(str);
                switch(type)
                    case 'PatientName'
                        info.(type)=data;
                    case 'ProtocolName'
                        info.(type)=data;
                    case 'ExaminationName'
                        info.(type)=data;
                    case 'ExaminationDateTime'
                        info.(type)=data;
                    case 'SeriesType'
                        info.(type)=data;
                    case 'AcquisitionNr'
                        info.(type)=sscanf(data, '%d')';
                    case 'ReconstructionNr'
                        info.(type)=sscanf(data, '%d')';
                    case 'ScanDuration'
                        info.(type)=sscanf(data, '%lf')';
                    case 'MaxNumberOfCardiacPhases'
                        info.(type)=sscanf(data, '%d')';
                    case 'MaxNumberOfEchoes'
                        info.(type)=sscanf(data, '%d')';
                    case 'MaxNumberOfSlicesLocations'
                        info.(type)=sscanf(data, '%d')';
                    case 'MaxNumberOfDynamics'
                        info.(type)=sscanf(data, '%d')';
                    case 'MaxNumberOfMixes'
                        info.(type)=sscanf(data, '%d')';
                    case 'PatientPosition'
                        info.(type)=data;
                    case 'PreparationDirection'
                        info.(type)=data;
                    case 'Technique'
                        info.(type)=data;
                    case 'ScanResolution'
                        info.(type)=sscanf(data, '%d')';
                    case 'ScanMode'
                        info.(type)=data;
                    case 'RepetitionTime'
                        info.(type)=sscanf(data, '%lf')';
                    case 'Fov'
                        info.(type)=sscanf(data, '%lf')';
                    case 'WaterFatShift'
                        info.(type)=sscanf(data, '%lf')';
                    case 'Angulation'
                        info.(type)=sscanf(data, '%lf')';
                    case 'OffCentre'
                        info.(type)=sscanf(data, '%lf')';
                    case 'FlowCompensation'
                        info.(type)=sscanf(data, '%d')';
                    case 'Presaturation'
                        info.(type)=sscanf(data, '%d')';
                    case 'PhaseEncodingVelocity'
                        info.(type)=sscanf(data, '%lf')';
                    case 'Mtc'
                        info.(type)=sscanf(data, '%lf')';
                    case 'Spir'
                        info.(type)=sscanf(data, '%lf')';
                    case 'EpiFactor'
                        info.(type)=sscanf(data, '%lf')';
                    case 'DynamicScan'
                        info.(type)=sscanf(data, '%lf')';
                    case 'Diffusion'
                        info.(type)=sscanf(data, '%lf')';
                    case 'DiffusionEchoTime'
                        info.(type)=sscanf(data, '%lf')';
                    case 'MaxNumberOfDiffusionValues'
                        info.(type)=sscanf(data, '%d')';
                    case 'MaxNumberOfGradientOrients'
                        info.(type)=sscanf(data, '%d')';
                    case 'NumberOfLabelTypes'
                        info.(type)=sscanf(data, '%d')';
                    case 'HeaderComment'
                    otherwise
                        info.(type)=data;
                end
            end
        case 2
        case 3
            if(str(1)=='#');
                [type datatype datalength]=Image_Information_Line(str);
                if(~isempty(type))
                    nIC=nIC+1;
                    ImageInformationTags(nIC).Name=type;
                    ImageInformationTags(nIC).DataType=datatype;
                    ImageInformationTags(nIC).NumberOfValues=datalength;
                end
            end
        case 4
            if(str(1)~='#');
                nSC=nSC+1;
                vals=regexp(str, '\s+','split');
                vald=sscanf(str, '%lf')';
                current_loc=0;
                for i=1:length(ImageInformationTags)
                    IIT=ImageInformationTags(i);
                    if(strcmp(IIT.DataType,'string'))
                        SliceInformation(nSC).(IIT.Name)=vals{current_loc+1};
                    else
                        SliceInformation(nSC).(IIT.Name)=vald(current_loc+1:current_loc+IIT.NumberOfValues);
                    end
                    current_loc=current_loc+IIT.NumberOfValues;
                end
            end
            
        case 5
        otherwise
            %disp(str);
    end
end
fclose(fid);
info.HeaderComment=HeaderComment;
info.SliceInformation=SliceInformation;
info.ImageInformationTags=ImageInformationTags;

% Add Dimensions and Voxel Spacing. Warning, based on only 1 slice!
infof=info.SliceInformation(1);
if(isfield(infof,'ReconResolution'))
    if(isfield(info,'MaxNumberOfSlicesLocations'))
        zs(1)=info.MaxNumberOfSlicesLocations;
        zs(2)=length(SliceInformation)/zs(1);
        if((mod(zs(2),1)>0)||zs(2)==1)
            zs=length(SliceInformation);
        end
    else
        zs=length(SliceInformation);
    end
    
    info.Dimensions=[infof.ReconResolution zs];
else
    info.Dimensions=[info.ScanResolution length(SliceInformation)];
end
if(isfield(infof,'PixelSpacing'))
    if(isfield(infof,'SliceThickness')&&isfield(infof,'SliceGap'))
        zs=infof.SliceThickness+infof.SliceGap;
    else
        zs=0;
    end
    info.Scales=[infof.PixelSpacing zs];
else
    info.Scales=[0 0 0];
end


[folder,filen]=fileparts(info.Filename);
info.FilenameREC=fullfile(folder,[filen '.rec']);
   
    
% Add bith depth
if(infof.ImagePixelSize)
    info.BitDepth=infof.ImagePixelSize;
else
    if(exist(info.FilenameREC,'file'))
        file_info=dir(info.FilenameREC);
        bytes=file_info.bytes;
        info.BitDepth=(bytes/prod(info.Dimensions))*8;
    end
end


function [type datatype datalength]=Image_Information_Line(str)
s=find(str=='(',1,'last');
if(isempty(s)), s=length(str); end
type=str(1:s-1);  data=str(s+1:end);
type=regexp(type, '\s+|/|_', 'split');
type_clean='';
for i=1:length(type)
    part=type{i};
    part(part=='#')=[]; part(part==' ')=[]; partu=uint8(part);
    if(~isempty(part))
        check=((partu>=97)&(partu<=122))|((partu>=65)&(partu<=90));
        if(check)
            part=lower(part); part(1)=upper(part(1));
            type_clean=[type_clean part];
        else
            break;
        end
    end
end
type=type_clean;
while(~isempty(data)&&data(1)==' '), data=data(2:end); end
while(~isempty(data)&&data(end)==' '), data=data(1:end-1); end
if(~isempty(data))
    data=data(1:end-1);
    s=find(data=='*',1,'first');
    if(isempty(s)),
        datalength=1; datatype=data;
    else
        datalength=str2double(data(1:s-1));  datatype=data(s+1:end);
    end
else
    datalength=0; datatype=''; type='';
end


function [type data]=General_Information_Line(str)
s=find(str==':',1,'first');
if(isempty(s)), s=length(str); end
type=str(1:s-1);  data=str(s+1:end);
type=regexp(type, '\s+|/', 'split');
type_clean='';
for i=1:length(type)
    part=type{i};
    part(part=='.')=[]; part(part==' ')=[]; partu=uint8(part);
    if(~isempty(part))
        check=((partu>=97)&(partu<=122))|((partu>=65)&(partu<=90));
        if(check)
            part=lower(part); part(1)=upper(part(1));
            type_clean=[type_clean part];
        else
            break;
        end
    end
end
type=type_clean;
while(~isempty(data)&&data(1)==' '), data=data(2:end); end
while(~isempty(data)&&data(end)==' '), data=data(1:end-1); end

