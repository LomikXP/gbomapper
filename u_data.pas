unit u_data;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, Forms;

const
 GBOM_VERSION = 'v. 0.4.2a4';
 GBOM_BUILD_DATE = {$I %DATE%};
 MAX_POINTS = 131072;
 CFG_FILE = 'gbomap.bcfg';

 //Список "TO DO":
 //1. Загрузка длинных строк проходит некорректно
 //2. Не определяет столбцы правильно у Сканматика или возможно ещё чего-то
 //3. Расчёт медианы вместо среднего значения (на выбор)

var
 //Количество точек в карте по оборотам и времени впрыска (с запасом до 255)
 po_count, pv_count: byte;
 //Значения оборотов
 OB: array [0..255] of integer;
 //Значения времени впрыска
 VP: array [0..255] of single;
 //Если произошла ошибка
 ProcessError: boolean;
 //Данные для макроса
 dvm,dvp,dmm,dmp: single;
 dom,dop: word;
 //Данные бензина
 BPoints: Cardinal;
 BGiri: array [0..MAX_POINTS] of word;
 BBenz: array [0..MAX_POINTS] of single;
 BMap: array [0..MAX_POINTS] of single;
 //Данные газа
 GPoints: Cardinal;
 GGiri: array [0..MAX_POINTS] of word;
 GBenz: array [0..MAX_POINTS] of single;
 GGaz: array [0..MAX_POINTS] of single;
 GMap: array [0..MAX_POINTS] of single;
 //Данные контроллера двигателя
 CPoints: cardinal;
 CGiri: array [0..MAX_POINTS] of word;
 CLT, CST: array [0..MAX_POINTS] of single;
 CBenz: array [0..MAX_POINTS] of single;
 //Запрет бензиновых данных и пропусков нулей (для расчёта по двум контроллерам)
 NoBenz: boolean;
 //Данные, заполняемые при чтении заголовка файла
 DF_filename: string;
 DF_type, df_rpm, df_vb, df_vg, df_map, df_st, df_lt, df_hs: byte;
 df_ds: char;
 //Результаты деления строки SplitString
 SplitA: array [0..255] of string;
 SplitN: integer;

 //Делитель строк (результат в SplitA и SplitN)
 procedure SplitString(S: String; Splitter: Char);
 //Преобразование строк в числа с коррекцией ошибок
 function toInt(s: string): int64;
 function toDouble(s: string): double;

 procedure WriteLog(s: string);
 procedure ErrorMessage(msg: string);

implementation

uses f_main;

function pow10(r: integer): int64;
var
 n: integer;
 rz: int64;
begin
 rz:=1;
 if (r>0) then
  for n:=1 to r do
   rz:=rz*10;
 pow10:=rz;
end;

function toInt(s: string): int64;
var
 n,rz: integer;
 r: int64;
 sz: boolean;
begin
 r:=0;
 rz:=0;
 sz:=false;
 for n:=length(s) downto 1  do
  begin
   if (s[n]='-') then sz:= true;
   if (ord(s[n])>47) and (ord(s[n])<58) then
    begin
     r:=r+(ord(s[n])-48)*pow10(rz);
     inc(rz);
    end;
  end;
 if sz then r:=-r;
 toInt:=r;
end;

function toDouble(s: string): double;
var
 n,rz: integer;
 sz: boolean;
 r: double;
begin
 r:=0;
 rz:=0;
 sz:=false;
 for n:=length(s) downto 1  do
  begin
   if (s[n]='-') then sz:= true;
   if (ord(s[n])>47) and (ord(s[n])<58) then
    begin
     r:=pow10(rz)*(ord(s[n])-48)+r;
     inc(rz);
    end;
   if (s[n]=',') or (s[n]='.') then
    begin
     r:=r / pow10(rz);
     rz:=0;
    end;
  end;
 if sz then r:=-r;
 toDouble:=r;
end;

procedure SplitString(S: String; Splitter: Char);
var
 n: integer;
begin
 for n:=0 to 255 do SplitA[n]:='';
 if length(S) < 1 then
  begin
   SplitN:=0;
   exit;
  end;
 SplitN:=1;
 for n:=1 to length(S) do
  if (S[n]=Splitter) then
   begin
    inc(SplitN);
    if (SplitN > 256) then exit;
   end else
    SplitA[SplitN-1]:=SplitA[SplitN-1]+S[n];
end;

procedure WriteLog(s: string);
begin
 MainForm.logtext.Lines.Add(s);
 Application.ProcessMessages;
end;

procedure ErrorMessage(msg: string);
begin
 MessageDlg('Ошибка',msg,mtError, [mbOk],0 );
 MainForm.logtext.Lines.Add('Ошибка: '+msg);
 Application.ProcessMessages;
 ProcessError:=True;
end;

end.

