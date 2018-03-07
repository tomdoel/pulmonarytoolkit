function datasets=dicom_folder_info(link,subfolders)
% Function DICOM_FOLDER_INFO gives information about all Dicom files
% in a certain folder (and subfolders), or of a certain dataset
%
% datasets=dicom_folder_info(link,subfolders)
%
% inputs,
%   link : A link to a folder like "C:\temp" or a link to the first
%           file of a dicom volume "C:\temp\01.dcm"
%   subfolders : Boolean if true (default) also look in sub-folders for 
%           dicom files
%
% ouputs,
%   datasets : A struct with information about all dicom datasets in a
%            folder or of the selected dicom-dataset.
%              (Filenames are already sorted by InstanceNumber)
%
%
% Example output:
%  datasets=dicom_folder_info('D:\MedicalVolumeData',true);
%
%  datasets =  1x7 struct array with fields
%
%  datasets(1) = 
%             Filenames: {24x1 cell}
%                 Sizes: [512 512 24]
%                Scales: [0.3320 0.3320 4.4992]
%             DicomInfo: [1x1 struct]
%     SeriesInstanceUID: '1.2.840.113619.2.176.2025'
%     SeriesDescription: 'AX.  FSE PD'
%            SeriesDate: '20070101'
%            SeriesTime: '120000.000000'
%              Modality: 'MR'
%
%  datasets(1).Filenames =
%   'D:\MedicalVolumeData\IM-0001-0001.dcm'
%   'D:\MedicalVolumeData\IM-0001-0002.dcm'
%   'D:\MedicalVolumeData\IM-0001-0003.dcm'
%
% Function is written by D.Kroon University of Twente (June 2010)

% If no Folder given, give folder selection dialog
if(nargin<1), link =  uigetdir(); end

% If no subfolders option defined set it to true
if(nargin<2), subfolders=true; end

% Check if the input is a file or a folder
if(isdir(link))
    dirname=link; filehash=[];
else
    dirname = fileparts(link);
    info=dicominfo(link);
    SeriesInstanceUID=0;
    if(isfield(info,'SeriesInstanceUID')), SeriesInstanceUID=info.SeriesInstanceUID; end
    filehash=string2hash([dirname SeriesInstanceUID]);
    subfolders=false;
end

% Make a structure to store all files and folders
dicomfilelist.Filename=cell(1,100000);
dicomfilelist.InstanceNumber=zeros(1,100000);
dicomfilelist.ImagePositionPatient=zeros(100000,3);
dicomfilelist.hash=zeros(1,100000);
nfiles=0;

% Get all dicomfiles in the current folder (and sub-folders)
[dicomfilelist,nfiles]=getdicomfilelist(dirname,dicomfilelist,nfiles,filehash,subfolders);
if(nfiles==0), datasets=[]; return; end

% Sort all dicom files based on a hash from dicom-series number and folder name
datasets=sortdicomfilelist(dicomfilelist,nfiles);

% Add Dicom information like scaling and size
datasets=AddDicomInformation(datasets);

function datasets=AddDicomInformation(datasets)
for i=1:length(datasets)
    Scales=[0 0 0];
    Sizes=[0 0 0];
    SeriesInstanceUID=0;
    SeriesDescription='';
    SeriesDate='';
    SeriesTime='';
    Modality='';
    info=dicominfo(datasets(i).Filenames{1});
    nf=length(datasets(i).Filenames);

    if(isfield(info,'SpacingBetweenSlices')), Scales(3)=info.SpacingBetweenSlices; end
    if(isfield(info,'PixelSpacing')), Scales(1:2)=info.PixelSpacing(1:2); end
    if(isfield(info,'ImagerPixelSpacing ')), Scales(1:2)=info.PixelSpacing(1:2); end
    if(isfield(info,'Rows')), Sizes(1)=info.Rows; end
    if(isfield(info,'Columns')), Sizes(2)=info.Columns; end
    if(isfield(info,'NumberOfFrames')), Sizes(3)=info.NumberOfFrames; end
    if(isfield(info,'SeriesInstanceUID')), SeriesInstanceUID=info.SeriesInstanceUID; end
    if(isfield(info,'SeriesDescription')), SeriesDescription=info.SeriesDescription; end
    if(isfield(info,'SeriesDate')),SeriesDate=info.SeriesDate; end
    if(isfield(info,'SeriesTime')),SeriesTime=info.SeriesTime; end
    if(isfield(info,'Modality')), Modality=info. Modality; end
    if(nf>1), Sizes(3)=nf; end
    if(nf>1)
        info1=dicominfo(datasets(i).Filenames{2});
        if(isfield(info1,'ImagePositionPatient'))
            dis=abs(info1.ImagePositionPatient(3)-info.ImagePositionPatient(3));
            if(dis>0), Scales(3)=dis; end
        end
    end
    datasets(i).Sizes=Sizes;
    datasets(i).Scales=Scales;
    datasets(i).DicomInfo=info;
    datasets(i).SeriesInstanceUID=SeriesInstanceUID;
    datasets(i).SeriesDescription=SeriesDescription;
    datasets(i).SeriesDate=SeriesDate;
    datasets(i).SeriesTime=SeriesTime;
    datasets(i).Modality= Modality;
end

function datasets=sortdicomfilelist(dicomfilelist,nfiles)
datasetids=unique(dicomfilelist.hash(1:nfiles));
ndatasets=length(datasetids);
for i=1:ndatasets
    h=find(dicomfilelist.hash(1:nfiles)==datasetids(i));
    InstanceNumbers=dicomfilelist.InstanceNumber(h);
    ImagePositionPatient=dicomfilelist.ImagePositionPatient(h,:);
    if(length(unique(InstanceNumbers))==length(InstanceNumbers))
        [temp ind]=sort(InstanceNumbers);
    else
        [temp ind]=sort(ImagePositionPatient(:,3));
    end
    h=h(ind);
    datasets(i).Filenames=cell(length(h),1);
    for j=1:length(h)
        datasets(i).Filenames{j}=dicomfilelist.Filename{h(j)};
    end
end

function [dicomfilelist nfiles]=getdicomfilelist(dirname,dicomfilelist,nfiles,filehash,subfolders)
dirn=fullfile(dirname);
if(~isempty(dirn)), filelist = dir(dirn); else filelist = dir; end

for i=1:length(filelist)
    fullfilename=fullfile(dirname,filelist(i).name);
    if((filelist(i).isdir))
        if((filelist(i).name(1)~='.')&&(subfolders))
            [dicomfilelist nfiles]=getdicomfilelist(fullfilename ,dicomfilelist,nfiles,filehash,subfolders);
        end
    else
        if(file_is_dicom(fullfilename))
            try info=dicominfo(fullfilename); catch me, info=[]; end
            if(~isempty(info))
                InstanceNumber=0;
                ImagePositionPatient=[0 0 0];
                SeriesInstanceUID=0;
                Filename=info.Filename;
                if(isfield(info,'InstanceNumber')), InstanceNumber=info.InstanceNumber; end
                if(isfield(info,'ImagePositionPatient')),ImagePositionPatient=info.ImagePositionPatient; end
                
                if(isfield(info,'SeriesInstanceUID')), SeriesInstanceUID=info.SeriesInstanceUID; end
                hash=string2hash([dirname SeriesInstanceUID]);
                if(isempty(filehash)||(filehash==hash))
                    nfiles=nfiles+1; 
                    dicomfilelist.Filename{ nfiles}=Filename;
                    dicomfilelist.InstanceNumber( nfiles)=InstanceNumber;
                    dicomfilelist.ImagePositionPatient(nfiles,:)=ImagePositionPatient(:)';
                    dicomfilelist.hash( nfiles)=hash;
                end
            end
        end
    end
end

function isdicom=file_is_dicom(filename)
isdicom=false;
try
    fid = fopen(filename, 'r');
    status=fseek(fid,128,-1);
    if(status==0)
        tag = fread(fid, 4, 'uint8=>char')';
        isdicom=strcmpi(tag,'DICM');
    end
    fclose(fid);
catch me
end

function hash=string2hash(str,type)
% This function generates a hash value from a text string
%
% hash=string2hash(str,type);
%
% inputs,
%   str : The text string, or array with text strings.
% outputs,
%   hash : The hash value, integer value between 0 and 2^32-1
%   type : Type of has 'djb2' (default) or 'sdbm'
%
% From c-code on : http://www.cse.yorku.ca/~oz/hash.html 
%
% djb2
%  this algorithm was first reported by dan bernstein many years ago 
%  in comp.lang.c
%
% sdbm
%  this algorithm was created for sdbm (a public-domain reimplementation of
%  ndbm) database library. it was found to do well in scrambling bits, 
%  causing better distribution of the keys and fewer splits. it also happens
%  to be a good general hashing function with good distribution.
%
% example,
%
%  hash=string2hash('hello world');
%  disp(hash);
%
% Function is written by D.Kroon University of Twente (June 2010)


% From string to double array
str=double(str);
if(nargin<2), type='djb2'; end
switch(type)
    case 'djb2'
        hash = 5381*ones(size(str,1),1); 
        for i=1:size(str,2), 
            hash = mod(hash * 33 + str(:,i), 2^32-1); 
        end
    case 'sdbm'
        hash = zeros(size(str,1),1);
        for i=1:size(str,2), 
            hash = mod(hash * 65599 + str(:,i), 2^32-1);
        end
    otherwise
        error('string_hash:inputs','unknown type');
end


 

 





