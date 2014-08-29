classdef PTKTimer < PTKBaseClass
    % PTKTimer. Part of the internal framework of the Pulmonary Toolkit.
    %
    %     You should not use this class within your own code. It is intended to
    %     be used internally within the framework of the Pulmonary Toolkit.
    %
    %     PTKTimer is used to time plugin execution
    %
    %     Licence
    %     -------
    %     Part of the TD Pulmonary Toolkit. http://code.google.com/p/pulmonarytoolkit
    %     Author: Tom Doel, 2012.  www.tomdoel.com
    %     Distributed under the GNU GPL v3 licence. Please see website for details.
    %    

    properties (Access = private)
        StartTicId       % ID from the tic function called at Start()
        PauseTicId       % ID from the tic function called at Resume()
        Reporting        % error/progress reporting
    end
    
    properties (SetAccess = private)
        SelfTime         % After Stop() is called, contains elapsed time in seconds, excluding when the timer was paused
        TotalElapsedTime % After Stop() is called, contains elapsed time in seconds, ignoring any Pause() calls
    end
    
    methods
        function obj = PTKTimer(reporting)
            obj.Reporting = reporting;
        end
        
        function Start(obj)
            if ~isempty(obj.StartTicId)
                reporting.Error('PTKTimer:TimerAlreadyStarted', 'The Start() method was called but the clock has already been started.');
            end
            obj.StartTicId = tic;
            obj.PauseTicId = obj.StartTicId;
        end

        function Stop(obj)
            if isempty(obj.StartTicId)
                reporting.Error('PTKTimer:TimerNotStarted', 'The Stop() method was called but the clock has not been started.');
            end
            if ~isempty(obj.TotalElapsedTime)
                reporting.Error('PTKTimer:ClockAlreadyStopped', 'The Stop() method was called but the clock has already been stopped.');
            end
            obj.TotalElapsedTime = toc(obj.StartTicId);
            elapsed_time_since_resume = toc(obj.PauseTicId);
            if isempty(obj.SelfTime)
                obj.SelfTime = elapsed_time_since_resume;
            else
                obj.SelfTime = obj.SelfTime + elapsed_time_since_resume;
            end
        end
        
        function Pause(obj)
            if isempty(obj.StartTicId)
                reporting.Error('PTKTimer:TimerNotStarted', 'The Pause() method was called but the clock has not been started.');
            end
            if isempty(obj.PauseTicId)
                reporting.Error('PTKTimer:TimerNotStarted', 'The Pause() method was called but the clock is already paused.');
            end
            if ~isempty(obj.TotalElapsedTime)
                reporting.Error('PTKTimer:ClockAlreadyStopped', 'The Pause() method was called but the clock has already been stopped.');
            end
            elapsed_time_since_resume = toc(obj.PauseTicId);
            if isempty(obj.SelfTime)
                obj.SelfTime = elapsed_time_since_resume;
            else
                obj.SelfTime = obj.SelfTime + elapsed_time_since_resume;
            end
            obj.PauseTicId = [];
        end
        
        function Resume(obj)
            if isempty(obj.StartTicId)
                reporting.Error('PTKTimer:TimerNotStarted', 'The Resume() method was called but the clock has not been started.');
            end
            if ~isempty(obj.TotalElapsedTime)
                reporting.Error('PTKTimer:ClockAlreadyStopped', 'The Resume() method was called but the clock has already been stopped.');
            end
            if ~isempty(obj.PauseTicId)
                reporting.Error('PTKTimer:NotPaused', 'The Resume() method was called but the clock has not been paused.');
            end
            obj.PauseTicId = tic;
        end
    end
end
