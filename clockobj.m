classdef clockobj
    methods (Static)
        
        function generateCalendar(handles, selection)
            x = {'handles.wake_insert'; 'handles.sleep_insert'; 'handles.WorkStartInput'; 'handles.WorkEndInput'};
            [cal] = feval('uicalendar','InitDate', handles.ID_list.String(handles.ID_list.Value,:), 'Weekend', [1 0 0 0 0 0 1], 'SelectionType', 1, 'DestinationUI', eval(x{selection}));
            uiwait(cal)
        end
        
        function generateTimeString(handles, selection)
            x = {'handles.wake_insert.String'; 'handles.sleep_insert.String'; 'handles.WorkStartInput.String'; 'handles.WorkEndInput.String'};

            time = handles.figure1.UserData;
            date = datevec(eval(x{selection}));
            datevector = horzcat(date(1:3),time(1:2), time(3) + time(4)/1000);
            DateT = datetime(datevector, 'InputFormat', 'yyyy-MM-dd HH:mm:ss.SSS');
            eval(horzcat(x{selection}, ' = datestr(DateT);')); 
        end
        
        function handles = generateClockFcn(GUIobj, handles)
            
            HourVec = num2cell(0:23);
            MinVec = num2cell(0:59);
            SecVec = num2cell(0:59);
            CentiSecVec = num2cell(0:99);
            
            xpos = 10;
            xscale = 90;
            width = 40;
            height = 30;
            ypos = 40;
            
            popup1 = uicontrol('Style', 'popup',...
                'String', HourVec,...
                'Position', [xpos ypos width height]);
            
            popup2 = uicontrol('Style', 'popup',...
                'String', MinVec,...
                'Position', [xpos + xscale ypos  width height]);
            
            popup3 = uicontrol('Style', 'popup',...
                'String', SecVec,...
                'Position', [xpos + (xscale*2) ypos  width height]);
            
            popup4 = uicontrol('Style', 'popup',...
                'String', CentiSecVec,...
                'Position', [xpos + (xscale*3) ypos  width height]);
            
            
            btn = uicontrol('Style', 'pushbutton', 'String', 'Confirm',...
                'Position', [10 10 50 30],...
                'Callback', {@GUIobj.time_button_buttondownFcn_callback});
            
            txt = uicontrol('Style','text',...
                'Position',[xpos+45 ypos+5 30 20],...
                'String','hrs ');
            
            txt = uicontrol('Style','text',...
                'Position',[xpos + xscale + 45 ypos+5 30 20],...
                'String','min ');
            
            txt = uicontrol('Style','text',...
                'Position',[xpos + (xscale*2)+45 ypos+5 30 20],...
                'String','secs');
            
            txt = uicontrol('Style','text',...
                'Position',[xpos + (xscale*3)+45 ypos+5 30 20],...
                'String','ms  ');
            
        end
        
    end
    
end 