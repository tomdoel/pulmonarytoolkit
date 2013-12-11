classdef PTKOriginalImage < PTKPlugin
    % PTKOriginalImage. Plugin to obtain hte uncropped full-size image
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See PTKPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     PTKOriginalImage loads the original image data from disk. Since
    %     full-size images can be very large, and plugins normally use the
    %     region of interest, this plugin result is not usually
    %     cached by default.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
    
    
    properties
        ButtonText = 'Full Image'
        ToolTip = 'Change the context to display the complete original image'
        Category = 'Context'

        AllowResultsToBeCached = false
        AlwaysRunPlugin = false
        PluginType = 'ReplaceImage'
        HidePluginInDisplay = false
        FlattenPreviewImage = false
        PTKVersion = '2'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
        Context = PTKContextSet.OriginalImage
    end
    
    methods (Static)
        function results = RunPlugin(dataset, context, reporting)
            reporting.ShowProgress('Loading Images');
            results = PTKOriginalImage.LoadImages(dataset.GetImageInfo, reporting);
            reporting.CompleteProgress;
        end
        
        function image = LoadImages(image_info, reporting)
            image_path = image_info.ImagePath;
            filenames = image_info.ImageFilenames;
            image_file_format = image_info.ImageFileFormat;
            study_uid = image_info.StudyUid;
            
            if isempty(filenames)
                filenames = PTKDiskUtilities.GetDirectoryFileList(image_path, '*');
                if isempty(filenames)
                    reporting.Error(PTKSoftwareInfo.FileMissingErrorId, ['Cannot find any files in the folder ' image_path]);
                end
            else
                first_file = filenames{1};
                if isa(first_file, 'PTKFilename')
                    first_file_path = first_file.Path;
                    first_file_name = first_file.Name;
                else
                    first_file_path = image_path;
                    first_file_name = first_file;
                end
                if ~PTKDiskUtilities.FileExists(first_file_path, first_file_name)
                    reporting.Error(PTKSoftwareInfo.FileMissingErrorId, ['Cannot find the file ' fullfile(image_path, filenames{1})]);
                end
            end
            
            switch(image_file_format)
                case PTKImageFileFormat.Dicom
                    image = PTKLoadImageFromDicomFiles(image_path, filenames, reporting);
                case PTKImageFileFormat.Metaheader
                    image = PTKLoad3DRawAndMetaFiles(image_path, filenames, study_uid, reporting);
                otherwise
                    reporting.Error('PTKOriginalImage:UnknownImageFileFormat', 'Could not load the image because the file format was not recognised.');
            end            
        end

    end
    
end