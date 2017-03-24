unit SignalGenU;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls;

const
  //���������� ������������ �������. �� ���
  NUM_WRITE_POCKET=5000;//100;
  //����������� ������ ������, � ��������� ������ ����(28)
  POCKETSIZE=28;
  N=1000;
  //N=100;
  //N=512;
  //N=4096;
  //�������� ������ ��� ����������� ���������� ��������
  SDVIG=100;
  //���������� ������� � �������
  NUM_POCKET_IN_SEC=2000;
  //������� ������(�������������) ���������; ��
  SAMPLING_FREQ_SLOW=10;
  //���������� ������� ���������
  NUM_SLOW_CHANAL=5;
  //���������� ���� ������ � ������ ���� . 30 ���� �� 4 �����
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

  //����� ��� ������
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
    //1 ����� GEOS 4 �����
    //�����. ������ �� 1 ������ 2008 ����  .8�
    time:int64;
    //������. ������� 8�
    latitude:double;
    //�������. ������� 8�
    longtitude:double;
    //������ ��� ���������� 8�
    hOnElps:double;
    //���������� ��������� �� ������ 8�
    deflGeoid:double;
    //����� �� 4
    KAnum:integer;
    //��������� ��������� 4
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
    //���� ������������� 4
    flagD:integer;
    //����. ����. �������  4
    countDes:integer;
    //��������  8
    planV:double;
    //���� 8
    kurs:double;
    //�����. ����� 8
    sum:int64;
  end;
var
  thRead: TThreadWrite;
  SignalGenForm: TSignalGenForm;
  //������� ������� ��� ������� ������
  pocketCount:integer;
  fileStream:TFileStream;
  //������� ������� ��� ���������� �����. �������. 0..65535
  pocketCountWWrite:word;
  geosPocket:TGeosRec;
  //������ - ����� �������
  signalPocket: array[1..POCKETSIZE] of byte;
  //������ ��� �������� � ����� 0..255.
  //Data ������ � �����
  //DataF ������ � ���������� ���������
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
  //�������� ������ ������������ � ����;
  arrayOfByte:byteArray;
  //������� ������ ������� � �������� �������
  iArrayOfByte:integer;
  //������ ���� �������� ������������ � ����
  wordArr:wordArray;
  //������� ������ ������� � ������� ����
  iWordArr:integer;
  //������� �������� ������ ����������� �������
  dataCount:integer;
  countWriteByteInFile:cardinal;
  //������ �������� ���������
  slowVal:word;
  //�������� ���� �������
  signalFile:file;
  //������ ��������� ����������
  arrSlowParam:TSlowPar;
  pocketOffset:integer;
  countReadSlowP:integer;
  //������� ��������� ������
  timeCount:integer;
  //������� ������� �� ������� ����
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
  //������� �� ���. ���� ���������� ����������
  for j := 1 to SizeOf(multiByteValue) do
  begin
    //�������� ���� ��� ������
    SetLength(arrayOfByte,arrayIndex+1);
    //��������� �������� ����� � ������ � ������
    arrayOfByte[arrayIndex] := multiByteValue and 255;
    inc(arrayIndex);
    //���������� �� ����� �������� ����� �������
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
    //�������� ���� ��� ������
    SetLength(arrayOfByte,arrayIndex+1);
    arrayOfByte[arrayIndex] := multiByteValue and 255;
    inc(arrayIndex);
    multiByteValue := multiByteValue shr 8;
  end;
end;
//==============================================================================

//==============================================================================
//������ ��������� � �����. ���������� ��������� �������� ���������
//==============================================================================
procedure WriteSlowVal(pocketCount:word; var offsetCount:integer;
  var arrSlowP:TSlowPar; var iArrSlowPPrev:integer);
begin
  //pocketCount-����� ������, offsetCount-�������� ��� ������ �������� ������� � ������ ������
  //arrSlowP-������ �������� ��������� ���������� ��� ���������� �����
  //iArrSlowPPrev-������� ��� ���������� ������� ������������� �������� ���������
  //������ � ����� ��������� 2 ����� ���������. ����� �� 10. 5 ��� �� 2 �����
  //������ ��������� � 0 ������
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
//������ ������ � ���� �����
//==============================================================================
procedure WriteGEOSParam(pocketCount:word; var offsetCount:integer);
begin
  //������ � ����� � ����
  if (pocketCount mod (NUM_POCKET_IN_SEC+offsetCount))=0 then
  begin
  end;
end;
//==============================================================================

//==============================================================================
//������ ������ � ������ ����
//==============================================================================
procedure WriteToWordArray(multiByteValue: integer; var  arrayOfWord:wordArray;
  var arrayIndex:integer); overload;
var
j: integer;
begin
  j:=1;
  while j<=SizeOf(multiByteValue) do
  begin
    //�������� ���� ��� ������
    SetLength(arrayOfWord,arrayIndex+1);
    //����������� ����� 2 �����
    arrayOfWord[arrayIndex] := multiByteValue and 65535;
    inc(arrayIndex);
    //�������� �� 2 �����
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
    //�������� ���� ��� ������
    SetLength(arrayOfWord,arrayIndex+1);
    //����������� ����� 2 �����
    arrayOfWord[arrayIndex] := multiByteValue and 65535;
    inc(arrayIndex);
    //�������� �� 2 �����
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
    //�������� ���� ��� ������
    SetLength(arrayOfWord,arrayIndex+1);
    arrayOfWord[arrayIndex]:=pWord^;
    inc(arrayIndex);
    inc(pWord);
    j:=j+2;
  end;
end;
//==============================================================================

//==============================================================================
//��������� ������
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

  //������ ��������. 2 �����
  WriteByteToByte(pocketCountWWrite,arrayOfByte,iArrayOfByte);
  //������ �������. 24 �����
  for i:=1 to POCKETSIZE-4 do
  begin
    //��� �������� �� ������� �������� �������� �������
    if dataCount>length(data) then
      begin
        dataCount:=1;
      end;
    //SignalGenForm.Memo1.Lines.Add(intTostr(data[dataCount]));
    WriteByteToByte(Data[dataCount],arrayOfByte,iArrayOfByte);
  end;
  inc(dataCount);
  i:=i+2;

  //���������� �������� � ����. � ������� �� � ������ ���� �� 2�����
  //��������� ������ 2000
  if (pocketCountWWrite mod NUM_POCKET_IN_SEC)=0 then
  begin
    //������ ����� ����� ������ � ����,
    //������� ������ ���� � ������� ����
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
    //������� �������� ��������� ������� �� 30 �� 150 ��\�
    geosPocket.planV:=RandomRange(30,150);
    WriteToWordArray(geosPocket.planV,wordArr,iWordArr);
    geosPocket.kurs:=111.0;
    WriteToWordArray(geosPocket.kurs,wordArr,iWordArr);
    geosPocket.sum:=777;
    WriteToWordArray(geosPocket.sum,wordArr,iWordArr);
  end;


  //������ ������ � ����
  //NUM_BYTE_IN_GEOS_POCKET/2-������� ������� ������ ��������� 0..59
  if ((pocketCountWWrite>=0) and (pocketCountWWrite<=(NUM_BYTE_IN_GEOS_POCKET/2)-1)) then
  begin
    { if pocketCountWWrite=56 then
    begin
      ShowMessage('333');
    end;}

    WriteByteToByte(wordArr[wordCount],arrayOfByte,iArrayOfByte);
    inc(wordCount);
    //��������� �� ��������� �� ��� ����������� ����� � ������
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
      //���������� ������ ���������
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
      //��������� ����� �� ������ ������ � ���� ������ 2000 �������
      //koef-���������� ��������������� 1..N, ��� ���������� �������
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
      //��������� �� ���� �� �������� ������ ��������� ����� ������ 260 �������
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
        //������������ 0 ��� ������. � ������ ���� � ���� ������� ������ ������������ �� ������
        wordNull:=0;
        WriteByteToByte(wordNull,arrayOfByte,iArrayOfByte);
      end;
    end;
  end;

  inc(pocketCountWWrite);
  //�������� �� ������������
  if pocketCountWWrite>High(pocketCountWWrite) then
  begin
    pocketCountWWrite:=0;
  end;
  inc(pocketC);
end;
//==============================================================================

//==============================================================================
//������ ����������� ���������� �������
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
//������� �������� ������� ������� �� ����� � �����. ��������
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
    //���������������� ��������
    pocketOffset:=1;
    pocketOffsetSlowP:=1;
    countReadSlowP:=1;
    timeCount:=0;
    SignalGenForm.startGen.Caption:='Stop';
    ShowMessage('������� �������� ����� �������');
    if SignalGenForm.SaveDialog1.Execute then
    begin
      //������� �������� �����.
      //������� ���� � �������� ������, ���� ���� ������ �� ��������� �� ������
      //fileStream:=TFileStream.Create(SignalGenForm.SaveDialog1.FileName,fmCreate);
      AssignFile(signalFile,SignalGenForm.SaveDialog1.FileName);
      rewrite(signalFile,1);
      SignalGenForm.signalTimer.Enabled:=true;
      //��������� ����� �� ������
      thRead:=TThreadWrite.Create(False);
      thRead.Priority:=tpNormal;
    end
    else
    begin
      ShowMessage('������!');
    end;
  end
  else
  begin
    SignalGenForm.startGen.Caption:='Gen';   
    //��������� ����� ������
    thRead.Terminate;
    //��������� ���� �������
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
      //���������� ���������� ���������� � ���� �a��
      countWriteByteInFile :=countWriteByteInFile+iArrayOfByte;
      arrayOfByte:=nil;
      iArrayOfByte:=0;
      //������ ������������ �������� ����
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
  showMessage('���� �������!');
  CloseFile(signalFile);
end;

procedure TSignalGenForm.signalTimerTimer(Sender: TObject);
begin
  SignalGenForm.Label2.Caption:=IntToStr(countWriteByteInFile)+' '+'����';
end;

end.
