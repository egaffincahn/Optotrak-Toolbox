%#ok<*NOCOM,*TRYNC>
try, Screen('CloseAll'),      end
try, OptoDenit,               end
try, PsychPortAudio('Close'), end
try, FlushEvents,             end
try, delete(h),               end
try, fclose('all');           end
try, ShowCursor;              end
try, rethrow(me),             end
