function [segment_image_map, labelled_segments] = PTKGetSegmentsByNearestBronchus(airway_root, left_and_right_lungs, segmental_bronchi_by_lobe, lobes, reporting)
    % PTKGetSegmentsByNearestBronchus. Allocates airways to pulmonary segments
    %
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
        
    results_left = GetLeft(airway_root, left_and_right_lungs.Copy, lobes.Copy, segmental_bronchi_by_lobe, reporting);
    results_right = GetRight(airway_root, left_and_right_lungs, lobes, segmental_bronchi_by_lobe, reporting);
    segment_image_map = PTKCombineLeftAndRightImages(left_and_right_lungs, results_left, results_right, left_and_right_lungs);
    segment_image_map.ImageType = PTKImageType.Colormap;
    labelled_segments = segmental_bronchi_by_lobe;
end

function results_right = GetRight(airway_root, left_and_right_lungs, lobes, segmental_bronchi_by_lobe, reporting)
    results_right = left_and_right_lungs.BlankCopy;
    results_right.ChangeRawImage(zeros(results_right.ImageSize, 'uint8'));
    all_segments = segmental_bronchi_by_lobe.Segments;
    
    results_upper_right = GetSegmentsFromUpperRightLobe(airway_root, lobes, all_segments, reporting);
    results_right.ChangeSubImageWithMask(results_upper_right, lobes, 1);
    
    results_mid_right = GetSegmentsFromMidRightLobe(airway_root, lobes, all_segments, reporting);
    results_right.ChangeSubImageWithMask(results_mid_right, lobes, 2);
    
    results_lower_right = GetSegmentsFromLowerRightLobe(airway_root, lobes, all_segments, reporting);
    results_right.ChangeSubImageWithMask(results_lower_right, lobes, 4);
    
    results_right.ImageType = PTKImageType.Colormap;
end

function results_left = GetLeft(airway_root, left_and_right_lungs, lobes, segmental_bronchi_by_lobe, reporting)
    results_left = left_and_right_lungs.BlankCopy;
    results_left.ChangeRawImage(zeros(results_left.ImageSize, 'uint8'));
    all_segments = segmental_bronchi_by_lobe.Segments;
    
    results_upper_left = GetSegmentsFromUpperLeftLobe(airway_root, lobes, all_segments, reporting);
    results_left.ChangeSubImageWithMask(results_upper_left, lobes, 5);
    
    results_lower_left = GetSegmentsFromLowerLeftLobe(airway_root, lobes, all_segments, reporting);
    results_left.ChangeSubImageWithMask(results_lower_left, lobes, 6);
    
    results_left.ImageType = PTKImageType.Colormap;
end

function results = GetSegmentsFromUpperRightLobe(airway_root, lobes, all_segments, reporting)
    roi = lobes.BlankCopy;
    roi.ChangeRawImage(lobes.RawImage == 1);
    segments = all_segments.UpperRightSegments;
    segments_remaining = segments;    
    airways_image = PTKGetAirwayImageFromCentreline(segments, airway_root, roi, true);
    [results, d1, d2, is, js, ks] = DivideImageCropped(airways_image, roi);
    
    % apical
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.R_AP, d1, d2, is, js, ks, 'k min');
    
    % posterior
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.R_P, d1, d2, is, js, ks, 'd1 max');
    
    % anterior
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.R_AN, d1, d2, is, js, ks, 'd1 min');

    % Verify there are no remaining segments
    if ~isempty(segments_remaining) || ~isempty(d1) || ~isempty(d2) || ~isempty(is) || ~isempty(js) || ~isempty(ks)
        reporting.Error('PTKGetSegmentsByNearestBronchus:ProgramError', 'An unexpected situation occurred');
    end

    % Recolour segment map according to segment numbers
    segment_colour_mapping = [0, segments.SegmentIndex];
    results.ChangeRawImage(segment_colour_mapping(results.RawImage + 1));    
end

function results = GetSegmentsFromMidRightLobe(airway_root, lobes, all_segments, reporting)
    roi = lobes.BlankCopy;
    roi.ChangeRawImage(lobes.RawImage == 2);
    segments = all_segments.MiddleRightSegments;
    segments_remaining = segments;    
    airways_image = PTKGetAirwayImageFromCentreline(segments, airway_root, roi, true);
    [results, d1, d2, is, js, ks] = DivideImageCropped(airways_image, roi);
    
    % medial
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.R_M, d1, d2, is, js, ks, 'd2 min');
    
    % lateral
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.R_L, d1, d2, is, js, ks, 'd2 min');

    % Verify there are no remaining segments
    if ~isempty(segments_remaining) || ~isempty(d1) || ~isempty(d2) || ~isempty(is) || ~isempty(js) || ~isempty(ks)
        reporting.Error('PTKGetSegmentsByNearestBronchus:ProgramError', 'An unexpected situation occurred');
    end

    % Recolour segment map according to segment numbers
    segment_colour_mapping = [0, segments.SegmentIndex];
    results.ChangeRawImage(segment_colour_mapping(results.RawImage + 1));        
end

function results = GetSegmentsFromLowerRightLobe(airway_root, lobes, all_segments, reporting)
    roi = lobes.BlankCopy;
    roi.ChangeRawImage(lobes.RawImage == 4);
    segments = all_segments.LowerRightSegments;
    segments_remaining = segments;    
    airways_image = PTKGetAirwayImageFromCentreline(segments, airway_root, roi, true);
    [results, d1, d2, is, js, ks] = DivideImageCropped(airways_image, roi);
    
    % superior
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.R_S, d1, d2, is, js, ks, 'already set');
    
    % anterior-basal
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.R_AB, d1, d2, is, js, ks, 'd1 min');

    % posterior-basal
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.R_PB, d1, d2, is, js, ks, 'd2 max');

    % medial-basal
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.R_MB, d1, d2, is, js, ks, 'd2 max');

    % lateral-basal
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.R_LB, d1, d2, is, js, ks, 'd2 min');

    % Verify there are no remaining segments
    if ~isempty(segments_remaining) || ~isempty(d1) || ~isempty(d2) || ~isempty(is) || ~isempty(js) || ~isempty(ks)
        reporting.Error('PTKGetSegmentsByNearestBronchus:ProgramError', 'An unexpected situation occurred');
    end

    % Recolour segment map according to segment numbers
    segment_colour_mapping = [0, segments.SegmentIndex];
    results.ChangeRawImage(segment_colour_mapping(results.RawImage + 1));        
end

function results = GetSegmentsFromUpperLeftLobe(airway_root, lobes, all_segments, reporting)
    roi = lobes.BlankCopy;
    roi.ChangeRawImage(lobes.RawImage == 5);
    segments = all_segments.UpperLeftSegments;
    segments_remaining = segments;
    airways_image = PTKGetAirwayImageFromCentreline(segments, airway_root, roi, true);
    [results, d1, d2, is, js, ks] = DivideImageCropped(airways_image, roi);
    
    % apico-posterior
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.L_APP, d1, d2, is, js, ks, 'd1 max');
    % Special case where there are 5 segments in the upper left lobe
    if numel(segments_remaining) == 4
        [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.L_APP2, d1, d2, is, js, ks, 'd1 max');
    end
    
    % inferior lingular
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.L_IL, d1, d2, is, js, ks, 'd1 min');
    
    % anterior
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.L_AN, d1, d2, is, js, ks, 'd2 min');
    
    % superior lingular
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.L_SL, d1, d2, is, js, ks, 'd2 max');
    
    % Verify there are no remaining segments    
    if ~isempty(segments_remaining) || ~isempty(d1) || ~isempty(d2) || ~isempty(is) || ~isempty(js) || ~isempty(ks)
        reporting.Error('PTKGetSegmentsByNearestBronchus:ProgramError', 'An unexpected situation occurred');
    end
    
    % Recolour segment map according to segment numbers
    segment_colour_mapping = [0, segments.SegmentIndex];
    results.ChangeRawImage(segment_colour_mapping(results.RawImage + 1));
end

function results = GetSegmentsFromLowerLeftLobe(airway_root, lobes, all_segments, reporting)
    roi = lobes.BlankCopy;
    roi.ChangeRawImage(lobes.RawImage == 6);
    segments = all_segments.LowerLeftSegments;
    segments_remaining = segments;    
    airways_image = PTKGetAirwayImageFromCentreline(segments, airway_root, roi, true);
    [results, d1, d2, is, js, ks] = DivideImageCropped(airways_image, roi);
    
    % superior
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.L_S, d1, d2, is, js, ks, 'd1 max');
    
    % anteromedial basal
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.L_AMB, d1, d2, is, js, ks, 'd1 min');

    % posterior basal
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.L_PB, d1, d2, is, js, ks, 'd2 max');
    
    % lateral basal
    [segments_remaining, d1, d2, is, js, ks] = ChooseSegment(segments_remaining, PTKPulmonarySegmentLabels.L_LB, d1, d2, is, js, ks, 'd2 min');

    % Verify there are no remaining segments
    if ~isempty(segments_remaining) || ~isempty(d1) || ~isempty(d2) || ~isempty(is) || ~isempty(js) || ~isempty(ks)
        reporting.Error('PTKGetSegmentsByNearestBronchus:ProgramError', 'An unexpected situation occurred');
    end
    
    
    % Recolour segment map according to segment numbers
    segment_colour_mapping = [0, segments.SegmentIndex];
    results.ChangeRawImage(segment_colour_mapping(results.RawImage + 1));    
end


function [segments, d1, d2, is, js, ks] = ChooseSegment(segments, segment_label, d1, d2, is, js, ks, comparison)
    if strcmp(comparison, 'd1 min')
        [~, index] = min(d1);
    elseif strcmp(comparison, 'd1 max')
        [~, index] = max(d1);
    elseif strcmp(comparison, 'd2 min')
        [~, index] = min(d2);
    elseif strcmp(comparison, 'd2 max')
        [~, index] = max(d2);
    elseif strcmp(comparison, 'k max')
        [~, index] = max(ks);
    elseif strcmp(comparison, 'k min')
        [~, index] = min(ks);
    elseif strcmp(comparison, 'already set')
        index = find([segments.SegmentIndex] == uint8(segment_label));
    end
    
    SetSegmentIndex(segments(index), segment_label);
    
    % Now remove from the vectors
    segments(index) = [];
    d1(index) = [];
    d2(index) = [];
    is(index) = [];
    js(index) = [];
    ks(index) = [];
end

function SetSegmentIndex(segments, segment_index)
    segments_to_do = segments;
    for segment = segments_to_do
        segment.SegmentIndex = uint8(segment_index);
        segments_to_do = [segments_to_do, segment.Children];
    end
end

function [starting_airways, d1, d2, is, js, ks] = DivideImageCropped(starting_airways, roi)
    roi = roi.Copy;
    roi.ChangeRawImage(roi.RawImage | ((starting_airways.RawImage > 0) & (starting_airways.RawImage ~= 7)));
    template = roi.BlankCopy;
    roi.CropToFit;
    starting_airways.ResizeToMatch(roi);
    raw_image = int8(starting_airways.RawImage);
    raw_image(starting_airways.RawImage == 7) = 0;
    [~, index] = bwdist(raw_image > 0);
    results_image = starting_airways.RawImage(index);
    starting_airways.ChangeRawImage(results_image);
    starting_airways.ResizeToMatch(template);
    [d1, d2, is, js, ks, colours] = AnalyseImage(starting_airways);
end

function [d1, d2, is, js, ks, colours] = AnalyseImage(nn_image)
    number_regions = max(nn_image.RawImage(:));
    d1 = zeros(number_regions, 1);
    d2 = zeros(number_regions, 1);
    is = zeros(number_regions, 1);
    js = zeros(number_regions, 1);
    ks = zeros(number_regions, 1);
    colours = 1 : number_regions;
    for region_index = 1 : number_regions
        local_indices = find(nn_image.RawImage == region_index);
        global_indices = nn_image.LocalToGlobalIndices(local_indices);
        [ic, jc, kc] = nn_image.GlobalIndicesToCoordinatesMm(global_indices);
        centrepoint = [mean(ic), mean(jc), mean(kc)];
        d1(region_index) = centrepoint(1) - centrepoint(3);
        d2(region_index) = centrepoint(1) + centrepoint(3);
        is(region_index) = centrepoint(1);
        js(region_index) = centrepoint(2);
        ks(region_index) = centrepoint(3);
    end
end