object SignalGenForm: TSignalGenForm
  Left = 192
  Top = 124
  Width = 400
  Height = 268
  Caption = 'SignalGen'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 48
    Top = 152
    Width = 317
    Height = 20
    Caption = #1050#1086#1083#1080#1095#1077#1089#1090#1074#1086' '#1079#1072#1087#1080#1089#1072#1085#1085#1099#1093' '#1074' '#1092#1072#1081#1083' '#1073#1072#1081#1090
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = 'MS Sans Serif'
    Font.Style = [fsBold]
    ParentFont = False
  end
  object Label2: TLabel
    Left = 136
    Top = 200
    Width = 6
    Height = 29
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clGreen
    Font.Height = -25
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ParentFont = False
  end
  object startGen: TButton
    Left = 128
    Top = 56
    Width = 113
    Height = 81
    Caption = 'Gen'
    TabOrder = 0
    OnClick = startGenClick
  end
  object signalTimer: TTimer
    Enabled = False
    Interval = 55
    OnTimer = signalTimerTimer
    Left = 16
    Top = 8
  end
  object SaveDialog1: TSaveDialog
    FileName = 'C:\Users\DmitriX\Desktop\SKRUTZHT 1'
    Left = 48
    Top = 8
  end
end
