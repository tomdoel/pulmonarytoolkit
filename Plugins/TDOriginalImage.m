classdef TDOriginalImage < TDPlugin
    % TDOriginalImage. Plugin to obtain hte uncropped full-size image
    %
    %     This is a plugin for the Pulmonary Toolkit. Plugins can be run using 
    %     the gui, or through the interfaces provided by the Pulmonary Toolkit.
    %     See TDPlugin.m for more information on how to run plugins.
    %
    %     Plugins should not be run directly from your code.
    %
    %     TDOriginalImage loads the original image data from disk. Since
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
        TDPTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
    
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            reporting.ShowProgress('Loading Images');
            results = TDOriginalImage.LoadImages(dataset.GetImageInfo, reporting);
            reporting.CompleteProgress;
        end
        
        function image = LoadImages(image_info, reporting)
            image_path = image_info.ImagePath;
            filenames = image_info.ImageFilenames;
            image_file_format = image_info.ImageFileFormat;
            study_uid = image_info.StudyUid;
            
            if isempty(filenames)
                filenames = TDDiskUtilities.GetDirectoryFileList(image_path, '*');
            end
            
            switch(image_file_format)
                case TDImageFileFormat.Dicom
                    image = TDLoadImageFromDicomFiles(image_path, filenames, false, reporting);
                case TDImageFileFormat.Metaheader
                    image = TDLoad3DRawAndMetaFiles(image_path, filenames, study_uid, reporting);
                otherwise
                    reporting.Error('TDOriginalImage:UnknownImageFileFormat', 'Could not load the image because the file format was not recognised.');
            end            
        end

    end
    
end