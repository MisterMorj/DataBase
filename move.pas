unit Move;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, windows;
procedure my_click;

implementation

procedure my_click;
begin
  mouse_event(MOUSEEVENTF_LEFTDOWN, 0, 0, 0, 0);
  mouse_event(MOUSEEVENTF_LEFTUP, 0, 0, 0, 0);
end;



end.

