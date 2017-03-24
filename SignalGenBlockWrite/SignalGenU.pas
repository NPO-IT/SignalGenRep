unit SignalGenU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

const
  //количество записываемых пакетов. за раз
  NUM_WRITE_POCKET=5000;//100;
  //размерность пакета записи, в частности пакета ИРУТ(28)
  POCKETSIZE=28;
  N=1000;
  //N=100;
  //N=512;
  //N=4096;
  //величина сдвига для правильного размещения значений
  SDVIG=100;
  //количество пакетов в секунду
  NUM_POCKET_IN_SEC=2000;
  //частота опроса(дискретизации) медленных; Гц
  SAMPLING_FREQ_SLOW=10;
  //количество каналов медленных
  NUM_SLOW_CHANAL=5;
  //количество байт данных в пакете ГЕОС . 30 слов по 4 байта
  NUM_BYTE_IN_GEOS_POCKET=120;

type
  TSignalGenForm = class(TForm)
    startGen: TButton;
    signalTimer: TTimer;
    SaveDialog1: TSaveDialog;
    Label1: TLabel;
    Label2: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure startGenClick(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure signalTimerTimer(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

  //поток для записи
  TThreadWrite = class(TThread)
    private
    { Private declarations }
  protected
    procedure Execute; override;
  end;
  byteArray=array of byte;
  wordArray=array of word;
  TSlowPar=array[1..NUM_SLOW_CHANAL] of word;
  TGeosRec=record
    //1 слово GEOS 4 байта
    //колич. секунд от 1 января 2008 года  .8б
    time:int64;
    //широта. радианы 8б
    latitude:double;
    //долгота. радианы 8б
    longtitude:double;
    //высота над элипсоидом 8б
    hOnElps:double;
    //отклонение элипсоида от геоида 8б
    deflGeoid:double;
    //число КА 4
    KAnum:integer;
    //состояние приемника 4
    transStatus:integer;
    //GDOP 8
    gDop:double;
    //PDOP 8
    pDop:double;
    //TDOP 8
    tDop:double;
    //HDOP 8
    hDop:double;
    //VDOP 8
    vDop:double;
    //флаг достоверности 4
    flagD:integer;
    //колл. дост. решений  4
    countDes:integer;
    //скорость  8
    planV:double;
    //курс 8
    kurs:double;
    //контр. сумма 8
    sum:int64;
  end;
var
  thRead: TThreadWrite;
  SignalGenForm: TSignalGenForm;
  //счетчик пакетов для частоты вывода
  pocketCount:integer;
  fileStream:TFileStream;
  //счетчик пакетов для пуменрации запис. пакетов. 0..65535
  pocketCountWWrite:word;
  geosPocket:TGeosRec;
  //массив - пакет сигнала
  signalPocket: array[1..POCKETSIZE] of byte;
  //Массив для хранения в кодах 0..255.
  //Data сигнал в кодах
  //DataF сигнал в физических величинах
  Data:array[1..N] of byte;
  DataF: array[1..N] of integer =
    (
  0,6,13,19,25,31,37,43,48,54,59,64,68,73,77,81,84,88,90,93,
  95,97,98,99,100,100,100,99,98,97,95,93,90,88,84,81,77,73,68,64,
  59,54,48,43,37,31,25,19,13,6,0,-6,-13,-19,-25,-31,-37,-43,-48,-54,
  -59,-64,-68,-73,-77,-81,-84,-88,-90,-93,-95,-97,-98,-99,-100,-100,-100,-99,-98,-97,
  -95,-93,-90,-88,-84,-81,-77,-73,-68,-64,-59,-54,-48,-43,-37,-31,-25,-19,-13,-6,
  0,6,13,19,25,31,37,43,48,54,59,64,68,73,77,81,84,88,90,93,
  95,97,98,99,100,100,100,99,98,97,95,93,90,88,84,81,77,73,68,64,
  59,54,48,43,37,31,25,19,13,6,0,-6,-13,-19,-25,-31,-37,-43,-48,-54,
  -59,-64,-68,-73,-77,-81,-84,-88,-90,-93,-95,-97,-98,-99,-100,-100,-100,-99,-98,-97,
  -95,-93,-90,-88,-84,-81,-77,-73,-68,-64,-59,-54,-48,-43,-37,-31,-25,-19,-13,-6,
  0,6,13,19,25,31,37,43,48,54,59,64,68,73,77,81,84,88,90,93,
  95,97,98,99,100,100,100,99,98,97,95,93,90,88,84,81,77,73,68,64,
  59,54,48,43,37,31,25,19,13,6,0,-6,-13,-19,-25,-31,-37,-43,-48,-54,
  -59,-64,-68,-73,-77,-81,-84,-88,-90,-93,-95,-97,-98,-99,-100,-100,-100,-99,-98,-97,
  -95,-93,-90,-88,-84,-81,-77,-73,-68,-64,-59,-54,-48,-43,-37,-31,-25,-19,-13,-6,
  0,6,13,19,25,31,37,43,48,54,59,64,68,73,77,81,84,88,90,93,
  95,97,98,99,100,100,100,99,98,97,95,93,90,88,84,81,77,73,68,64,
  59,54,48,43,37,31,25,19,13,6,0,-6,-13,-19,-25,-31,-37,-43,-48,-54,
  -59,-64,-68,-73,-77,-81,-84,-88,-90,-93,-95,-97,-98,-99,-100,-100,-100,-99,-98,-97,
  -95,-93,-90,-88,-84,-81,-77,-73,-68,-64,-59,-54,-48,-43,-37,-31,-25,-19,-13,-6,
  0,6,13,19,25,31,37,43,48,54,59,64,68,73,77,81,84,88,90,93,
  95,97,98,99,100,100,100,99,98,97,95,93,90,88,84,81,77,73,68,64,
  59,54,48,43,37,31,25,19,13,6,0,-6,-13,-19,-25,-31,-37,-43,-48,-54,
  -59,-64,-68,-73,-77,-81,-84,-88,-90,-93,-95,-97,-98,-99,-100,-100,-100,-99,-98,-97,
  -95,-93,-90,-88,-84,-81,-77,-73,-68,-64,-59,-54,-48,-43,-37,-31,-25,-19,-13,-6,
  0,6,13,19,25,31,37,43,48,54,59,64,68,73,77,81,84,88,90,93,
  95,97,98,99,100,100,100,99,98,97,95,93,90,88,84,81,77,73,68,64,
  59,54,48,43,37,31,25,19,13,6,0,-6,-13,-19,-25,-31,-37,-43,-48,-54,
  -59,-64,-68,-73,-77,-81,-84,-88,-90,-93,-95,-97,-98,-99,-100,-100,-100,-99,-98,-97,
  -95,-93,-90,-88,-84,-81,-77,-73,-68,-64,-59,-54,-48,-43,-37,-31,-25,-19,-13,-6,
  0,6,13,19,25,31,37,43,48,54,59,64,68,73,77,81,84,88,90,93,
  95,97,98,99,100,100,100,99,98,97,95,93,90,88,84,81,77,73,68,64,
  59,54,48,43,37,31,25,19,13,6,0,-6,-13,-19,-25,-31,-37,-43,-48,-54,
  -59,-64,-68,-73,-77,-81,-84,-88,-90,-93,-95,-97,-98,-99,-100,-100,-100,-99,-98,-97,
  -95,-93,-90,-88,-84,-81,-77,-73,-68,-64,-59,-54,-48,-43,-37,-31,-25,-19,-13,-6,
  0,6,13,19,25,31,37,43,48,54,59,64,68,73,77,81,84,88,90,93,
  95,97,98,99,100,100,100,99,98,97,95,93,90,88,84,81,77,73,68,64,
  59,54,48,43,37,31,25,19,13,6,0,-6,-13,-19,-25,-31,-37,-43,-48,-54,
  -59,-64,-68,-73,-77,-81,-84,-88,-90,-93,-95,-97,-98,-99,-100,-100,-100,-99,-98,-97,
  -95,-93,-90,-88,-84,-81,-77,-73,-68,-64,-59,-54,-48,-43,-37,-31,-25,-19,-13,-6,
  0,6,13,19,25,31,37,43,48,54,59,64,68,73,77,81,84,88,90,93,
  95,97,98,99,100,100,100,99,98,97,95,93,90,88,84,81,77,73,68,64,
  59,54,48,43,37,31,25,19,13,6,0,-6,-13,-19,-25,-31,-37,-43,-48,-54,
  -59,-64,-68,-73,-77,-81,-84,-88,-90,-93,-95,-97,-98,-99,-100,-100,-100,-99,-98,-97,
  -95,-93,-90,-88,-84,-81,-77,-73,-68,-64,-59,-54,-48,-43,-37,-31,-25,-19,-13,-6,
  0,6,13,19,25,31,37,43,48,54,59,64,68,73,77,81,84,88,90,93,
  95,97,98,99,100,100,100,99,98,97,95,93,90,88,84,81,77,73,68,64,
  59,54,48,43,37,31,25,19,13,6,0,-6,-13,-19,-25,-31,-37,-43,-48,-54,
  -59,-64,-68,-73,-77,-81,-84,-88,-90,-93,-95,-97,-98,-99,-100,-100,-100,-99,-98,-97,
  -95,-93,-90,-88,-84,-81,-77,-73,-68,-64,-59,-54,-48,-43,-37,-31,-25,-19,-13,-6
  );
  //байтовый массив записываемый в файл;
  arrayOfByte:byteArray;
  //счетчик номера позиции в байтовом массиве
  iArrayOfByte:integer;
  //массив слов значений записываемых в файл
  wordArr:wordArray;
  //счетчик номера позиции в массиве слов
  iWordArr:integer;
  //счетчик перебора данных сигнального массива
  dataCount:integer;
  countWriteByteInFile:cardinal;
  //храним значение медленных
  slowVal:word;
  //бинарный файл сигнала
  signalFile:file;
  //массив медленных параметров
  arrSlowParam:TSlowPar;
  pocketOffset:integer;
  countReadSlowP:integer;
  //счетчик прошедших секунд
  timeCount:integer;
  //счетчик выборки из массива слов
  wordCount:integer;
  koef:integer;
  koefVibSlowP:integer;
  pocketOffsetSlowP:integer;
  flag:boolean;
implementation

uses Math;

{$R *.dfm}

//==============================================================================
//
//==============================================================================
procedure WriteByteToByte(multiByteValue: byte;var arrayOfByte:byteArray;
  var arrayIndex:integer); overload;
var
j: integer;
begin
  //зависит от кол. байт переданной переменной
  for j := 1 to SizeOf(multiByteValue) do
  begin
    //заказали байт под данные
    SetLength(arrayOfByte,arrayIndex+1);
    //наложение байтовой маски и запись в массив
    arrayOfByte[arrayIndex] := multiByteValue and 255;
    inc(arrayIndex);
    //записываем на место младшего байта старший
    multiByteValue := multiByteValue shr 8;
  end;
end;

procedure WriteByteToByte(multiByteValue: word; var  arrayOfByte:byteArray;
  var arrayIndex:integer); overload;
var
j: integer;
begin
  for j := 1 to SizeOf(multiByteValue) do
  begin
    //заказали байт под данные
    SetLength(arrayOfByte,arrayIndex+1);
    arrayOfByte[arrayIndex] := multiByteValue and 255;
    inc(arrayIndex);
    multiByteValue := multiByteValue shr 8;
  end;
end;
//==============================================================================

//==============================================================================
//Запись медленных в пакет. Возвращает записаное значение медленных
//==============================================================================
procedure WriteSlowVal(pocketCount:word; var offsetCount:integer;
  var arrSlowP:TSlowPar; var iArrSlowPPrev:integer);
begin
  //pocketCount-номер пакета, offsetCount-смещение для записи значений быстрых в нужные пакеты
  //arrSlowP-массив значений медленных параметров для заполнения файла
  //iArrSlowPPrev-счетчик для правильной выборки повторяющихся значений медленных
  //запись в пакет медленных 2 байта медленных. Всего их 10. 5 раз по 2 байта
  //запись медленных с 0 пакета
  if (pocketCount mod (round(NUM_POCKET_IN_SEC/SAMPLING_FREQ_SLOW)+(offsetCount-1)))=0 then
  begin
    arrSlowP[offsetCount]:=Random(High(word));
    WriteByteToByte(arrSlowP[offsetCount],arrayOfByte,iArrayOfByte);
    inc(offsetCount);
    if offsetCount>NUM_SLOW_CHANAL then
    begin
      offsetCount:=1;
    end;
  end
  else
  begin
    WriteByteToByte(arrSlowP[iArrSlowPPrev],arrayOfByte,iArrayOfByte);
    inc(iArrSlowPPrev);
    if iArrSlowPPrev>NUM_SLOW_CHANAL then
    begin
      iArrSlowPPrev:=1;
    end;
  end;
end;
//==============================================================================

//==============================================================================
//Запись данных с ГЕОС пакет
//==============================================================================
procedure WriteGEOSParam(pocketCount:word; var offsetCount:integer);
begin
  //запись в пакет с ГЕОС
  if (pocketCount mod (NUM_POCKET_IN_SEC+offsetCount))=0 then
  begin
  end;
end;
//==============================================================================

//==============================================================================
//Запись данных в массив слов
//==============================================================================
procedure WriteToWordArray(multiByteValue: integer; var  arrayOfWord:wordArray;
  var arrayIndex:integer); overload;
var
j: integer;
begin
  j:=1;
  while j<=SizeOf(multiByteValue) do
  begin
    //заказали байт под данные
    SetLength(arrayOfWord,arrayIndex+1);
    //накладываем маску 2 байта
    arrayOfWord[arrayIndex] := multiByteValue and 65535;
    inc(arrayIndex);
    //сдвигаем по 2 байта
    multiByteValue := multiByteValue shr 16;
    j:=j+2;
  end;
end;

procedure WriteToWordArray(multiByteValue: int64; var  arrayOfWord:wordArray;
  var arrayIndex:integer); overload;
var
j: integer;
begin
  j:=1;
  while j<=SizeOf(multiByteValue) do
  begin
    //заказали байт под данные
    SetLength(arrayOfWord,arrayIndex+1);
    //накладываем маску 2 байта
    arrayOfWord[arrayIndex] := multiByteValue and 65535;
    inc(arrayIndex);
    //сдвигаем по 2 байта
    multiByteValue := multiByteValue shr 16;
    j:=j+2;
  end;
end;

procedure WriteToWordArray(multiByteValue: double; var  arrayOfWord:wordArray;
  var arrayIndex:integer); overload;
var
j: integer;
Pword: ^word;
begin
  j:=1;
  Pword:=@multiByteValue;
  while j<=SizeOf(multiByteValue) do
  begin
    //заказали байт под данные
    SetLength(arrayOfWord,arrayIndex+1);
    arrayOfWord[arrayIndex]:=pWord^;
    inc(arrayIndex);
    inc(pWord);
    j:=j+2;
  end;
end;
//==============================================================================

//==============================================================================
//Генератор пакета
//==============================================================================
procedure GenPocket(var pocketC:integer);
var
i:integer;
wordNull:word;
begin
  {if pocketCountWWrite=2046 then
    begin
      ShowMessage('11');
    end;}

  //запись счетчика. 2 байта
  WriteByteToByte(pocketCountWWrite,arrayOfByte,iArrayOfByte);
  //запись быстрых. 24 байта
  for i:=1 to POCKETSIZE-4 do
  begin
    //при переходе за пределы значений начинаем сначала
    if dataCount>length(data) then
      begin
        dataCount:=1;
      end;
    //SignalGenForm.Memo1.Lines.Add(intTostr(data[dataCount]));
    WriteByteToByte(Data[dataCount],arrayOfByte,iArrayOfByte);
  end;
  inc(dataCount);
  i:=i+2;

  //сформируем значения с ГЕОС. И запишем их в массив слов по 2байта
  //формируем каждые 2000
  if (pocketCountWWrite mod NUM_POCKET_IN_SEC)=0 then
  begin
    //пришел новый пакет данных с ГЕОС,
    //сбросим массив слов и счетчик слов
    wordArr:=nil;
    iWordArr:=0;

    geosPocket.time:=timeCount;
    WriteToWordArray(geosPocket.time,wordArr,iWordArr);
    inc(timeCount);
    if timeCount>=High(timeCount) then
    begin
      timeCount:=0;
    end;
    geosPocket.latitude:=0.947817116;
    WriteToWordArray(geosPocket.latitude,wordArr,iWordArr);
    geosPocket.longtitude:=0.639544114;
    WriteToWordArray(geosPocket.longtitude,wordArr,iWordArr);
    geosPocket.hOnElps:=10.0;
    WriteToWordArray(geosPocket.hOnElps,wordArr,iWordArr);
    geosPocket.deflGeoid:=10.0;
    WriteToWordArray(geosPocket.deflGeoid,wordArr,iWordArr);
    geosPocket.KAnum:=1;
    WriteToWordArray(geosPocket.KAnum,wordArr,iWordArr);
    geosPocket.transStatus:=10;
    WriteToWordArray(geosPocket.transStatus,wordArr,iWordArr);
    geosPocket.gDop:=10.0;
    WriteToWordArray(geosPocket.gDop,wordArr,iWordArr);
    geosPocket.pDop:=10.0;
    WriteToWordArray(geosPocket.pDop,wordArr,iWordArr);
    geosPocket.tDop:=10.0;
    WriteToWordArray(geosPocket.tDop,wordArr,iWordArr);
    geosPocket.hDop:=10.0;
    WriteToWordArray(geosPocket.hDop,wordArr,iWordArr);
    geosPocket.vDop:=10.0;
    WriteToWordArray(geosPocket.vDop,wordArr,iWordArr);
    geosPocket.flagD:=1;
    WriteToWordArray(geosPocket.flagD,wordArr,iWordArr);
    geosPocket.countDes:=10;
    WriteToWordArray(geosPocket.countDes,wordArr,iWordArr);
    //зададим скорость случайным образом от 30 до 150 км\ч
    geosPocket.planV:=RandomRange(30,150);
    WriteToWordArray(geosPocket.planV,wordArr,iWordArr);
    geosPocket.kurs:=111.0;
    WriteToWordArray(geosPocket.kurs,wordArr,iWordArr);
    geosPocket.sum:=777;
    WriteToWordArray(geosPocket.sum,wordArr,iWordArr);
  end;


  //запись данных с ГЕОС
  //NUM_BYTE_IN_GEOS_POCKET/2-сколько пакетов должны заполнить 0..59
  if ((pocketCountWWrite>=0) and (pocketCountWWrite<=(NUM_BYTE_IN_GEOS_POCKET/2)-1)) then
  begin
    { if pocketCountWWrite=56 then
    begin
      ShowMessage('333');
    end;}

    WriteByteToByte(wordArr[wordCount],arrayOfByte,iArrayOfByte);
    inc(wordCount);
    //проверяем не последний ли это заполняемый пакет в начале
    if (pocketCountWWrite=(NUM_BYTE_IN_GEOS_POCKET/2)-1) then
    begin
      wordCount:=0;
    end;
  end
  else
  begin
    {if pocketCountWWrite=3000 then
      begin
        ShowMessage('333');
      end;}

    if  ((pocketCountWWrite>=(NUM_BYTE_IN_GEOS_POCKET/2)) and
        (pocketCountWWrite<=(NUM_BYTE_IN_GEOS_POCKET/2+NUM_SLOW_CHANAL-1))) then
    begin
      //записываем данные медленных
      arrSlowParam[pocketOffset]:=2056{Random(High(word))};
      WriteByteToByte(arrSlowParam[pocketOffset],arrayOfByte,iArrayOfByte);
      inc(pocketOffset);
      if pocketOffset>NUM_SLOW_CHANAL then
      begin
        pocketOffset:=1;
      end;
    end
    else
    begin
      flag:=false;
      //проверяем нужно ли писать данные с ГЕОС каждые 2000 пакетов
      //koef-коэфициент масштабирования 1..N, для правильной выборки
      if (pocketCountWWrite mod (NUM_POCKET_IN_SEC*koef+(pocketOffset-1)))=0 then
      begin
        WriteByteToByte(wordArr[wordCount],arrayOfByte,iArrayOfByte);
        inc(wordCount);
        inc(pocketOffset);
        if wordCount>length(wordArr)-1 then
        begin
          wordCount:=0;
          pocketOffset:=1;
          inc(koef);
        end;
        flag:=true;
      end;
      {if pocketCountWWrite=460 then
      begin
        ShowMessage('333');
      end;}
      //проверяем не пора ли вставить данные медленных через каждые 260 пакетов
      if (pocketCountWWrite mod (round(NUM_POCKET_IN_SEC/SAMPLING_FREQ_SLOW)*koefVibSlowP+
            round(NUM_BYTE_IN_GEOS_POCKET/2)+(pocketOffsetSlowP-1)))=0 then
      begin
        arrSlowParam[pocketOffsetSlowP]:=2056{Random(High(word))};
        WriteByteToByte(arrSlowParam[pocketOffsetSlowP],arrayOfByte,iArrayOfByte);
        inc(pocketOffsetSlowP);
        if pocketOffsetSlowP>NUM_SLOW_CHANAL then
        begin
          pocketOffsetSlowP:=1;
          inc(koefVibSlowP);
        end;
        flag:=true;
      end;
      {if pocketCountWWrite=260 then
        begin
          ShowMessage('333');
        end;}
      if (not flag) then
      begin
        //двухбайтовый 0 для записи. В случае если в этих пакетах данные передаваться не должны
        wordNull:=0;
        WriteByteToByte(wordNull,arrayOfByte,iArrayOfByte);
      end;
    end;
  end;

  inc(pocketCountWWrite);
  //проверка на переполнения
  if pocketCountWWrite>High(pocketCountWWrite) then
  begin
    pocketCountWWrite:=0;
  end;
  inc(pocketC);
end;
//==============================================================================

//==============================================================================
//Запись переданного количества пакетов
//==============================================================================
procedure WritePocket;
var
i:integer;
begin
  try
    BlockWrite(signalFile,arrayOfByte[0],length(arrayOfByte)*Sizeof(byte));
  finally
  end;
end;
//==============================================================================

procedure TSignalGenForm.FormCreate(Sender: TObject);
begin
  pocketCount:=0;
  pocketCountWWrite:=0;
  dataCount:=1;
  countWriteByteInFile:=0;
  koef:=1;
  koefVibSlowP:=1;
end;

//==============================================================================
//Перевод значений массива сигнала из кодов в физич. величину
//==============================================================================
procedure TranslateKodToFval;
var
i:integer;
begin
  for i:=1 to N do
  begin
    data[i]:=dataF[i]+SDVIG;
  end;
end;
//==============================================================================

procedure TSignalGenForm.startGenClick(Sender: TObject);
begin
  TranslateKodToFval;
  if SignalGenForm.startGen.Caption='Gen' then
  begin
    //предустановочные значения
    pocketOffset:=1;
    pocketOffsetSlowP:=1;
    countReadSlowP:=1;
    timeCount:=0;
    SignalGenForm.startGen.Caption:='Stop';
    ShowMessage('Введите название файла сигнала');
    if SignalGenForm.SaveDialog1.Execute then
    begin
      //создаем файловый поток.
      //создаем файл с указаным именем, если файл создан то открываем на запись
      //fileStream:=TFileStream.Create(SignalGenForm.SaveDialog1.FileName,fmCreate);
      AssignFile(signalFile,SignalGenForm.SaveDialog1.FileName);
      rewrite(signalFile,1);
      SignalGenForm.signalTimer.Enabled:=true;
      //запускаем поток на запись
      thRead:=TThreadWrite.Create(False);
      thRead.Priority:=tpNormal;
    end
    else
    begin
      ShowMessage('Ошибка!');
    end;
  end
  else
  begin
    SignalGenForm.startGen.Caption:='Gen';   
    //завершаем поток записи
    thRead.Terminate;
    //закрываем файл сигнала
    //fileStream.Free;
    //CloseFile(signalFile);
  end;
end;

//==============================================================================
//
//==============================================================================
procedure TThreadWrite.Execute;
begin
  while (true) do
  begin
    if thRead.Terminated then
    begin
      SignalGenForm.signalTimer.Enabled:=false;
      break;
    end;
    GenPocket(pocketCount);
    if pocketCount=NUM_WRITE_POCKET then
    begin
      WritePocket;
      //записываем количество записанных в файл бaйт
      countWriteByteInFile :=countWriteByteInFile+iArrayOfByte;
      arrayOfByte:=nil;
      iArrayOfByte:=0;
      //барьер переполнения счетчика байт
      if countWriteByteInFile>High(countWriteByteInFile) then
      begin
        countWriteByteInFile:=0;
      end;
      pocketCount:=0;
    end;
  end;
end;
//==============================================================================


procedure TSignalGenForm.FormDestroy(Sender: TObject);
begin
  thRead.Terminate;
  showMessage('Файл записан!');
  CloseFile(signalFile);
end;

procedure TSignalGenForm.signalTimerTimer(Sender: TObject);
begin
  SignalGenForm.Label2.Caption:=IntToStr(countWriteByteInFile)+' '+'байт';
end;

end.
