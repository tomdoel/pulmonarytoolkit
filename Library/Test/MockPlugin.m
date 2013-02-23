classdef MockPlugin < PTKPlugin
    % MockPlugin. Part of the PTK test framework
    %
    % This class is used in tests in place of an object implementing the
    % PTKPlugin interface. It allows expected calls to be verified, while
    % maintaining some of the expected behaviour of a PTKPlugin object. 
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    
        
    properties
        ButtonText = ''
        ToolTip = ''
        Category = ''

        AllowResultsToBeCached = true
        AlwaysRunPlugin = false
        PluginType = ''
        HidePluginInDisplay = false
        FlattenPreviewImage = true
        PTKVersion = '1'
        ButtonWidth = 6
        ButtonHeight = 2
        GeneratePreview = true
    end
       
    methods (Static)
        function results = RunPlugin(dataset, reporting)
            results = MockPlugin.RunPluginResults;
        end
        
        function results = GenerateImageFromResults(results, image_templates, reporting)
            if ~isa(results, 'PTKImage')
                results = results.ImageResult;
            end
       end
    end
end