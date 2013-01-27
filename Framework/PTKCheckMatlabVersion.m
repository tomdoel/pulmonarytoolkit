function PTKCheckMatlabVersion
    % PTKCheckMatlabVersion. A function for verifying that an appropriate version
    %     of Matlab is installed for the Pulmonary Toolkit.
    %
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %

    % Get the current Matlab version
    [major_version, minor_version] = PTKSoftwareInfo.GetMatlabVersion;

    % Get the minimum Matlab version required to run the software
    minimum_major_version = PTKSoftwareInfo.MatlabMinimumMajorVersion;
    minimum_minor_version = PTKSoftwareInfo.MatlabMinimumMinorVersion;
    minimum_version_string = [int2str(minimum_major_version) '.' int2str(minimum_minor_version)];
    
    % Get the recommended Matlab version for running the software
    advised_major_version = PTKSoftwareInfo.MatlabAdvisedMajorVersion;
    advised_minor_version = PTKSoftwareInfo.MatlabAdvisedMinorVersion;
    advised_version_string = [int2str(advised_major_version) '.' int2str(advised_minor_version)];

    if (major_version > minimum_major_version) || ...
            ((major_version == minimum_major_version) && (minor_version >= minimum_minor_version))
        minimum_version_passed = true;
    else
        minimum_version_passed = false;
    end
    
    if (major_version > advised_major_version) || ...
            ((major_version == advised_major_version) && (minor_version >= advised_minor_version))
        advised_version_passed = true;
    else
        advised_version_passed = false;
    end
   
    if ~minimum_version_passed
        error('PTKCheckMatlabVersion:MatlabVersionBelowRequired', ['You need a newer version of Matlab to run the Pulmonary Toolkit. Minimum Matlab version:' minimum_version_string '. Recommended Matlab version:' advised_version_string]);
    else
       if ~advised_version_passed
           warning('PTKCheckMatlabVersion:MatlabVersionBelowAdvised', ['Your Matlab version is lower than the recommended version for the Pulmonary Toolkit. Some features may not work as expected. Recommended Matlab version:' advised_version_string]);
       end
    end
end

