program SignalGenP;

uses
  Forms,
  SignalGenU in 'SignalGenU.pas' {SignalGenForm};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TSignalGenForm, SignalGenForm);
  Application.Run;
end.
