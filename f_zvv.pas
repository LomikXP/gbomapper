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
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  ZVVForm: TZVVForm;

implementation

uses f_main;

{$R *.lfm}

{ TZVVForm }

procedure TZVVForm.FormCreate(Sender: TObject);
begin
 Edit1.Text:='2';
 Edit2.Text:='14';
 Edit3.Text:='0,5';
end;

procedure TZVVForm.FormDeactivate(Sender: TObject);
begin
 ZVVForm.Hide;
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
 ZVVForm.Hide;
end;

end.

