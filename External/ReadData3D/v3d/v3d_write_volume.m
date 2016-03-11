function v3d_write_volume(I,fname,scales)
% Function for writing V3D volume files version R6.1
% 
% v3d_write_volume(volume, filename, voxelsize in mm)
%
% examples:
% I=uint16(rand(64,64,64)*65536);
%
% 1: v3d_write_volume(I);
% 2: v3d_write_volume(I,'random.v3d',[2 2 2];

% Filename
    if((exist('fname','var')==0)), 
        [filename, pathname] = uiputfile('*.v3d', 'Write v3d-file'); 
        fname = [pathname filename]; 
    end
    
% Sizes
    sizes=size(I);
% Scales
    if(exist('scales','var')==0), scales=ones(1,3); end;
% Offset
    offset=204; % Header size R6.1
% Filesize
    fsize=numel(I)*2+offset;
% Format
    fform='3D-RA';
% Version
    vers='6.1';
% Voxelbits
    bits=16; 
% par1;
    par1 = 1072693248; % The meaning of this number is unknown

disp(['filename : ' num2str(fname)]);   
disp(['format : ' fform]);
disp(['version : ' vers]);
disp(['filesize : ' num2str(fsize)]);
fprintf('sizes : %i, %i, %i\n',sizes);
fprintf('scales : %2.6f, %2.6f, %2.6f\n',scales);
disp(['voxelbits : ' num2str(bits)]);
disp(['offset : ' num2str(offset)]);
disp(['par1 : ' num2str(par1)]);
fprintf('\n');

fout=fopen(fname,'wb');
fwrite(fout,[fform ' R' vers],'char');
fwrite(fout,zeros(1,30),'uint8'); %seek
fwrite(fout,sizes,'int');
fwrite(fout,scales,'double');

fwrite(fout,zeros(1,28),'uint8'); %seek 
fwrite(fout,par1,'int');
fwrite(fout,zeros(1,28),'uint8'); %seek
fwrite(fout,par1,'int');
fwrite(fout,zeros(1,28),'uint8'); %seek
fwrite(fout,par1,'int');

fwrite(fout,bits,'int'); % Seems the new (R6.1) number of bits position

% Meaning of this part of the header is unknown
fwrite(fout,140,'int');
fwrite(fout,1,'int');
fwrite(fout,1075789855,'int');
fwrite(fout,1068449823,'int');
fwrite(fout,0,'int');
fwrite(fout,0,'uint8');
fwrite(fout,64,'uint8');
fwrite(fout,143,'uint8');
fwrite(fout,192,'uint8');
fwrite(fout,1,'int');

% Write uint16 volume
fwrite(fout,uint16(I),'uint16');

fclose('all');



