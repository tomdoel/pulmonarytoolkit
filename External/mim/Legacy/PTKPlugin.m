classdef PTKPlugin < MimPlugin
    % MimPlugin. Base class for a Plugin used by the Pulmonary Toolkit
    %
    %     Plugins are classes you create to run your own routines from the
    %     Pulmonary Toolkit. When you create a plugin, it will automatically
    %     appear as a button in the gui, and is available to scripts and other
    %     plugins which use the Pulmonay Toolkit. The framework automatically
    %     handles result caching, dependency tracking and preview thumbnail
    %     generation.
    %
    %     To run a plugin from the gui, first start up the gui using the script
    %     ptk.m. Load in the dataset you wish to run the plugin with, and then
    %     click on the plugin button which is automatically created in the
    %     plugins panel on the right.
    %
    %     To run a plugin from your own code, first create a PTKMain object. Then
    %     call CreateDatasetFromInfo() to create a MimDataset for the image files
    %     you wish to run the plugin with. Then call GetResult() on this dataset
    %     interface to run the plugin or fetch a previously cached result.
    %
    %     Example
    %     -------
    %     Replace <image path> and <filenames> with the path and filenames
    %     to your image data, and MyPluginName with the name of the plugin to
    %     run.
    %
    %         image_info = MimImageInfo( <image path>, <filenames>, [], [], [], []);
    %         ptk = PTKMain;
    %         dataset = ptk.CreateDatasetFromInfo(image_info);
    %         airways = dataset.GetResult('MyPluginName');
    %    
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

end

