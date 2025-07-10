unit f_zvv;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, StdCtrls,
  u_data;

type

  { TZVVForm }

  TZVVForm = class(TForm)
    Button1: TButton;
    Button2: TButton;
    Edit1: TEdit;
    Edit2: TEdit;
    Edit3: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  ZVVForm: TZVVForm;
  ZVVForm_Mode: integer;
  ZVVForm_Min: integer = 500;
  ZVVForm_Max: integer = 4500;
  ZVVForm_Step: integer = 500;

implementation

uses f_main;

{$R *.lfm}

{ TZVVForm }

procedure TZVVForm.FormDeactivate(Sender: TObject);
begin
 ZVVForm.Hide;
end;

procedure TZVVForm.FormShow(Sender: TObject);
begin
  if ZVVForm_Mode = 0 then
  begin
    Caption := 'Время впрыска';
    Edit1.Text:='2';
    Edit2.Text:='14';
    Edit3.Text:='0,5';
  end
  else
  begin
    Caption := 'Обороты';
    Edit1.Text:=IntToStr(ZVVForm_Min);
    Edit2.Text:=IntToStr(ZVVForm_Max);
    Edit3.Text:=IntToStr(ZVVForm_Step);
  end;
end;

procedure TZVVForm.Button2Click(Sender: TObject);
begin
 ZVVForm.Hide;
end;

procedure TZVVForm.Button1Click(Sender: TObject);
var
 i,m,s,c: single;
begin
  i:=toDouble(Edit1.Caption);
  m:=toDouble(Edit2.Caption);
  s:=toDouble(Edit3.Caption);
  if (i>=m) or (i<=0) or (s<=0) then
  begin
   MessageDlg('Ошибка','Ошибка исходных данных!',mtError, [mbOk],0 );
   exit;
  end;  
  if ZVVForm_Mode=0 then
  begin
    if (s>10) then s:=10;
    if (i>20) then i:=20;
    if (m>100) then m:=100;
    Edit1.Text:=FloatToStrF(i ,ffFixed, 2, 1);
    Edit2.Text:=FloatToStrF(m ,ffFixed, 2, 1);
    Edit3.Text:=FloatToStrF(s ,ffFixed, 2, 1);
    c:=i;

    MainForm.l_vprysk.Clear;

    while (c<=m) do
    begin
      MainForm.l_vprysk.Lines.Add(FloatToStrF(c ,ffFixed, 2, 1));
      c:=c+s;
    end;
  end
  else
  begin
    Edit1.Text:=FloatToStrF(i ,ffFixed, 0, 0);
    Edit2.Text:=FloatToStrF(m ,ffFixed, 0, 0);
    Edit3.Text:=FloatToStrF(s ,ffFixed, 0, 0);
    c:=i;

    MainForm.l_oborot.Clear;

    while (c<=m) do
    begin
      MainForm.l_oborot.Lines.Add(FloatToStrF(c ,ffFixed, 0, 0));
      c:=c+s;
    end;
  end;
  ZVVForm.Hide;
end;

end.

