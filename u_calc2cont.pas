unit u_calc2cont;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Forms, TAGraph, TASeries, LazUTF8, u_data, u_loader, u_mapper;

var
 //Коэффициенты для данных контроллера двигателя
 dsk: single;
 dsb: integer;

//Процедура запуска расчёта по данным двух контроллеров
procedure calc_2cont;
//Проверка файла данных
procedure Check_2c_file(FileName: string);
//Загрузка данных
procedure ec_load_data;
//Автоматический подбор коэффициентов
procedure ec_auto_sync;
//Вывод графиков оборотов
procedure ec_build_graph;
//Расчёт таблицы коррекций
procedure ec_calc;

implementation

uses f_main;

procedure Check_2c_file(FileName: string);
var
 b: byte;
 s: string;
begin
 b:=ReadFileHeader(UTF8toSys(FileName));
 SplitString(FileName,DIR_SPLITTER);
 s:=SplitA[SplitN-1];
 if (b=0) then
  begin
   Writelog('Файл не поддерживается: '+s);
   exit;
  end;
 if (b=1) then
  begin
   Writelog('Выбран файл данных газового контроллера: '+s);
   MainForm.file_gas.Caption:=FileName;
   exit;
  end;
 Writelog('Выбран файл данных контроллера двигателя: '+s);
 MainForm.file_cont.Caption:=FileName;
end;

procedure ec_load_data;
begin
 NoBenz:=True;
 if (ReadFileHeader(UTF8toSys(MainForm.file_gas.Caption)) <> 1) then
  begin
   ErrorMessage('Ошибка файла данных газового контроллера!');
   exit;
  end;
 ReadFile;
 if (ReadFileHeader(UTF8toSys(MainForm.file_cont.Caption)) <> 2) then
  begin
   ErrorMessage('Ошибка файла данных контроллера двигателя!');
   exit;
  end;
 ReadFile;
 WriteLog('Записей газового контроллера: '+inttostr(GPoints));
 WriteLog('Записей контроллера двигателя: '+inttostr(CPoints));
end;

procedure ec_auto_sync;
var
 n,i,x: integer;
 sum,sk,rk,rs,ck: single;
 rb,cb: integer;
begin
 rb:=toint(MainForm.ds_b_text.Text);
 rk:=toDouble(MainForm.ds_k_text.Text);
 if (rb<>0) or (rk<0.99) or (rk>1.01) then exit;
 if (CPoints<50) or (GPoints<110) then
  begin
   ErrorMessage('Недостаточно данных!');
   exit;
  end;
 WriteLog('Подбор коэффициентов синхронизации данных. Подождите...');
 sk:=GPoints / CPoints;
 rk:=sk; rb:=-50; rs:=999999;
 for cb:=-50 to 50 do
  for x:=-50 to 50 do
   begin
    ck:=x/100 + sk;
    Sum:=0;
    for n:=0 to CPoints-1 do
     begin
      i:=round(ck*n) + cb;
      if (i<0) then i:=0;
      if (i>GPoints-1) then i:=GPoints-1;
      Sum:=Sum + abs(CGiri[n]-GGiri[i]);
     end;
    Sum:=Sum / CPoints;
    if (sum<rs) then begin rs:=sum; rk:=ck; rb:=cb; end;
   end;
 MainForm.ds_b_text.Text:=inttostr(rb);
 MainForm.ds_k_text.Text:=FloatToStrF(rk,ffFixed, 1, 2);
end;

procedure ec_build_graph;
var
 BSer, GSer: TLineSeries;
 n,i: integer;
 rs: single;
begin
 MainForm.ds_chart.Series.Clear;
 dsk:=toDouble(MainForm.ds_k_text.Text);
 dsb:=toInt(MainForm.ds_b_text.Text);
 BSer:=TLineSeries.Create(MainForm.ds_chart);
 GSer:=TLineSeries.Create(MainForm.ds_chart);
 BSer.SeriesColor:=clRed;
 GSer.SeriesColor:=clBlue;
 MainForm.ds_chart.AddSeries(BSer);
 MainForm.ds_chart.AddSeries(GSer);
 rs:=0;
 for n:=0 to CPoints-1 do
  begin
   i:=round(dsk*n)+dsb;
   if (i<0) then i:=0;
   if (i>GPoints-1) then i:=GPoints-1;
   BSer.AddXY(n,CGiri[n],'',clRed);
   GSer.AddXY(n,GGiri[i],'',clBlue);
   rs:=rs + abs(CGiri[n]-GGiri[i]);
  end;
 rs:=rs / CPoints;
 Writelog('Коэффициенты: K = '+FloatToStrF(dsk,ffFixed, 1, 2) + '   B = ' +
  inttostr(dsb)+'.   Средняя разность оборотов: '+FloatToStrF(rs,ffFixed, 1, 2));
 if (rs>200) then if (rs>dom) or (rs>dop) then ErrorMessage('Данные не синхронизированы!');
end;

procedure ec_calc;
var
 x,y,i,n:integer;
 sum, gm: single;
begin
 MainForm.t_kmap.Show;
 for x:=0 to po_count-1 do
  for y:=0 to pv_count-1 do
   begin
    Application.ProcessMessages;
    mid_clear;
    for n:=0 to CPoints-1 do
     begin
      i:=round(dsk*n)+dsb;
      if (i<0) then i:=0;
      if (i>GPoints-1) then i:=GPoints-1;
      if (GBenz[i] >= VP[y]-dvm) and (GBenz[i] <= VP[y]+dvp) and
       (CGiri[n] >= OB[x]-dom) and (CGiri[n] <= OB[x]+dop) then
        mid_add(CLT[n]+CST[n]);
     end;

    sum:=mid_calc;

    if (sum<>0) then
    begin
      if (MainForm.cbMultGazMap.Enabled and MainForm.cbMultGazMap.Checked) then
      begin
        gm := toDouble(MainForm.g_gaz.Cells[x+1, y+1]);
        if (gm > 0) then
          sum := gm + (gm / 100 * sum);
      end;
      MainForm.g_kor.Cells[x+1,y+1] := FloatToStrF(sum,ffFixed, 1, 1)
    end
    else
      MainForm.g_kor.Cells[x+1,y+1] := '-';
   end;
end;

procedure calc_2cont;
begin
 GPoints:=0;
 BPoints:=0;
 CPoints:=0;
 dsk:=toDouble(MainForm.ds_k_text.Text);
 WriteLog('Расчёт по данным двух контроллеров...');
 if (dsk<=0) then ErrorMessage('Задан некорректный коэффициент "К" !');
 if ProcessError then exit;
 ec_load_data;
 if ProcessError then exit;
 ec_auto_sync;
 ec_build_graph;
 if ProcessError then exit;
 ec_calc;
end;

end.

