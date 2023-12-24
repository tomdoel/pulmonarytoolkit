classdef MimStorageFormat
    % Numeration which describes how a cached file will be stored
    %
    % When storing data in the cache, this enumeration can be used to 
    % choose the file format
    %
    % - Mat:
    %     Store as a Matlab .mat file 
    % - Xml:
    %     Convert to an XML file using a structured format
    %     that can be loaded back into the original data
    %     using CoreLoadXml(). Use this format when you wat
    % - SimplifiedXml:
    %     Save using a more compact XML format that uses
    %     less disk space and is easier for people to parse,
    %     but loading the data from the simplified XML file
    %     will not necessarily produce exactly the same
    %     structure that was saved
    %
    % .. Licence
    %    -------
    %    Part of the TD MIM Toolkit. https://github.com/tomdoel
    %    Author: Tom Doel, Copyright Tom Doel 2014.  www.tomdoel.com
    %    Distributed under the MIT licence. Please see website for details.
    %    
    
    enumeration
        Mat           % MATLAB .MAT file 
        Xml           % XML file that can be automatically reloaded
        XmlSimplified % XML file that may require conversion when loading
    end
end

