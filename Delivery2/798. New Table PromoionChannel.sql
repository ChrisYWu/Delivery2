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

-------------------------------
CREATE TABLE [PreCal].[PromotionChannel](
	[PromotionID] [int] NOT NULL,
	[ChannelID] [int] NOT NULL,
	CONSTRAINT [PK_PromotionChannel] PRIMARY KEY CLUSTERED 
(
	[PromotionID] ASC,
	[ChannelID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
Go

----- Inital Load
Truncate Table PreCal.PromotionChannel
Go

Insert PreCal.PromotionChannel
Select Distinct PromotionID, c.ChannelID
From Playbook.PromotionChannel pc
Join SAP.Channel c on pc.SuperChannelID = c.SuperChannelID
Union
Select PromotionID, ChannelID
From Playbook.PromotionChannel pc
Where ChannelID is not null
Go

