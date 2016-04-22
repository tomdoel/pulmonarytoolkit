classdef MimImageFileFormat
    % MimImageFileFormat. An enumeration used to specify how a medical image is
    % stored
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    enumeration
        Dicom,      % DICOM format
        Metaheader, % Metaheader (mha/mhd) plus raw data
        Matlab,     % Matlab matrix
        Analyze,    % Analyze format
        Gipl,       % Guys Image Processing Lab
        Isi,        % ISI
        Nifti,      % NIFTI
        V3d,        % Philips Scanner
        Vmp,        % BrainVoyager
        Xif,        % HDllab/ATL Ultrasound
        Vtk,        % Visualization Toolkit (VTK)
        MicroCT,    % MicroCT
        Par         % Philips PAR/REC
    end
end