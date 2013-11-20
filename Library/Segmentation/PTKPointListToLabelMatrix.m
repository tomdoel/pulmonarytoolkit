function label_image = PTKPointListToLabelMatrix(points_list, image_template, reporting)
    % PTKPointListToLabelMatrix. Converts sets of image points into a label
    %     matrix
    %
    %     PTKPointListToLabelMatrix takes in a set of regions, each member of
    %     which is a vector of points for that region. Each point is defined by
    %     its global index. Each vector of points is assigned a label in the
    %     output image.
    %
    %     So if start_points == {[14, 35, 53], [90, 138]}, then the output image
    %     will have two colour values (1 and 2). The points with global indices
    %     14, 35 and 53 will be set to colour index 1, and the points with
    %     global indices 90 and 138 will be set to colour index 2.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2013.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %
     
    if ~isa(image_template, 'PTKImage')
        reporting.Error('PTKPointListToLabelMatrix:BadInput', 'Requires a PTKImage as input');
    end
    
    if ~iscell(points_list)
        reporting.Error('PTKPointListToLabelMatrix:BadInput', 'points_list must be a cell array');
    end
    
    if numel(points_list) > 255
        reporting.Error('PTKPointListToLabelMatrix:TooManyRegions', 'Maximum number of 255 different labels');
    end
    
    label_image = image_template.BlankCopy;
    label_image.ChangeRawImage(zeros(image_template.ImageSize, 'uint8'));
    for label_index = 1 : numel(points_list)
        label_image.SetIndexedVoxelsToThis(points_list{label_index}, label_index);
    end
end