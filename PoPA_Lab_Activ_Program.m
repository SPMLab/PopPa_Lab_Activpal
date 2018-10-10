% PopPA Lab Activity Tracker Analysis Program 
% Created by: Anthony Chen, PhD Student 
% Start Date: July 4th, 2018
% Associated Objs 
    % journal_data.m
    % AP_data.m
    % logMessage.m
    
function varargout = PoPA_Lab_Activ_Program(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @PoPA_Lab_Activ_Program_OpeningFcn, ...
                   'gui_OutputFcn',  @PoPA_Lab_Activ_Program_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end

% --- Outputs from this function are returned to the command line.
function varargout = PoPA_Lab_Activ_Program_OutputFcn(~, eventdata, handles) 
varargout{1} = handles.output;

%%% ACTIVPAL ANALYSIS PROGRAM INITIALIZATION
function PoPA_Lab_Activ_Program_OpeningFcn(hObject, eventdata, handles, varargin)

    handles.output = hObject; guidata(hObject, handles);
    % Run Journal Table Header Method
    % Initialize Log Event Dialog Box
    % Disable Full Plot
    
try    
    [~, handles] = journal_data.initialize_Journal(handles); 
    guidata(hObject, handles);   
    
    handles = AP_data.initializeActivpalMemory(handles);
    guidata(hObject, handles); 

    master_logstr{2} = horzcat('[',datestr(datetime),']: ', logMessage.Name);
    master_logstr{1} = horzcat('[',datestr(datetime),']: ', logMessage.Initialize);
    set(handles.log_box, 'String', master_logstr, 'Min', 0, 'Max', 2, 'Value', []);
    
    set(handles.d2d_panel2, 'Visible', 'off') 
    
    handles.ControlParameters{1} = [3 6];
    handles.ControlParameters{2} = 0.8;
    handles.ControlParameters{3} = 1;
    guidata(hObject, handles);
    
catch ME
    errordlg(ME.message, 'Error Alert');
    set(handles.activpal_import, 'Enable', 'off');  
    set(handles.journal_table, 'Enable', 'off');
end 

%%% IMPORT JOURNAL FILE BUTTON
function import_journal_Callback(hObject, eventdata, handles)

% Run Journal CSV Import

try
    AP_data.delete_activpal_plots(handles)
    
    [journal_header_count, handles] = journal_data.initialize_Journal(handles); % Run Journal Table Header Method
    [handles, logstr] = journal_data.import_journal_file(journal_header_count, handles);
    guidata(hObject, handles);
    
    logMessage.GenerateLogMessage(handles.log_box, logstr)
    
catch ME
    errordlg(ME.message, 'Error Alert');
end

%%% IMPORT ACTIVPAL FILE BUTTON
function activpal_import_Callback(hObject, eventdata, handles)
try
    % Run Import Activpal Function
    [handles, start_date, logstr] = AP_data.import_activpal_func(handles);
    guidata(hObject, handles);
    
    % Print Log Event
    logMessage.GenerateLogMessage(handles.log_box, logstr)
    
    % Plot Hourly and Full Plots
    logstr = AP_data.gen_subplot_coordinates(handles, start_date);
    logMessage.GenerateLogMessage(handles.log_box, logstr)

    logstr = AP_data.fullplot(handles);
    logMessage.GenerateLogMessage(handles.log_box, logstr)

    % Implement Wake/Sleep Algorithm
    % sleep_algorithm.deMaastricht(activpal_data, start_date, end_date);
    
    % Set GUI State
    GUIobj_inst = GUIobj;
    GUIobj_inst.setJournalList(handles);
    GUIobj.enableJournalTable(handles);
    GUIobj.enableActionPanel(handles);
  
catch ME
    errordlg(ME.message, 'Error Alert');
end

%%% HOURLY PLOT DATE SELECTION
function ID_list_Callback(hObject, eventdata, handles)
try
    % Find Journal Column from Activpal Metadata
    start_date = hObject.String(get(hObject,'Value'),:); 
    
    % Plot Hourly Plots
    logstr = AP_data.gen_subplot_coordinates(handles, start_date);
    logMessage.GenerateLogMessage(handles.log_box, logstr) 
    
catch ME
    errordlg(ME.message, 'Error Alert');
end

%%% CELL SELECTION AT JOURNAL DATA TABLE
function journal_table_CellSelectionCallback(hObject, eventdata, handles)
try
    str = hObject.Data{eventdata.Indices(1,1), eventdata.Indices(1,2)};
    if size(eventdata.Indices,1) == 1 ...
            && ~isempty(regexp(str, '\d{1,2}:\d{2,}', 'once'))...
            && strcmp(num2str(handles.subject_id), hObject.Data{eventdata.Indices(1)}) == 1
        
        handles.journal_data.cell_selection = eventdata.Indices; 
        guidata(hObject, handles);
        
        GUIobj.enableGoodSelectionIndicator(handles); 
    else
        GUIobj.disableGoodSelectionIndicator(handles); 
    end
        
catch ME
    errordlg(ME.message, 'Error Alert');
end

%%% Action Panel Command
function journal_command_Callback(hObject, eventdata, handles)

try
    if isfield(handles.journal_data, 'cell_selection')
        f = waitbar(0,'Please wait...');
        
        listselection = hObject.Value;
        j_data = handles.journal_data.memory;
        j_selection = handles.journal_data.cell_selection;
        RecordingDuration = handles.journal_data.expDuration;
        
        time_selected = j_data{j_selection(1), j_selection(2)};
        
        % Find Day Based on Selected Journal Cell
        [InsertDay, ~] = ...
            journal_data.find_day(...
            length(handles.journal_table.ColumnName)-5, ... % Non-fixed Journal Column #
            str2double(RecordingDuration),...               % # of Experimental Recording in Journal
            j_selection,...                                 % Selected Cell in J Table
            get(handles.journal_table), ...                 % Journal Table Struct
            handles.activpal_data.memory);                  % Activpal Data in Working Memory
        
        switch listselection
            case 1
                % Save Current Activpal State for Undo
                handles.activpal_data.working = handles.activpal_data.memory;
                guidata(hObject, handles);
                
                % Run Insert Function
                [handles, logstr] = AP_data.insertToActivpalData(handles, time_selected, InsertDay);
                guidata(hObject, handles);
                
                
            case 2
                
                tempStart_time = datenum(handles.WorkStartInput.String);
                tempEnd_time = datenum(handles.WorkEndInput.String);
                
                [handles, logstr] = AP_data.markActivpal(handles, tempStart_time, tempEnd_time);
                guidata(hObject, handles); 
                
                
            case 3
                tempStart_time = datenum(handles.WorkStartInput.String);
                tempEnd_time = datenum(handles.WorkEndInput.String);
                
                [handles, logstr] = AP_data.unmarkActivpal(handles, tempStart_time, tempEnd_time);
                guidata(hObject, handles); 
                
                
            case 4
                handles.activpal_data.working = handles.activpal_data.memory;
                guidata(hObject, handles);
                
                [handles, logstr] = sleep_algorithm.insertWake(handles, time_selected, InsertDay);
                guidata(hObject, handles);
                
        
                
                
            case 5
                handles.activpal_data.working = handles.activpal_data.memory;
                guidata(hObject, handles);
                
                [handles, logstr] = sleep_algorithm.insertSleep(handles, time_selected, InsertDay);
                guidata(hObject, handles);
                
            case 6
                if datenum(handles.wake_insert.String) < datenum(handles.sleep_insert.String) &&  datenum(handles.WorkStartInput.String) < datenum(handles.WorkEndInput.String)
                    timeStamp = {handles.wake_insert.String, handles.sleep_insert.String, handles.WorkStartInput.String, handles.WorkEndInput.String};
                    [ActionTimeFrame, WakeSleep, logstr] = AP_data.calculate_activpalData(handles);
                    
                    if isfield(handles, 'SavedCalculatedData') == 1
                        handles.SavedCalculatedData = vertcat(handles.SavedCalculatedData(:,:), {timeStamp, ActionTimeFrame, WakeSleep});
                    else
                        handles.SavedCalculatedData = {timeStamp, ActionTimeFrame, WakeSleep};
                    end
                    
                    guidata(hObject, handles);
                    
                    %                     L1 = horzcat('Total time spent in Sitting (', sprintf('%.2f', ActionTimeFrame.Total_Time(1)), ' mins), Standing (', sprintf('%.2f', ActionTimeFrame.Total_Time(2)), ' mins) and Stepping (', sprintf('%.2f', ActionTimeFrame.Total_Time(3)), ' mins)');
                    %                     L2 = horzcat('Percent time spent in Sitting (', sprintf('%.2f', ActionTimeFrame.Percent_Of_Actions_During_Action_Time_Frame(1)), '), Standing (', sprintf('%.2f', ActionTimeFrame.Percent_Of_Actions_During_Action_Time_Frame(2)), ') and Stepping (', sprintf('%.2f', ActionTimeFrame.Percent_Of_Actions_During_Action_Time_Frame(3)), ')');
                    %                     L3 = horzcat('Total time spent in Light MET (', sprintf('%.2f', ActionTimeFrame.Time_In_MET(1)), ' mins), Moderate MET (', sprintf('%.2f', ActionTimeFrame.Time_In_MET(2)), ' mins) and Vigorous MET (', sprintf('%.2f', ActionTimeFrame.Time_In_MET(3)), ' mins)');
                    %                     L4 = horzcat('Number of prolonged sedentary count: ', sprintf('%.2f', ActionTimeFrame.Prolonged_Sed_Count), ' over ', sprintf('%.2f', ActionTimeFrame.Total_Prolonged_Sed_Min), ' Min');
                    %                     L5 = horzcat('Total valid wear time: ', sprintf('%.2f', ActionTimeFrame.Total_Valid_Wear_Min), ' Min');
                    %                     L6 = horzcat('Total invalid wear time: ', sprintf('%.2f', ActionTimeFrame.Total_Invalid_Wear_Min), ' Min');
                    %                     L7 = horzcat('Percent of valid wear time: ', sprintf('%.2f', ActionTimeFrame.Valid_Wear_Percentage*100), ' %');
                    %
                    %                     formatSpec = '%s\n%s\n%s\n%s\n%s\n%s\n%s';
                    %                     fprintf(formatSpec, L1, L2, L3, L4,L5,L6,L7);
                    %
                    %                     msg = cell(4,1);
                    %                     msg{1} = sprintf(L1);
                    %                     msg{2} = sprintf(L2);
                    %                     msg{3} = sprintf(L3);
                    %                     msg{4} = sprintf(L4);
                    %                     msg{5} = sprintf(L5);
                    %                     msg{6} = sprintf(L6);
                    %                     msg{7} = sprintf(L7);

                else 
                    close(f)
                    return
                end 
                
            case 7
                
                % Undo Inserted Activpal Data from Working Memory
                handles.activpal_data.memory = handles.activpal_data.working;
                guidata(hObject, handles);
                
                logstr = 'Undo Previous Action'; 
                
                
            otherwise
                
                return
        end
        
        close(f)
        logMessage.GenerateLogMessage(handles.log_box, logstr)
        
        start_date = GUIobj.find_list_StartDate(handles);
        logstr = AP_data.gen_subplot_coordinates(handles, start_date);
        logMessage.GenerateLogMessage(handles.log_box, logstr)
        
        logstr = AP_data.fullplot(handles);
        logMessage.GenerateLogMessage(handles.log_box, logstr)
        
    end
    
catch ME
    errordlg(ME.message, 'Error Alert');
    close(f) 
end


% Wake/Sleep Detection 
% Marking Work/PW
% Exporting 
% Validity Idx 
% MET Segregation and Find time spent in those MET zones 

% LOGBOX 
% --------------------------------------------------------------------
function log_box_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function log_box_Callback(hObject, eventdata, handles)
% --------------------------------------------------------------------

% TAB CONTROLS
% FILE TAB 
% --------------------------------------------------------------------
function FileIO_Callback(hObject, eventdata, handles)
function Save_Activpal_Selection_Callback(hObject, eventdata, handles)
try
    
    AP_data.ExportOutcomes(handles)
    logMessage.GenerateLogMessage(handles.log_box, 'Outcomes Saved') 

    %AP_data.Export(handles.activpal_data.memory, handles.AP_file_name.String)
    % logMessage.GenerateLogMessage(handles.log_box, 'New Activpal CSV Saved') 

catch ME
    errordlg(ME.message, 'Error Alert');
end
function Save_Action_Log_Button_Callback(hObject, eventdata, handles)
try
    logMessage.Export(handles.log_box);
    logMessage.GenerateLogMessage(handles.log_box, 'Log Action Saved') 

catch ME
    errordlg(ME.message, 'Error Alert');
end
% --------------------------------------------------------------------
% VIEW TAB
% --------------------------------------------------------------------
function view_button_Callback(hObject, eventdata, handles)
function hourly_plots_Callback(hObject, eventdata, handles)
% Enable Hourly Disasble Full
set(handles.d2d_panel2, 'Visible', 'off')
set(handles.d2d_panel, 'Visible', 'on')
function full_plot_Callback(hObject, eventdata, handles)
% Enable Full Plot Disable Hourly
set(handles.d2d_panel2, 'Visible', 'on')
set(handles.d2d_panel, 'Visible', 'off')
% --------------------------------------------------------------------
% CONTROL TAB 
% --------------------------------------------------------------------
function controls_button_Callback(hObject, eventdata, handles)
function setWearThreshold_Callback(hObject, eventdata, handles)
try
    prompt = {'Enter Valid Wear Threshold (0 - 1)'};
    title = 'Set Valid Wear';
    dims = [1 40];
    definput = {num2str(handles.ControlParameters{2})};
    answer = inputdlg(prompt,title,dims,definput);
    
    if isa(str2double(answer), 'numeric') && (str2double(answer) <= 1) && (str2double(answer) >= 0)
        handles.ControlParameters{2} = str2double(answer);
        guidata(hObject, handles);
    else
        errordlg('Invalid Input', 'Error Alert');
    end
    
catch
    errordlg('Invalid Input', 'Error Alert');
end
function SetMetThresholdButton_Callback(hObject, eventdata, handles)
try
    prompt = {'Light to Moderate', 'Moderate to Vigorous'};
    title = 'Set MET';
    dims = [1 40];
    definput = {num2str(handles.ControlParameters{1}(1)), num2str(handles.ControlParameters{1}(2))};
    answer = inputdlg(prompt,title,dims,definput);
    
    if isa(str2double(answer{1}), 'numeric') && isa(str2double(answer{1}), 'numeric') &&  (str2double(answer{1}) < str2double(answer{2}))
        handles.ControlParameters{1} = [str2double(answer{1}), str2double(answer{2})];
        guidata(hObject, handles);
    else
        errordlg('Invalid Input', 'Error Alert');
    end
    
catch
    errordlg('Invalid Input', 'Error Alert');
end
function sleepAlgorithmButton_Callback(hObject, eventdata, handles)
function wakeSleep_method_closest_Callback(hObject, eventdata, handles)
handles = sleep_algorithm.Sleep_AlgoSelection(handles, 1);
guidata(hObject, handles); 
function wakeSleep_method_Manual_Callback(hObject, eventdata, handles)
handles = sleep_algorithm.Sleep_AlgoSelection(handles, 2);
guidata(hObject, handles); 
function wakeSleep_method_DeM_Callback(hObject, eventdata, handles)
handles = sleep_algorithm.Sleep_AlgoSelection(handles, 3);
guidata(hObject, handles); 
% --------------------------------------------------------------------



function wake_insert_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function wake_insert_CreateFcn(hObject, eventdata, handles)

if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function sleep_insert_Callback(hObject, eventdata, handles)



% Miscellaneous
% --------------------------------------------------------------------
function journal_table_ButtonDownFcn(hObject, eventdata, handles)
function WorkStartInput_Callback(hObject, eventdata, handles)
function WorkStartInput_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function WorkEndInput_Callback(hObject, eventdata, handles)
function WorkEndInput_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function ID_list_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
function sleep_insert_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% --- Executes during object creation, after setting all properties.
function journal_command_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
set(hObject, 'String',  GUIobj.initialization_text); 


% --------------------------------------------------------------------
function wake_button_Callback(hObject, eventdata, handles)
cal = uicalendar('Weekend', [1 0 0 0 0 0 1], ...  
'SelectionType', 1, ...  
'DestinationUI', handles.wake_insert);

uiwait(cal) 

handles.F = figure('WindowStyle', 'normal', 'Name', 'Select Time', 'menubar','none', 'Resize', 'off', 'InnerPosition', [300 300 375 80], 'Units', 'pixels');

Guiobj = GUIobj; 
clockobj.generateClockFcn(Guiobj, handles);
uiwait(handles.F)
    
time = handles.figure1.UserData;
date = datevec(handles.wake_insert.String);
datevector = horzcat(date(1:3),time(1:2), time(3) + time(4)/1000);
DateT = datetime(datevector, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
handles.wake_insert.String = datestr(DateT); 
function sleep_button_Callback(hObject, eventdata, handles)
    cal = uicalendar('Weekend', [1 0 0 0 0 0 1], ...  
    'SelectionType', 1, ...  
    'DestinationUI', handles.sleep_insert);
    uiwait(cal) 
    handles.F = figure('WindowStyle', 'normal', 'Name', 'Select Time', 'menubar','none', 'Resize', 'off', 'InnerPosition', [300 300 375 80], 'Units', 'pixels');
    Guiobj = GUIobj; 
    clockobj.generateClockFcn(Guiobj, handles);
    uiwait(handles.F)
    time = handles.figure1.UserData;
    date = datevec(handles.sleep_insert.String);
    datevector = horzcat(date(1:3),time(1:2), time(3) + time(4)/1000);
    DateT = datetime(datevector, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    handles.sleep_insert.String = datestr(DateT); 
function action_start_button_Callback(hObject, eventdata, handles)

 cal = uicalendar('Weekend', [1 0 0 0 0 0 1], ...  
    'SelectionType', 1, ...  
    'DestinationUI', handles.WorkStartInput);
    uiwait(cal) 
    handles.F = figure('WindowStyle', 'normal', 'Name', 'Select Time', 'menubar','none', 'Resize', 'off', 'InnerPosition', [300 300 375 80], 'Units', 'pixels');
    Guiobj = GUIobj; 
    clockobj.generateClockFcn(Guiobj, handles);
    uiwait(handles.F)
    time = handles.figure1.UserData;
    date = datevec(handles.WorkStartInput.String);
    datevector = horzcat(date(1:3),time(1:2), time(3) + time(4)/1000);
    DateT = datetime(datevector, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    handles.WorkStartInput.String = datestr(DateT); 
function action_end_button_Callback(hObject, eventdata, handles)

 cal = uicalendar('Weekend', [1 0 0 0 0 0 1], ...  
    'SelectionType', 1, ...  
    'DestinationUI', handles.WorkEndInput);
    uiwait(cal) 
    handles.F = figure('WindowStyle', 'normal', 'Name', 'Select Time', 'menubar','none', 'Resize', 'off', 'InnerPosition', [300 300 375 80], 'Units', 'pixels');
    Guiobj = GUIobj; 
    clockobj.generateClockFcn(Guiobj, handles);
    uiwait(handles.F)
    time = handles.figure1.UserData;
    date = datevec(handles.WorkEndInput.String);
    datevector = horzcat(date(1:3),time(1:2), time(3) + time(4)/1000);
    DateT = datetime(datevector, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
    handles.WorkEndInput.String = datestr(DateT); 



