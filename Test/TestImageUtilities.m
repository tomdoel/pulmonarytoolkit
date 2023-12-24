classdef TestImageUtilities < CoreTest
    % TestImageUtilities. Tests for the PTKTextUtilities class.
    %
    %
    % .. Licence
    %    -------
    %    Part of the TD Pulmonary Toolkit. https://github.com/tomdoel/pulmonarytoolkit
    %    Author: Tom Doel, 2012.  www.tomdoel.com
    %    Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    methods
        function obj = TestImageUtilities
            obj.TestCT;
        end
    end
    
    methods (Access = private)
        function TestCT(obj)
            datasets = {};
            datasets{end + 1} = obj.MakeDataset('OT', 12, 'OT0');
            datasets{end + 1} = obj.MakeDataset('CT', 12, 'CT1');
            datasets{end + 1} = obj.MakeDataset('CT', 14, 'CTlarge');
            datasets{end + 1} = obj.MakeDataset('CT', 1, 'CT2');
            datasets{end + 1} = obj.MakeDataset('MR', 13, 'MR1');
            datasets{end + 1} = obj.MakeDataset('OT', 25, 'OT1');
            obj.Assert(strcmp(MimImageUtilities.FindBestSeries(datasets), 'CTlarge'));
        end
    
        function TestMR(obj)
            datasets = {};
            datasets{end + 1} = obj.MakeDataset('OT', 12, 'OT0');
            datasets{end + 1} = obj.MakeDataset('CT', 12, 'CT1');
            datasets{end + 1} = obj.MakeDataset('CT', 14, 'CTlarge');
            datasets{end + 1} = obj.MakeDataset('CT', 1, 'CT2');
            datasets{end + 1} = obj.MakeDataset('MR', 13, 'MR1');
            datasets{end + 1} = obj.MakeDataset('MR', 100, 'MRlarge');
            datasets{end + 1} = obj.MakeDataset('OT', 250, 'OT1');
            obj.Assert(strcmp(MimImageUtilities.FindBestSeries(datasets), 'MRlarge'));
        end
        
        function TestOther(obj)
            datasets = {};
            datasets{end + 1} = obj.MakeDataset('AB', 12, 'CT1');
            datasets{end + 1} = obj.MakeDataset('CD', 14, 'CTlarge');
            datasets{end + 1} = obj.MakeDataset('EF', 1, 'CT2');
            datasets{end + 1} = obj.MakeDataset('GH', 1300, 'GHuid');
            datasets{end + 1} = obj.MakeDataset('IJ', 100, 'MRlarge');
            datasets{end + 1} = obj.MakeDataset('KL', 250, 'OT1');
            obj.Assert(strcmp(MimImageUtilities.FindBestSeries(datasets), 'GHuid'));
        end
    end
    
    methods (Access = private, Static)
        function fake_dataset = MakeDataset(modality, num_images, uid)
            fake_dataset = struct;
            fake_dataset.Modality = modality;
            fake_dataset.NumberOfImages = num_images;
            fake_dataset.SeriesUid = uid;
        end
    end
end