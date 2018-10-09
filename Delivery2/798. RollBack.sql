Use Portal_Data
Go

If Exists (Select *
			From sys.tables t
			Join sys.schemas s on t.schema_id = s.schema_id
			Where t.Name = 'PromotionChannel'
			And s.Name = 'PreCal')
Begin
	Drop Table [PreCal].[PromotionChannel]
End
Go
