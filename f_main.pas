unit f_main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, FileUtil, Forms, Controls, Graphics, Dialogs, ComCtrls,
  StdCtrls, Grids, Menus, PrintersDlgs, TAGraph, Printers, u_data,
  u_loader, u_mapper, f_about, f_zvv, u_calc2cont;

type

  { TMainForm }

  TMainForm = class(TForm)
    alg_select: TComboBox;
    cs_average: TComboBox;
    cs_splitter: TComboBox;
    cs_charset: TComboBox;
    cs_benz: TComboBox;
    cs_sft: TComboBox;
    cs_lft: TComboBox;
    cs_giri: TComboBox;
    ds_chart: TChart;
    clear_button: TButton;
    ds_b_text: TEdit;
    ds_k_text: TEdit;
    file_gas: TStaticText;
    file_cont: TStaticText;
    Label13: TLabel;
    Label14: TLabel;
    Label15: TLabel;
    Label16: TLabel;
    go_button: TButton;
    dm_vprysk: TEdit;
    dp_vprysk: TEdit;
    dm_oboroty: TEdit;
    dp_oboroty: TEdit;
    dm_map: TEdit;
    dp_map: TEdit;
    file_button: TButton;
    alg_makros_group: TGroupBox;
    graph_group: TGroupBox;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    Label17: TLabel;
    Label18: TLabel;
    Label19: TLabel;
    Label20: TLabel;
    Label21: TLabel;
    Label22: TLabel;
    Label7: TLabel;
    Label8: TLabel;
    Label9: TLabel;
    flm_add: TMenuItem;
    flm_del: TMenuItem;
    flm_clear: TMenuItem;
    em_text: TMenuItem;
    em_print: TMenuItem;
    em_printc: TMenuItem;
    em_about: TMenuItem;
    ob_min: TEdit;
    ob_max: TEdit;
    ob_step: TEdit;
    files_list: TListBox;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    l_vprysk: TMemo;
    fl_menu: TPopupMenu;
    fl_open: TOpenDialog;
    exp_menu: TPopupMenu;
    PrintDialog1: TPrintDialog;
    SaveDialog1: TSaveDialog;
    s_vprysk: TComboBox;
    Label1: TLabel;
    Label2: TLabel;
    logtext: TMemo;
    PageControl1: TPageControl;
    g_benz: TStringGrid;
    g_gaz: TStringGrid;
    g_kor: TStringGrid;
    t_csetup: TTabSheet;
    t_setup: TTabSheet;
    t_kmap: TTabSheet;
    t_benzmap: TTabSheet;
    t_gazmap: TTabSheet;
    procedure alg_selectChange(Sender: TObject);
    procedure clear_buttonClick(Sender: TObject);
    procedure cs_charsetChange(Sender: TObject);
    procedure cs_splitterChange(Sender: TObject);
    procedure em_aboutClick(Sender: TObject);
    procedure em_printcClick(Sender: TObject);
    procedure em_printClick(Sender: TObject);
    procedure em_textClick(Sender: TObject);
    procedure files_listKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure files_listMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure file_buttonClick(Sender: TObject);
    procedure flm_addClick(Sender: TObject);
    procedure flm_clearClick(Sender: TObject);
    procedure flm_delClick(Sender: TObject);
    procedure FormHide(Sender: TObject);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure go_buttonClick(Sender: TObject);
    procedure g_korDrawCell(Sender: TObject; aCol, aRow: Integer; aRect: TRect;
      aState: TGridDrawState);
    procedure g_korMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer
      );
    procedure g_korMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure s_vpryskChange(Sender: TObject);
    procedure t_csetupResize(Sender: TObject);
    procedure t_setupResize(Sender: TObject);
  private
    { private declarations }
    function SetCellColor(CStr: string): TColor;
    procedure PrintTable(Colored: boolean);
  public
    { public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

procedure TMainForm.FormResize(Sender: TObject);
begin
 PageControl1.Height:=round(MainForm.ClientHeight*0.775);
 logtext.Height:=MainForm.ClientHeight - PageControl1.Height - 1;
end;

procedure TMainForm.flm_clearClick(Sender: TObject);
begin
 clear_button.Click;
end;

procedure TMainForm.flm_addClick(Sender: TObject);
begin
 file_button.Click;
end;

procedure TMainForm.files_listMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 if (Button = mbRight) then fl_menu.PopUp;
end;

procedure TMainForm.file_buttonClick(Sender: TObject);
var
 n: integer;
begin
 if not fl_open.Execute or ( fl_open.Files.Count < 1 ) then exit;
 if (alg_select.ItemIndex<2) then
  begin
   for n:=0 to (fl_open.Files.Count-1) do
    if fileexists(fl_open.Files.Strings[n]) then
     files_list.Items.Add(fl_open.Files.Strings[n]);
   exit;
  end;
 if (alg_select.ItemIndex=3) then
  begin
   for n:=0 to (fl_open.Files.Count-1) do Check_2c_file(fl_open.Files.Strings[n]);
   exit;
  end;
 if (alg_select.ItemIndex=2) then CheckContFile(fl_open.Files.Strings[0])
end;

procedure TMainForm.files_listKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
 if (Key = 46) then flm_del.Click;
 if (Key = 45) then flm_add.Click;
end;

procedure TMainForm.em_aboutClick(Sender: TObject);
begin
 AboutForm.Show;
end;

procedure TMainForm.alg_selectChange(Sender: TObject);
begin
 graph_group.Visible:=False;
 files_list.Visible:=True;
 file_gas.Visible:=False;
 file_cont.Visible:=False;
 ds_k_text.Visible:=False;
 ds_b_text.Visible:=False;
 Label15.Visible:=False;
 Label16.Visible:=False;
 cs_giri.Enabled:=False;
 cs_benz.Enabled:=False;
 cs_sft.Enabled:=False;
 cs_lft.Enabled:=False;
 cs_splitter.Enabled:=False;
 if (alg_select.ItemIndex=0) then
 begin
  dm_map.Enabled:=True;
  dp_map.Enabled:=True;
  dp_vprysk.Enabled:=True;
  dm_vprysk.Enabled:=True;
  PageControl1.Pages[4].Visible:=False;
  //t_benzmap.Visible:=True;
  //t_gazmap.Visible:=True;
  //t_csetup.Visible:=False;
 end else if (alg_select.ItemIndex=1) then
  begin
   dm_map.Enabled:=False;
   dp_map.Enabled:=False;
   dp_vprysk.Enabled:=True;
   dm_vprysk.Enabled:=True;
   //t_benzmap.Visible:=True;
   //t_gazmap.Visible:=True;
   //t_csetup.Visible:=False;
  end else
   if (alg_select.ItemIndex=2) then
    begin
     dm_map.Enabled:=False;
     dp_map.Enabled:=False;
     dp_vprysk.Enabled:=True;
     dm_vprysk.Enabled:=True;
     //t_benzmap.Visible:=False;
     //t_gazmap.Visible:=False;
     //t_csetup.Visible:=True;
     files_list.Visible:=False;
     file_cont.Visible:=True;
     cs_giri.Enabled:=True;
     cs_benz.Enabled:=True;
     cs_sft.Enabled:=True;
     cs_lft.Enabled:=True;
     cs_splitter.Enabled:=True;
    end else
     if (alg_select.ItemIndex=3) then
      begin
       dm_map.Enabled:=False;
       dp_map.Enabled:=False;
       dp_vprysk.Enabled:=True;
       dm_vprysk.Enabled:=True;
       graph_group.Visible:=True;
       files_list.Visible:=False;
       file_gas.Visible:=True;
       file_cont.Visible:=True;
       ds_k_text.Visible:=True;
       ds_b_text.Visible:=True;
       Label15.Visible:=True;
       Label16.Visible:=True;
       //t_benzmap.Visible:=False;
       //t_gazmap.Visible:=False;
       //t_csetup.Visible:=False;
      end;
end;

procedure TMainForm.clear_buttonClick(Sender: TObject);
begin
 files_list.Items.Clear;
 file_gas.Caption:='Файл данных газового контроллера не открыт';
 file_cont.Caption:='Файл данных контроллера двигателя не открыт';
 ds_k_text.Text:='1';
 ds_b_text.Text:='0';
 ds_chart.Series.Clear;
end;

procedure TMainForm.cs_charsetChange(Sender: TObject);
begin
 if fileexists(file_cont.Caption) then CheckContFile(file_cont.Caption);
end;

procedure TMainForm.cs_splitterChange(Sender: TObject);
begin
 if fileexists(file_cont.Caption) then CheckContFile(file_cont.Caption);
end;

procedure TMainForm.em_printcClick(Sender: TObject);
begin
 PrintTable(True);
end;

procedure TMainForm.em_printClick(Sender: TObject);
begin
 PrintTable(False);
end;

procedure TMainForm.em_textClick(Sender: TObject);
var
 f: textfile;
 x,y: integer;
 s: string;
begin
 if not SaveDialog1.Execute then exit;
 if fileexists(SaveDialog1.FileName) then
  if (MessageDlg('Сохранение данных', 'Файл существует. Переписать?',
   mtCustom, mbOkCancel, 0 ) = mrCancel) then exit;
 try
  assignfile(f,SaveDialog1.FileName);
  rewrite(f);
  writeln(f, 'Данные карты изменений от '+FormatDateTime('DD.MM.YYYY hh:nn',Now));
  for y:=0 to g_kor.RowCount-1 do
   begin
    if (y=0) then s:='Впр\Об' else s:=g_kor.Cells[0,y];
    for x:=1 to g_kor.ColCount-1 do
     s:=s+chr(9)+g_kor.Cells[x,y];
    writeln(f,s);
   end;
 finally
  closefile(f);
  WriteLog('Данные сохранены в текстовый файл '+SaveDialog1.FileName);
 end;
end;

procedure TMainForm.flm_delClick(Sender: TObject);
begin
 if (files_list.ItemIndex < 0) then exit;
 files_list.Items.Delete(files_list.ItemIndex);
end;

procedure TMainForm.FormHide(Sender: TObject);
begin
 SetupData(False);
 SaveCfg;
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
 t_setup.Caption:='Настройки';
 t_kmap.Caption:='Карта изменений';
 t_benzmap.Caption:='Карта бензина';
 t_gazmap.Caption:='Карта газа';
 t_csetup.Caption:='Настройки данных';
 t_setup.Show;
 Logtext.Lines.Clear;
 Logtext.Lines.Add('GBO Mapper '+GBOM_VERSION + ' (сборка ' + GBOM_BUILD_DATE + ')');
 clear_button.Click;
 s_vprysk.Style:=csDropDownList;
 s_vprysk.Items.Clear;
 s_vprysk.Items.Add('Вручную');
 s_vprysk.Items.Add('OMVL, Lovato');
 s_vprysk.Items.Add('2-10 шаг 0,5');
 s_vprysk.Items.Add('2-18 шаг 0,5');
 s_vprysk.ItemIndex:=2;
 ob_min.Text:='500';
 ob_max.Text:='4500';
 ob_step.Text:='500';
 dm_vprysk.Text:='0,05';
 dp_vprysk.Text:='0,05';
 dm_oboroty.Text:='100';
 dp_oboroty.Text:='100';
 dm_map.Text:='0,01';
 dp_map.Text:='0,01';
 go_button.Caption:='СТАРТ';
 file_button.Caption:='Открыть';
 clear_button.Caption:='Очистить';
 alg_makros_group.Caption:='Данные для расчёта';
 graph_group.Caption:='Графики оборотов двигателя';
 alg_select.Style:=csDropDownList;
 alg_select.Clear;
 alg_select.Items.Add('среднему времени впрыска (оригинальный макрос)');
 alg_select.Items.Add('среднему значению MAP');
 alg_select.Items.Add('данным коррекции контроллера двигателя');
 alg_select.Items.Add('данным двух контроллеров');
 alg_select.ItemIndex:=0;
 {$IFDEF WINDOWS}
 cs_giri.Style:=csDropDownList;
 cs_benz.Style:=csDropDownList;
 cs_sft.Style:=csDropDownList;
 cs_lft.Style:=csDropDownList;
 cs_splitter.Style:=csDropDownList;
 cs_charset.Style:=csDropDownList;
 cs_average.Style:=csDropDownList;
 {$ENDIF}
 cs_giri.Clear;
 cs_benz.Clear;
 cs_sft.Clear;
 cs_lft.Clear;
 cs_splitter.Clear;
 cs_charset.Clear;
 cs_average.Clear;
 cs_charset.Items.Add('CP1251');
 cs_charset.Items.Add('UTF8');
 cs_charset.ItemIndex:=0;
 cs_splitter.Items.Add('Автоматически');
 cs_splitter.Items.Add('Точка с запятой');
 cs_splitter.Items.Add('Табуляция');
 cs_splitter.Items.Add('Запятая');
 cs_splitter.ItemIndex:=0;
 cs_average.Items.Add('Среднее арифметическое');
 cs_average.Items.Add('Медиана');
 cs_average.ItemIndex:=0;
 NoBenz:=False;
 g_kor.Cells[0,0]:='[Меню]';
 ProcessError:=False;
 Label7.Left:=alg_select.Left - Label7.Width - 5;
 Label7.Top:=(alg_select.Height - Label7.Height) div 2;
 ds_k_text.Text:='1';
 ds_b_text.Text:='0';
 Application.ProcessMessages;
 FormResize(Sender);
 alg_SelectChange(Sender);
 LoadCfg;
 s_vpryskChange(Sender);
end;

procedure TMainForm.go_buttonClick(Sender: TObject);
var
 dt: TDateTime;
begin
 ProcessError:=False;
 logtext.Lines.Clear;
 WriteLog('GBOMapper '+GBOM_VERSION + ' (сборка ' + GBOM_BUILD_DATE + ')');
 dt:=Now;
 WriteLog('Начало: '+FormatDateTime('hh:nn.ss',dt));
 SetupData(True);
 if ProcessError then exit;
 if (alg_select.ItemIndex = 2) then calc_econt else
  if (alg_select.ItemIndex = 3) then calc_2cont else
   begin
    LoadData;
    if ProcessError then exit;
    if (alg_select.ItemIndex = 0) then calc_makros else calc_av_map;
   end;
 if ProcessError then exit;
 WriteLog('Завершение: '+FormatDateTime('hh:nn.ss',Now)+' ( '+
  FormatDateTime('nn.ss',(Now+(1/86400)-dt))+' )');
end;

procedure TMainForm.g_korDrawCell(Sender: TObject; aCol, aRow: Integer;
  aRect: TRect; aState: TGridDrawState);
var
 x,y: integer;
begin
 if (aCol = 0) or (aRow = 0) then exit;
 if (g_kor.Cells[aCol,aRow] = '') then exit;
 g_kor.Canvas.Brush.Color:=SetCellColor(g_kor.Cells[aCol,aRow]);
 g_kor.Canvas.FillRect(aRect);
 y:=g_kor.Canvas.TextHeight(g_kor.Cells[aCol,aRow]) div 2;
 x:=g_kor.Canvas.TextWidth(g_kor.Cells[aCol,aRow]) div 2;
 x:=(aRect.Right - aRect.Left) div 2 - x + aRect.Left;
 y:=(aRect.Bottom - aRect.Top) div 2 - y + aRect.Top;
 g_kor.Canvas.TextOut(x,y,g_kor.Cells[aCol,aRow]);
end;

procedure TMainForm.g_korMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
 if (x <= g_kor.ColWidths[0]) and (y <= g_kor.RowHeights[0]) then
  g_kor.Cursor:=crHandPoint else
   g_kor.Cursor:=crDefault;
end;

procedure TMainForm.g_korMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
 if (x > g_kor.ColWidths[0]) or (y > g_kor.RowHeights[0]) then exit;
 exp_menu.PopUp;
end;

procedure TMainForm.s_vpryskChange(Sender: TObject);
var
 n: integer;
begin
 if (s_vprysk.ItemIndex = 0) then
  begin
   l_vprysk.ReadOnly:=False;
   ZVVForm.Show;
  end else
   l_vprysk.ReadOnly:=True;
 if (s_vprysk.ItemIndex = 1) then
  begin
   l_vprysk.Lines.Clear;
   l_vprysk.Lines.Add('2,0');
   l_vprysk.Lines.Add('2,5');
   l_vprysk.Lines.Add('3,0');
   l_vprysk.Lines.Add('3,5');
   l_vprysk.Lines.Add('4,5');
   l_vprysk.Lines.Add('6,0');
   l_vprysk.Lines.Add('8,0');
   l_vprysk.Lines.Add('10,0');
   l_vprysk.Lines.Add('12,0');
   l_vprysk.Lines.Add('14,0');
   l_vprysk.Lines.Add('16,0');
   l_vprysk.Lines.Add('18,0');
  end;
 if (s_vprysk.ItemIndex = 2) then
  begin
   l_vprysk.Lines.Clear;
   for n:=0 to 16 do
    l_vprysk.Lines.Add(FloatToStrF(n/2+2 ,ffFixed, 2, 1));
  end;
 if (s_vprysk.ItemIndex = 3) then
  begin
   l_vprysk.Lines.Clear;
   for n:=0 to 32 do
    l_vprysk.Lines.Add(FloatToStrF(n/2+2 ,ffFixed, 2, 1));
  end;
 l_vprysk.SelStart:=0;
 l_vprysk.SelLength:=0;
end;

procedure TMainForm.t_csetupResize(Sender: TObject);
begin
 cs_giri.Width:=t_csetup.ClientWidth-1;
 cs_benz.Width:=cs_giri.Width;
 cs_sft.Width:=cs_giri.Width;
 cs_lft.Width:=cs_giri.Width;
end;

procedure TMainForm.t_setupResize(Sender: TObject);
var
 bgv: boolean;
begin
 files_list.Width := t_setup.ClientWidth - file_button.Width;
 file_gas.Width := files_list.Width;
 file_cont.Width := files_list.Width;
 file_button.Left:=t_setup.ClientWidth - file_button.Width;
 clear_button.Left:=file_button.Left;
 alg_select.Width:=t_setup.ClientWidth-alg_select.Left;
 l_vprysk.Top := s_vprysk.Top + s_vprysk.Height + 1;
 l_vprysk.Height := t_setup.Height - l_vprysk.Top - 1;
 go_button.Left:=t_setup.ClientWidth - go_button.Width - 1;
 if graph_group.Visible then bgv:=True else bgv:=False;
 if not bgv then
  begin
   graph_group.Visible:=True;
   Application.ProcessMessages;
  end;
 graph_group.Width:=t_setup.Width - graph_group.Left;
 graph_group.Height:=t_setup.Height - graph_group.Top;
 if not bgv then graph_group.Visible:=False;
end;

function TMainForm.SetCellColor(CStr: string): TColor;
var
 r,g,b: byte;
 c: single;
begin
 c:=todouble(CStr);
 if (c = 0) then
  begin
   Result:=clWhite;
   exit;
  end;
 if (c < -100) then c:=-100;
 if (c > 100) then c:=100;
 if (c<0) then
  begin
   r:=255+round(c*2.55);
   g:=255+round(c*1.2);
   b:=255;
  end else
   begin
    r:=255;
    g:=255-round(c*1.2);
    b:=255-round(c*2.55);
   end;
 Result:=RGBtoColor(r,g,b);
end;

procedure TMainForm.PrintTable(Colored: boolean);
var
 YPos, LineHeight, CellWidth, VerticalMargin: Integer;
 x,y: integer;
 R: TRect;
begin
 if (g_kor.ColCount < 3) and (g_kor.RowCount < 3) then
  begin
   MessageDlg('Ошибка','Нет данных для печати!' ,mtError, [mbOk],0 );
   WriteLog('Нет данных для печати!');
   exit;
  end;
 if not PrintDialog1.Execute then exit;
 if Colored then WriteLog('Печать карты изменений в цвете...')
  else WriteLog('Печать карты изменений ч/б...');
 with Printer do
 try
  BeginDoc;
  WriteLog('Подготовка к печати таблицы...');
  Application.ProcessMessages;
  Canvas.Font.Name := 'Times New Roman';
  Canvas.Font.Size := 10;
  Canvas.Font.Color := clBlack;
  Canvas.Font.Bold := True;
  LineHeight := Round(1.1 * Abs(Canvas.TextHeight('I')));
  VerticalMargin := Round(1.1 * LineHeight);
  CellWidth:=(PageWidth-10) div g_kor.ColCount;
  Canvas.TextOut(100, 0, 'GBOMap '+GBOM_VERSION+
   ' Карта изменений от '+FormatDateTime('DD.MM.YYYY hh:nn',Now));
  YPos := VerticalMargin;
  Canvas.Font.Bold := False;
  Canvas.Line(5, YPos, PageWidth-10, YPos);
  for y:=0 to g_kor.RowCount-1 do
   begin
    for x:=0 to g_kor.ColCount-1 do
     begin
      R.Left:=x*CellWidth+round(0.1*LineHeight)+5;
      R.Top:=YPos+round(0.2*LineHeight);
      R.Bottom:=R.Top+LineHeight;
      R.Right:=(x+1)*CellWidth-round(0.1*LineHeight);
      if Colored and (x>0) and (y>0) then
       begin
        Canvas.Brush.Color:=SetCellColor(g_kor.Cells[x,y]);
        Canvas.FillRect(x*CellWidth+5,YPos,(x+1)*CellWidth+5,Ypos+VerticalMargin);
       end;
      if (x=0) and (y=0) then
       Canvas.TextRect(R,R.Left,R.Top,'Впр.\Об.')
        else Canvas.TextRect(R,R.Left,R.Top,g_kor.Cells[x,y]);
      Canvas.Line(x*CellWidth+5, YPos, x*CellWidth+5, YPos+VerticalMargin);
     end;
    Canvas.Line((x+1)*CellWidth+5, YPos, (x+1)*CellWidth+5, YPos+VerticalMargin);
    YPos:=YPos+VerticalMargin;
    Canvas.Line(5, YPos, PageWidth-10, YPos);
    if (YPos > PageHeight-VerticalMargin) then
     begin
      NewPage;
      YPos:=5;
      Canvas.Line(5, YPos, PageWidth-10, YPos);
     end;
   end;
  Writelog('Печать...');
  Application.ProcessMessages;
 finally
  EndDoc;
 end;
 Writelog('Готово.');
end;

end.

