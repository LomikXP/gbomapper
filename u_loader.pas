unit u_loader;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazUTF8, Forms, u_data, LConvEncoding;

const
 {$IFDEF WINDOWS}
 DIR_SPLITTER = '\';
 {$ELSE}
 DIR_SPLITTER = '/';
 {$ENDIF}

//Подготовка входных данных
procedure SetupData(PE: boolean);
//Чтение заголовка файла данных
//(0-нет данных, 1-газовый контроллер, 2-контроллер двигателя)
function ReadFileHeader(FileName: string): byte;
//Чтение данных из файла после проверки заголовка
procedure ReadFile;
//Загрузка данных для методов расчёта без данных контроллера двигателя
procedure LoadData;
//Загрузка данных для методов расчёта без данных контроллера двигателя
procedure LoadDataECont;
//Проверка произвольного файла контроллера двигателя
procedure CheckContFile(FileName: String);
//Сохранение файла настроек
procedure SaveCfg;
//Загрузка файла настроек
procedure LoadCfg;

implementation

uses f_main;

procedure SetupData(PE: boolean);
var
 n,i,x: integer;
 s: string;
begin
 with MainForm do
  begin
   po_count:=0;
   pv_count:=0;
   for n:=0 to (l_vprysk.Lines.Count - 1) do
    begin
     VP[pv_count] := todouble (l_vprysk.Lines.Strings[n]);
     if (VP[pv_count] > 0) then
      begin
       if (pv_count < 255) then inc(pv_count) else
        break;
      end;
    end;
   s:='';
   for n:=0 to (pv_count-1) do
    s:=s+FloatToStrF(VP[n] ,ffFixed, 2, 1)+' ';
   WriteLog('Точки времени впрыска: '+s);
   for n:=0 to (pv_count-2) do
    if (VP[n] > VP[n+1]) and PE then
     begin
      ErrorMessage('Ошибка в данных времени впрыска!');
      exit;
     end;
   if (pv_count<2) and PE then
    begin
     ErrorMessage('Слишком мало точек времени впрыска.');
     exit;
    end;
   n:=toint(ob_min.Text);
   i:=toint(ob_max.Text);
   x:=toint(ob_step.Text);
   if (n<1) then n:=1;
   if (i>10000) then i:=10000;
   if (x<1) then x:=1;
   OB[0]:=n;
   po_count:=1;
   if PE and ((n>i) or (n<100)) then
    begin
     ErrorMessage('Ошибка настройки оборотов!');
     exit;
    end;
   s:=inttostr(n)+' ';
   while (n < i) do
    begin
     n:=n+x;
     OB[po_count]:=n;
     if (po_count = 255) then break else inc(po_count);
     s:=s+inttostr(n)+' ';
    end;
   if PE then WriteLog('Точки оборотов: '+s);
   dvm:=todouble(dm_vprysk.Text);
   dvp:=todouble(dp_vprysk.Text);
   dmm:=todouble(dm_map.Text);
   dmp:=todouble(dp_map.Text);
   dom:=toint(dm_oboroty.Text);
   dop:=toint(dp_oboroty.Text);
   g_kor.Clear;
   g_benz.Clear;
   g_gaz.Clear;
   g_kor.ColCount:=po_count+1;
   g_kor.RowCount:=pv_count+1;
   g_benz.ColCount:=po_count+1;
   g_benz.RowCount:=pv_count+1;
   g_gaz.ColCount:=po_count+1;
   g_gaz.RowCount:=pv_count+1;
   g_kor.Cells[0,0]:='[Меню]';
   for n:=1 to pv_count do
    begin
     g_kor.Cells[0,n]:=FloatToStrF(VP[n-1] ,ffFixed, 2, 1);
     g_benz.Cells[0,n]:=g_kor.Cells[0,n];
     g_gaz.Cells[0,n]:=g_kor.Cells[0,n];
    end;
   for n:=1 to po_count do
    begin
     g_kor.Cells[n,0]:=inttostr(OB[n-1]);
     g_benz.Cells[n,0]:=g_kor.Cells[n,0];
     g_gaz.Cells[n,0]:=g_kor.Cells[n,0];
    end;
  end;
end;

//Чтение заголовка файла данных
function ReadFileHeader(FileName: string): byte;
var
 n,i,x:integer;
 f: textfile;
 s: string;
 cds: char;
 crpm,cvb,cvg,cmap,cst,clt: byte;
begin
 DF_filename:=FileName;
 DF_type:=0; df_rpm:=0; df_vb:=0; df_vg:=0; df_map:=0; df_st:=0; df_lt:=0;
 ReadFileHeader:=0; df_ds:=chr(0); df_hs:=0;
 {$I-}
 if not fileexists(FileName) then exit;
 assignfile(f,FileName);
 reset(f);
 if (IOResult<>0) then exit;
 for n:=0 to 15 do
  begin
   if eof(f) then break;
   readln(f,s);
   if (IOResult<>0) then break;
   if (MainForm.cs_charset.ItemIndex = 0) then s:=CP1251toUTF8(s);
   s:=UTF8UpperCase(s);
   for i:=0 to 2 do
    begin
     case i of
      0: cds:=chr(9);
      1: cds:=';';
      else cds:=',';
     end;
     crpm:=0; cvb:=0; cvg:=0; cmap:=0; cst:=0; clt:=0;
     SplitString(s,cds);
     if (SplitN<3) then continue;
     for x:=1 to SplitN do
      begin
       //Пытаемся определить тип данных в подстроке
       if (SplitA[x-1]='MAP') then begin cmap:=x; continue; end;
       if (SplitA[x-1]='GIRI') then begin crpm:=x; continue; end;
       if (SplitA[x-1]='GAS') then begin cvg:=x; continue; end;
       if (SplitA[x-1]='INJ.') then begin cvg:=x; continue; end;
       if (SplitA[x-1]='INJ,') then begin cvg:=x; continue; end;
       if (SplitA[x-1]='BENZ') then begin cvb:=x; continue; end;
       if (SplitA[x-1]='INJ.BNZ') then begin cvb:=x; continue; end;
       if (SplitA[x-1]='INJ,BNZ') then begin cvb:=x; continue; end;
       if (pos('REALPCOL',SplitA[x-1])>0) and (cmap=0) then begin cmap:=x; continue; end;
       if (pos('RPM',SplitA[x-1])>0) and (crpm=0) then begin crpm:=x; continue; end;
       if (pos('ОБОРОТЫ',SplitA[x-1])>0) and (crpm=0) then begin crpm:=x; continue; end;
       if (pos('REALAVGTG',SplitA[x-1])>0) and (cvg=0) then begin cvg:=x; continue; end;
       if (pos('REALAVGTB',SplitA[x-1])>0) and (cvb=0) then begin cvb:=x; continue; end;
       if (pos('ДЛИТЕЛЬНОСТЬ ВПРЫСКА',SplitA[x-1])>0) and (cvb=0) then begin cvb:=x; continue; end;
       if (pos('МУЛЬТИПЛИКАТИВНАЯ СОСТАВЛЯЮЩАЯ КОРРЕКЦИИ',SplitA[x-1])>0) and (clt=0) then begin clt:=x; continue; end;
       if (pos('КОРРЕКЦИЯ',SplitA[x-1])>0) and (cst=0) then begin cst:=x; continue; end;
       if (pos('КОЭФФИЦИЕНТ КОРРЕКЦИИ',SplitA[x-1])>0) and (cst=0) then begin if (cst=0) then cst:=x; continue; end;
       if (pos('FUEL',SplitA[x-1])>0)
        and ((pos('PW',SplitA[x-1])>0) or (pos('POW',SplitA[x-1])>0)) or
         (pos('TIME CORR',SplitA[x-1])>0) then begin if (cvb=0) then cvb:=x; continue; end;
       if (pos('LONG',SplitA[x-1])>0)
        and ((pos('FT',SplitA[x-1])>0) or (pos('TRIM',SplitA[x-1])>0)) then
         begin if (clt=0) then clt:=x; continue; end;
       if ((pos('SHRT',SplitA[x-1])>0) or (pos('FUEL',SplitA[x-1])>0) or (pos('SHORT',SplitA[x-1])>0)) and
        ((pos('FT',SplitA[x-1])>0) or (pos('TRIM',SplitA[x-1])>0)) then
         begin if (cst=0) then cst:=x; continue; end;
       if (pos('LFT',SplitA[x-1])>0) or (pos('LTFT',SplitA[x-1])>0) then
        begin if (clt=0) then clt:=x; continue; end;
       if (pos('SFT',SplitA[x-1])>0) or (pos('STFT',SplitA[x-1])>0) then
        begin if (cst=0) then cst:=x; continue; end;
      end;
     if (crpm>0) then
      begin
       if (cvb>0) and (cvg>0) then begin DF_type:=1; df_hs:=n+1; break; end;
       if (cst>0) then begin DF_type:=2; df_hs:=n+1; break; end;
      end;
    end;
   if (DF_type>0) then break;
  end;
 closefile(f);
 {$I+}
 if (DF_type>0) then
  begin
   df_rpm:=crpm; df_vb:=cvb; df_vg:=cvg; df_map:=cmap; df_st:=cst; df_lt:=clt;
   ReadFileHeader:=DF_type; df_ds:=cds;
  end;
end;

//Чтение данных из файла после проверки заголовка
procedure ReadFile;
var
 f: textfile;
 n: integer;
 cc: byte;
 s: string;
 rv1,rv2: single;
begin
 if (DF_type = 0) then exit;
 {$I-}
 if not fileexists(DF_FileName) then exit;
 assignfile(f,DF_FileName);
 reset(f);
 if (IOResult<>0) then exit;
 SplitString(DF_FileName,DIR_SPLITTER);
 s:=SplitA[SplitN-1]+' ( ';
 if (df_ds=',')  then s:=s+'C ' else
  if (df_ds=';') then s:=s+'SC ' else s:=s+'TAB ';
 if (df_rpm>0) then s:=s+inttostr(df_rpm)+' ';
 if (df_vb>0) then s:=s+inttostr(df_vb)+' ';
 if (df_vg>0) then s:=s+inttostr(df_vg)+' ';
 if (df_map>0) then s:=s+inttostr(df_map)+' ';
 if (df_st>0) then s:=s+inttostr(df_st)+' ';
 if (df_lt>0) then s:=s+inttostr(df_lt)+' ';
 Writelog('Загрузка файла: '+s+')');
 for n:=1 to df_hs do
  if not eof(f) then readln(f,s);
 //Определяем последний столбец, чтобы потом отсекать строки с недостаточным их количеством
 cc:=df_rpm;
 if (cc<df_vb) then cc:=df_vb;
 if (cc<df_vg) then cc:=df_vg;
 if (cc<df_map) then cc:=df_map;
 if (cc<df_st) then cc:=df_st;
 if (cc<df_lt) then cc:=df_lt;
 //Цикл чтения строк до конца файла
 while not eof(f) do
  begin
   readln(f,s);
   if (IOResult<>0) then break;
   SplitString(s,df_ds);
   if (SplitN<cc) then continue;
   if (DF_type=1) then
    begin
     if (df_vb < 1) or (df_vg < 1) then break;
     if NoBenz then //При запрете бензиновых данных
      begin
       if (GPoints >= MAX_POINTS) then continue;
       if (df_rpm > 0) then GGiri[GPoints]:=round(todouble(SplitA[df_rpm-1]))
        else GGiri[GPoints]:=0;
       GGaz[GPoints]:=todouble(SplitA[df_vg-1]);
       if (df_map > 0) then GMap[GPoints]:=todouble(SplitA[df_map-1])
        else GMap[GPoints]:=0;
       GBenz[GPoints]:=todouble(SplitA[df_vb-1]);
       inc (GPoints);
       continue;
      end;
     //Чтение данных для файла газового контроллера
     rv1:=todouble(SplitA[df_vb-1]);
     rv2:=todouble(SplitA[df_vg-1]);
     if (rv1=0) then continue;
     if (rv2=0) then
      begin
       //Данные поездки на бензине
       if (BPoints >= MAX_POINTS) then continue;
       if (df_rpm > 0) then BGiri[BPoints]:=round(todouble(SplitA[df_rpm-1]))
        else BGiri[BPoints]:=0;
       if (df_map > 0) then BMap[BPoints]:=todouble(SplitA[df_map-1])
        else BMap[BPoints]:=0;
       BBenz[BPoints]:=rv1;
       inc (BPoints);
      end else
       begin
        //Данные поездки на газе
        if (GPoints >= MAX_POINTS) then continue;
        if (df_rpm > 0) then GGiri[GPoints]:=round(todouble(SplitA[df_rpm-1]))
         else GGiri[GPoints]:=0;
        GGaz[GPoints]:=rv2;
        if (df_map > 0) then GMap[GPoints]:=todouble(SplitA[df_map-1])
         else GMap[GPoints]:=0;
        GBenz[GPoints]:=rv1;
        inc (GPoints);
       end;
    end else
     begin
      //Чтение данных для файла контроллера двигателя
      if (CPoints >= MAX_POINTS) then break;
      if (df_rpm > 0) then CGiri[CPoints]:=round(todouble(SplitA[df_rpm-1]))
       else CGiri[CPoints]:=0;
      if (df_st > 0) then CST[CPoints]:=todouble(SplitA[df_st-1])
       else CST[CPoints]:=0;
      if (df_lt > 0) then CLT[CPoints]:=todouble(SplitA[df_lt-1])
       else CLT[CPoints]:=0;
      if (df_vb > 0) then CBenz[CPoints]:=todouble(SplitA[df_vb-1])
       else CBenz[CPoints]:=0;
      inc (CPoints);
     end;
  end;
 closefile(f);
 {$I+}
end;

//Загрузка данных из файлов
procedure LoadData;
var
 n,i: integer;
 b: byte;
 s: string;
begin
 GPoints:=0;
 BPoints:=0;
 CPoints:=0;
 FileMode:=0;
 {$I-}
 for i:=0 to (MainForm.files_list.Count-1) do
  begin
   NoBenz:=False;
   s:=UTF8toSys(MainForm.files_list.Items.Strings[i]);
   b:=ReadFileHeader(s);
   SplitString(s,DIR_SPLITTER);
   s:=SplitA[SplitN-1];
   if (b=0) then
    begin
     WriteLog('Неизвестный формат файла: '+s);
     continue;
    end;
   if (b=2) then
    begin
     WriteLog('Неподходящий тип файла: '+s);
     continue;
    end;
   ReadFile;
  end;
 {$I+}
 FileMode:=2;
 if (BPoints = MAX_POINTS) then s:=' (!максимум!)' else s:='';
 Writelog('Записей движения на бензине: '+inttostr(BPoints)+s);
 if (GPoints = MAX_POINTS) then s:=' (!максимум!)' else s:='';
 Writelog('Записей движения на газе: '+inttostr(GPoints)+s);
 if (GPoints < 3) or (BPoints < 3) then ErrorMessage('Недостаточно данных!');
 if ProcessError then exit;
 i:=0;
 for n:=0 to BPoints-1 do
  if (BMap[n] > 0) then inc(i);
 if (i<2) then ErrorMessage('Нет данных MAP для бензина!');
 i:=0;
 for n:=0 to GPoints-1 do
  if (GMap[n] > 0) then inc(i);
 if (i<2) then ErrorMessage('Нет данных MAP для газа!');
 i:=0;
 for n:=0 to GPoints-1 do
  if (GMap[n]>3) then
   begin
    GMap[n]:=GMap[n] / 1000;
    inc(i);
   end;
 for n:=0 to BPoints-1 do
  if (BMap[n]>3) then
   begin
    BMap[n]:=BMap[n] / 1000;
    inc(i);
   end;
 if (i>0) then
  writelog('Данные MAP нормализованы для '+inttostr(i)+' из '+
   inttostr(GPoints+BPoints)+' точек.');
end;

//Загрузка данных для расчёта по коррекциям контроллера двигателя
procedure LoadDataECont;
var
 n,i: integer;
 b,cc: byte;
 s: string;
 f: textfile;
begin
 GPoints:=0;
 BPoints:=0;
 CPoints:=0;
 FileMode:=0;
 {$I-}
 s:=UTF8toSys(MainForm.file_cont.Caption);
 if not fileexists(s) then exit;
 assignfile(f,s);
 reset(f);
 if (IOResult<>0) then exit;
 SplitString(s,DIR_SPLITTER);
 df_rpm:=MainForm.cs_giri.ItemIndex+1;
 df_vb:=MainForm.cs_benz.ItemIndex+1;
 df_st:=MainForm.cs_sft.ItemIndex+1;
 df_lt:=MainForm.cs_lft.ItemIndex;
 if (df_lt=255) then df_lt:=0;
 if (df_lt=df_st) or (df_rpm=df_vb) or (df_vb=df_st) or (df_st=df_rpm) or
  (df_rpm=0) or (df_vb = 0) or (df_st = 0) then
   begin
    Errormessage('Данные настроены некорректно.');
    Exit;
   end;
 s:=SplitA[SplitN-1]+' ( ';
 if (df_ds=',')  then s:=s+'C ' else
  if (df_ds=';') then s:=s+'SC ' else s:=s+'TAB ';
 if (df_rpm>0) then s:=s+inttostr(df_rpm)+' ';
 if (df_vb>0) then s:=s+inttostr(df_vb)+' ';
 if (df_st>0) then s:=s+inttostr(df_st)+' ';
 if (df_lt>0) then s:=s+inttostr(df_lt)+' ';
 Writelog('Загрузка файла: '+s+')');
 for n:=1 to df_hs do
  if not eof(f) then readln(f,s);
 //Определяем последний столбец, чтобы потом отсекать строки с недостаточным их количеством
 cc:=df_rpm;
 if (cc<df_vb) then cc:=df_vb;
 if (cc<df_st) then cc:=df_st;
 if (cc<df_lt) then cc:=df_lt;
 //Цикл чтения строк до конца файла
 while not eof(f) do
  begin
   readln(f,s);
   if (IOResult<>0) then break;
   SplitString(s,df_ds);
   if (SplitN<cc) then continue;
   //Чтение данных файла контроллера двигателя
   if (CPoints >= MAX_POINTS) then break;
   if (df_rpm > 0) then CGiri[CPoints]:=round(todouble(SplitA[df_rpm-1]))
    else CGiri[CPoints]:=0;
   if (df_st > 0) then CST[CPoints]:=todouble(SplitA[df_st-1])
    else CST[CPoints]:=0;
   if (df_lt > 0) then CLT[CPoints]:=todouble(SplitA[df_lt-1])
    else CLT[CPoints]:=0;
   if (df_vb > 0) then CBenz[CPoints]:=todouble(SplitA[df_vb-1])
    else CBenz[CPoints]:=0;
   inc (CPoints);
  end;
 closefile(f);
 {$I+}
 FileMode:=2;
 if (CPoints = MAX_POINTS) then s:=' (!максимум!)' else s:='';
 Writelog('Записей данных: '+inttostr(CPoints)+s);
 if (CPoints < 3) then ErrorMessage('Недостаточно данных!');
 if ProcessError then exit;
 b:=0;
 for n:=0 to CPoints-1 do if (CST[n]>1.5) or (CST[n]<0.5) then if (CST[n]<>0) then b:=1;
 if (b=0) then
  begin
   for n:=0 to CPoints-1 do CST[n]:=(CST[n]-1)*100;
   WriteLog('Данные коррекции нормализованы.');
  end;
 b:=0;
 for n:=0 to CPoints-1 do if (CLT[n]>1.25) or (CLT[n]<0.75) then b:=1;
 if (b=0) then
  begin
   for n:=0 to CPoints-1 do CLT[n]:=(CLT[n]-1)*100;
   WriteLog('Данные долгосрочной коррекции нормализованы.');
  end;
end;

procedure CheckContFile(FileName: String);
var
 n,i,l,hs: integer;
 f: textfile;
 cc,cs,ct,cn: integer;
 cspl: char;
 s: string;
 has: array [0..255] of string;
begin
 MainForm.file_cont.Caption:='Файл не загружен.';
 MainForm.cs_giri.Items.Clear;
 MainForm.cs_benz.Items.Clear;
 MainForm.cs_sft.Items.Clear;
 MainForm.cs_lft.Items.Clear;
 MainForm.cs_lft.Items.Add('Отключено');
 Application.ProcessMessages;
 Writelog('Проверка файла "'+FileName+'"...');
 {$I-}
 assignfile(f,UTF8toSys(FileName));
 reset(f);
 if (IOResult<>0) then
  begin
   ErrorMessage('Нет доступа.');
   exit;
  end;
 cc:=0;
 cs:=0;
 ct:=0;
 hs:=0;
 for n:=0 to 50 do
  begin
   if eof(f) then break;
   cn:=0;
   readln(f,s);
   //Writelog(inttostr(length(s)));
   if (IOResult<>0) then break;
   if (MainForm.cs_charset.ItemIndex = 0) then s:=CP1251toUTF8(s);
   l:=length(s);
   for i:=1 to l do
    begin
     if (s[i]=',') then inc(cc);
     if (s[i]=';') then inc(cs);
     if (ord(s[i])=9) then inc(ct);
     if (s[i]='0') or (s[i]='1') or (s[i]='2') or (s[i]='3') or (s[i]='4') or
      (s[i]='5') or (s[i]='6') or (s[i]='7') or (s[i]='8') or (s[i]='9') or
       (s[i]='-') or (s[i]='.') then inc(cn);
    end;
   //Если в строке больше 50% цифр, то считаем, что это уже данные, а не заголовок
   if ((cn/l) > 0.5) and (n>0) then begin hs:=n; break; end;
  end;
 l:=cs;
 if (cc>l) then l:=cc;
 if (ct>l) then l:=ct;
 if (l<2) or (hs<1) then
  begin
   ErrorMessage('Заголовок не определён.');
   closefile(f);
   exit;
  end;
 if (MainForm.cs_splitter.ItemIndex=0) then
  if (l=cs) then cspl:=';' else
   if (l=ct) then cspl:=chr(9) else
    cspl:=',';
 if (MainForm.cs_splitter.ItemIndex=1) then cspl:=';';
 if (MainForm.cs_splitter.ItemIndex=2) then cspl:=chr(9);
 if (MainForm.cs_splitter.ItemIndex=3) then cspl:=',';
 for i:=0 to 255 do has[i]:='';
 reset(f);
 if (IOResult<>0) then
  begin
   ErrorMessage('Ошибка доступа.');
   closefile(f);
   exit;
  end;
 l:=0;
 for n:=1 to hs do
  begin
   if eof(f) then break;
   readln(f,s);
   if (IOResult<>0) then break;
   if (MainForm.cs_charset.ItemIndex = 0) then s:=CP1251toUTF8(s);
   SplitString(s,cspl);
   if (SplitN<3) then continue;
   if (SplitN>l) then l:=SplitN;
   for i:=0 to SplitN-1 do
    has[i]:=has[i]+SplitA[i]+' ';
  end;
 closefile(f);
 if (IOResult<>0) or (l<3) then
  begin
   ErrorMessage('При чтении файла произошла ошибка.');
   exit;
  end;
 {$I+}
 for i:=0 to l-1 do
  begin
   MainForm.cs_giri.Items.Add(has[i]);
   MainForm.cs_benz.Items.Add(has[i]);
   MainForm.cs_sft.Items.Add(has[i]);
   MainForm.cs_lft.Items.Add(has[i]);
   //writelog('"'+has[i]+'"');
  end;
 MainForm.file_cont.Caption:=FileName;
 if (ReadFileHeader(FileName) = 2) then
  begin
   if (MainForm.cs_giri.Items.Count >= df_rpm) then MainForm.cs_giri.ItemIndex:=df_rpm-1;
   if (MainForm.cs_benz.Items.Count >= df_vb) then MainForm.cs_benz.ItemIndex:=df_vb-1;
   if (MainForm.cs_sft.Items.Count >= df_st) then MainForm.cs_sft.ItemIndex:=df_st-1;
   if (MainForm.cs_lft.Items.Count >= df_lt+1) then MainForm.cs_lft.ItemIndex:=df_lt;
   hs:=df_hs;
   Writelog('Файл автоматически определён. Проверьте настройки при необходимости.');
  end else
   begin
    Writelog('Файл распознан, но автоматически не определён. Настройте вручную.');
    MainForm.t_csetup.Show;
   end;
  df_ds:=cspl;
  df_hs:=hs;
end;

procedure SaveCfg;
var
 str: TMemoryStream;
 s: TStringStream;
 hdr: array [0..4] of char;
 b: byte;
 n,i,l: integer;
begin
 try
  str:= TMemoryStream.Create;
  s:= TStringStream.Create('');
  hdr:='BCFG2';
  if (str.Write(hdr,5) <> 5) then exit;
  n:=toint(MainForm.ob_min.Text);
  if (str.Write(n,4) <> 4) then exit;
  n:=toint(MainForm.ob_max.Text);
  if (str.Write(n,4) <> 4) then exit;
  n:=toint(MainForm.ob_step.Text);
  if (str.Write(n,4) <> 4) then exit;
  if (str.Write(dvm,4) <> 4) then exit;
  if (str.Write(dvp,4) <> 4) then exit;
  if (str.Write(dmm,4) <> 4) then exit;
  if (str.Write(dmp,4) <> 4) then exit;
  b:=MainForm.alg_select.ItemIndex;
  if (str.Write(b,1) <> 1) then exit;
  if (str.Write(dom,2) <> 2) then exit;
  if (str.Write(dop,2) <> 2) then exit;
  b:=MainForm.s_vprysk.ItemIndex;
  if (str.Write(b,1) <> 1) then exit;
  if (b=0) then
   begin
    if (str.Write(pv_count,1) <> 1) then exit;
    if (str.Write(VP, pv_count*4) <> pv_count*4) then exit;
   end;
  n:=MainForm.files_list.Count;
  if (str.Write(n,4) <> 4) then exit;
  if (n>0) then
   for i:=0 to n-1 do
    begin
     l:=length(MainForm.files_list.Items.Strings[i]);
     if (str.Write(l,4) <> 4) then exit;
     if (l<1) then continue;
     s.Size:=l;
     s.Seek(0,0);
     s.WriteString(MainForm.files_list.Items.Strings[i]);
     s.Seek(0,0);
     if (str.CopyFrom(s,l) <> l) then exit;
    end;
  if (str.Write(MainForm.g_kor.ColCount,4) <> 4) then exit;
  if (str.Write(MainForm.g_kor.RowCount,4) <> 4) then exit;
  for n:=0 to MainForm.g_kor.ColCount-1 do
   for i:=0 to MainForm.g_kor.RowCount-1 do
    begin
     if (n=0) and (i=0) then continue;
     l:=length(MainForm.g_kor.Cells[n,i]);
     if (str.Write(l,4) <> 4) then exit;
     if (l<1) then continue;
     s.Size:=l;
     s.Seek(0,0);
     s.WriteString(MainForm.g_kor.Cells[n,i]);
     s.Seek(0,0);
     if (str.CopyFrom(s,l) <> l) then exit;
    end;
  if (MainForm.WindowState = wsMaximized) then
   begin
    n:=-1024;
    for l:=0 to 3 do str.Write(n,4);
   end else
    begin
     if (str.Write(MainForm.Left,4) <> 4) then exit;
     if (str.Write(MainForm.Top,4) <> 4) then exit;
     if (str.Write(MainForm.Width,4) <> 4) then exit;
     if (str.Write(MainForm.Height,4) <> 4) then exit;
    end;
  str.SaveToFile(CFG_FILE);
 finally str.Free; s.Free; end;
end;

procedure LoadCfg;
var
 g: boolean;
 str: TMemoryStream;
 s: TStringStream;
 hdr: array [0..4] of char;
 b: byte;
 n,x,y,l: integer;
begin
 if not fileexists(CFG_FILE) then exit;
 g:=false;
 str:=TMemoryStream.Create;
 s:=TStringStream.Create('');
 try
  str.LoadFromFile(CFG_FILE);
  if (str.Read(hdr,5) <> 5) then exit;
  if (hdr <> 'BCFG2') then exit;
  if (str.Read(n,4) <> 4) then exit;
  MainForm.ob_min.Text:=inttostr(n);
  if (str.Read(n,4) <> 4) then exit;
  MainForm.ob_max.Text:=inttostr(n);
  if (str.Read(n,4) <> 4) then exit;
  MainForm.ob_step.Text:=inttostr(n);
  if (str.Read(dvm,4) <> 4) then exit;
  if (str.Read(dvp,4) <> 4) then exit;
  if (str.Read(dmm,4) <> 4) then exit;
  if (str.Read(dmp,4) <> 4) then exit;
  if (str.Read(b,1) <> 1) then exit;
  if (b<6) then MainForm.alg_select.ItemIndex := b;
  Application.ProcessMessages;
  MainForm.alg_selectChange(MainForm);
  if (str.Read(dom,2) <> 2) then exit;
  if (str.Read(dop,2) <> 2) then exit;
  MainForm.dm_vprysk.Text:=FloatToStrF(dvm ,ffFixed, 2, 3);
  MainForm.dp_vprysk.Text:=FloatToStrF(dvp ,ffFixed, 2, 3);
  MainForm.dm_map.Text:=FloatToStrF(dmm ,ffFixed, 2, 2);
  MainForm.dp_map.Text:=FloatToStrF(dmp ,ffFixed, 2, 2);
  MainForm.dm_oboroty.Text:=inttostr(dom);
  MainForm.dp_oboroty.Text:=inttostr(dop);
  if (str.Read(b,1) <> 1) then exit;
  MainForm.s_vprysk.ItemIndex:=b;
  if (b=0) then
   begin
    if (str.Read(pv_count,1) <> 1) then exit;
    if (str.Read(VP, pv_count*4) <> pv_count*4) then exit;
    MainForm.l_vprysk.Clear;
    for n:=0 to pv_count-1 do
     MainForm.l_vprysk.Lines.Add(FloatToStrF(VP[n] ,ffFixed, 2, 1));
   end;
  if (str.Read(n,4) <> 4) then exit;
  MainForm.files_list.Clear;
  for x:=0 to n-1 do
    begin
     if (str.Read(l,4) <> 4) then exit;
     if (l<1) then continue;
     s.Size:=l;
     s.Seek(0,0);
     if (s.CopyFrom(str,l) <> l) then exit;
     MainForm.files_list.Items.Add(s.DataString);
    end;
  if (str.Read(x,4) <> 4) then exit;
  if (str.Read(y,4) <> 4) then exit;
  if (x<1) or (y<1) then exit;
  MainForm.g_kor.ColCount:=x;
  MainForm.g_kor.RowCount:=y;
  for x:=0 to MainForm.g_kor.ColCount-1 do
   for y:=0 to MainForm.g_kor.RowCount-1 do
    begin
     if (x=0) and (y=0) then continue;
     if (str.Read(l,4) <> 4) then exit;
     if (l<1) then continue;
     s.Size:=l;
     s.Seek(0,0);
     if (s.CopyFrom(str,l) <> l) then exit;
     s.seek(0,0);
     MainForm.g_kor.Cells[x,y]:=s.DataString;
    end;
  if (str.Read(n,4) <> 4) then exit;
  if (n=-1024) then MainForm.WindowState := wsMaximized else
   begin
    if (n > -32) and (n < Screen.Width - 32) then MainForm.Left:=n;
    if (str.Read(n,4) <> 4) then exit;
    if (n > -32) and (n < Screen.Height - 32) then MainForm.Top:=n;
    if (str.Read(n,4) <> 4) then exit;
    if (n > 639) and (n <= Screen.Width) then MainForm.Width:=n;
    if (str.Read(n,4) <> 4) then exit;
    if (n > 399) and (n <= Screen.Height) then MainForm.Height:=n;
   end;
  g:=true;
 finally
  str.Free;
  s.free;
  if not g then Writelog('Ошибка загрузки файла настроек!');
 end;
end;

end.

