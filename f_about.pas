unit f_about;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ExtCtrls,
  StdCtrls, u_data;

type

  { TAboutForm }

  TAboutForm = class(TForm)
    Image1: TImage;
    Image2: TImage;
    Label1: TLabel;
    Memo1: TMemo;
    Memo2: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure FormDeactivate(Sender: TObject);
  private
    { private declarations }
  public
    { public declarations }
  end;

var
  AboutForm: TAboutForm;

implementation

{$R *.lfm}

{ TAboutForm }

procedure TAboutForm.FormDeactivate(Sender: TObject);
begin
 AboutForm.Hide;
end;

procedure TAboutForm.FormCreate(Sender: TObject);
begin
 Memo1.Clear;
 Memo2.Clear;
 AboutForm.Caption:='GBO Mapper - о программе';
 Memo1.Lines.Add('Версия: '+GBOM_VERSION);
 Memo1.Lines.Add('Дата сборки: '+GBOM_BUILD_DATE);
 Memo1.Lines.Add('Copyleft: Шимигон Алексей (shimigon@yandex.ru)');
 Memo1.Lines.Add('Основано на макросе для настройки ГБО 4 поколения:');
 Memo1.Lines.Add('http://gazmap.ru/stati/regulirovka-gbo-lovato-i-omvl');
 Memo2.Lines.Add('Программа предназначена для расчёта карты коэффициентов газовых контроллеров.');
 Memo2.Lines.Add('Более подробная информация об использовании программы в файле readme.txt');
end;

end.

