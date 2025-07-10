unit u_mapper;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Forms, u_data, u_loader;

procedure calc_makros;
procedure calc_av_map;
procedure calc_econt;
procedure mid_clear; //Очистка счётчика среднего значения
procedure mid_add(val: single); //Добавление цифры для расчёта среднего
function  mid_calc: single; //Расчёт среднего значения (среднее арифметическое или медиана в зависимости от настройки)

implementation

uses f_main;

var
 mida: array [0..MAX_POINTS] of single;
 midc: integer;

procedure calc_makros;
var
 n,x,y: integer;
 Sum, r: double;
begin
 Writelog('Расчёт по оригинальному макросу...');
 Writelog('Дельта впрыска: +'+FloatToStrF(dvp,ffFixed, 1, 3)+' -'+
  FloatToStrF(dvm,ffFixed, 1, 3));
 Writelog('Дельта оборотов: +'+inttostr(dop)+' -'+inttostr(dom));
 Writelog('Дельта MAP: +'+FloatToStrF(dmp,ffFixed, 1, 3)+' -'+
  FloatToStrF(dmm,ffFixed, 1, 3));
 MainForm.t_kmap.Show;
 for x:=0 to po_count-1 do
  for y:=0 to pv_count-1 do
   begin
    Application.ProcessMessages;
    mid_clear;
    for n:=0 to BPoints-1 do
     begin
      if (BBenz[n] >= VP[y]-dvm) and (BBenz[n] <= VP[y]+dvp) and
       (BGiri[n] >= OB[x]-dom) and (BGiri[n] <= OB[x]+dop) then
        mid_add(BMap[n]);
     end;
    r := mid_calc;
    if (midc>0) then MainForm.g_benz.Cells[x+1,y+1]:=FloatToStrF(r ,ffFixed, 2, 3)
     else MainForm.g_benz.Cells[x+1,y+1]:='-';
    mid_clear;
    //Округляем результат в лучшего соответствия оригинальному макросу
    r:=round(r*100) / 100;
    if (MainForm.g_benz.Cells[x+1,y+1] <> '-') then
     for n:=0 to GPoints-1 do
      if (GMap[n] >= r-dmm-0.001) and (GMap[n] <= r+dmp+0.001) and
       (GGiri[n] >= OB[x]-dom) and (GGiri[n] <= OB[x]+dop) then
        if (GBenz[n] > 0) then
         mid_add(GBenz[n]);
    r:=mid_calc;
    if (midc>0) then MainForm.g_gaz.Cells[x+1,y+1]:=FloatToStrF(r ,ffFixed, 2, 3)
     else MainForm.g_gaz.Cells[x+1,y+1]:='-';
    Sum:=-(VP[y]-r)/VP[y]*100;
    if (MainForm.g_benz.Cells[x+1,y+1]<>'-') and
     (MainForm.g_gaz.Cells[x+1,y+1]<>'-') then
      MainForm.g_kor.Cells[x+1,y+1]:=FloatToStrF(Sum ,ffFixed, 2, 2)
       else MainForm.g_kor.Cells[x+1,y+1]:='-';
   end;
end;

procedure calc_av_map;
var
 n,x,y: integer;
 rb, rg, Sum: double;
begin
 Writelog('Расчёт по средним значениям МАР...');
 Writelog('Дельта впрыска: +'+FloatToStrF(dvp,ffFixed, 1, 3)+' -'+
  FloatToStrF(dvm,ffFixed, 1, 3));
 Writelog('Дельта оборотов: +'+inttostr(dop)+' -'+inttostr(dom));
 MainForm.t_kmap.Show;
 for x:=0 to po_count-1 do
  for y:=0 to pv_count-1 do
   begin
    mid_clear;
    Application.ProcessMessages;
    for n:=0 to BPoints-1 do
     begin
      if (BBenz[n] >= VP[y]-dvm) and (BBenz[n] <= VP[y]+dvp) and
       (BGiri[n] >= OB[x]-dom) and (BGiri[n] <= OB[x]+dop) then
        mid_add(BMap[n]);
     end;
    rb := mid_calc;
    if (midc>0) then MainForm.g_benz.Cells[x+1,y+1]:=FloatToStrF(rb ,ffFixed, 2, 3)
     else MainForm.g_benz.Cells[x+1,y+1]:='-';
    mid_clear;
    for n:=0 to GPoints-1 do
     begin
      if (GBenz[n] >= VP[y]-dvm) and (GBenz[n] <= VP[y]+dvp) and
       (GGiri[n] >= OB[x]-dom) and (GGiri[n] <= OB[x]+dop) then
        mid_add(GMap[n]);
     end;
    rg := mid_calc;
    if (midc>0) then MainForm.g_gaz.Cells[x+1,y+1]:=FloatToStrF(rg ,ffFixed, 2, 3)
     else MainForm.g_gaz.Cells[x+1,y+1]:='-';
    if (rb<>0) and (rg<>0) then Sum:=(rb-rg)/rg*100 else Sum:=0;
    if (Sum<>0) then
     MainForm.g_kor.Cells[x+1,y+1]:=FloatToStrF(Sum ,ffFixed, 2, 2)
      else MainForm.g_kor.Cells[x+1,y+1]:='-';
   end;
end;

procedure calc_econt;
var
 n,x,y: integer;
 sum, gm: single;
begin
 WriteLog('Расчёт по коррекциям контроллера двигателя...');
 LoadDataECont;
 if ProcessError then exit;
 Writelog('Построение таблицы...');
 MainForm.t_kmap.Show;
 for x:=0 to po_count-1 do
  for y:=0 to pv_count-1 do
   begin
    Application.ProcessMessages;
    mid_clear;
    for n:=0 to CPoints-1 do
     begin
      if (CBenz[n] >= VP[y]-dvm) and (CBenz[n] <= VP[y]+dvp) and
       (CGiri[n] >= OB[x]-dom) and (CGiri[n] <= OB[x]+dop) then
        mid_add(CLT[n]+CST[n]);
     end;
    if (midc>0) then
    begin
      sum := mid_calc;

      if (MainForm.cbMultGazMap.Enabled and MainForm.cbMultGazMap.Checked) then
      begin
        gm := toDouble(MainForm.g_gaz.Cells[x+1, y+1]);
        if (gm > 0) then
          sum := gm + (gm / 100 * sum);
      end;
      MainForm.g_kor.Cells[x+1,y+1] := FloatToStrF(sum, ffFixed, 2, 2)
    end
    else
      MainForm.g_kor.Cells[x+1,y+1]:='-';
   end;
end;

procedure mid_clear;
begin //Очистка счётчика среднего значения
 midc:=0;
end;

procedure mid_add(val: single);
begin //Добавление цифры для расчёта среднего
 if (midc>=MAX_POINTS) then exit;
 mida[midc]:=val;
 inc(midc);
end;

function mid_calc: single;
var //Расчёт среднего значения (среднее арифметическое или медиана в зависимости от настройки)
 n: integer;
 Sum: double;
 b: boolean;
begin
 if (midc=0) then
  begin //Если данных нет - возвращаем 0
   mid_calc:=0;
   exit;
  end;
 if (MainForm.cs_average.ItemIndex=0) then
  begin //Среднее арифметическое
   Sum:=0;
   for  n:=0 to (midc-1) do Sum:=Sum+mida[n];
   mid_calc := Sum / midc;
   exit;
  end else
   begin //Медиана
    if (midc=1) then
     begin //Если есть только одно значение
      mid_calc:=mida[0];
      exit;
     end else
      begin
       b:=true; //Сортируем массив значений
       while b do
        begin
         b:=false;
         for n:=0 to (midc-2) do
          if (mida[n] > mida[n+1]) then
           begin
            Sum:=mida[n];
            mida[n]:=mida[n+1];
            mida[n+1]:=Sum;
            b:=True;
           end;
        end;
       if (midc mod 2 = 0) then
        begin //При чётном числе данных
         n:=midc div 2 - 1;
         mid_calc:=(mida[n]+mida[n+1]) / 2;
        end else
         //При нечётном числе данных
         mid_calc:=mida[midc div 2];
      end;
   end;
end;

end.

