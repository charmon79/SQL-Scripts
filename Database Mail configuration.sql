 
use master 
go 
sp_configure 'show advanced options',1 
go 
reconfigure with override 
go 
sp_configure 'Database Mail XPs',1 
--go 
--sp_configure 'SQL Mail XPs',0 
go 
reconfigure 
go 

-- make display name for sent emails look like ServerName <noreply@rtsfinancial.com>
DECLARE @display_name nvarchar(128) = cast(serverproperty('ServerName') as nvarchar(128))
 
-------------------------------------------------------------------------------------------------- 
-- BEGIN Mail Settings Shamrock Mail Profile 
-------------------------------------------------------------------------------------------------- 
IF NOT EXISTS(SELECT * FROM msdb.dbo.sysmail_profile WHERE  name = 'Shamrock Mail Profile')  
  BEGIN 
    --CREATE Profile [Shamrock Mail Profile] 
    EXECUTE msdb.dbo.sysmail_add_profile_sp 
      @profile_name = 'Shamrock Mail Profile', 
      @description  = ''; 
  END --IF EXISTS profile 
   
  IF NOT EXISTS(SELECT * FROM msdb.dbo.sysmail_account WHERE  name = 'Shamrock SMTP') 
  BEGIN 
    --CREATE Account [Shamrock SMTP] 
    EXECUTE msdb.dbo.sysmail_add_account_sp 
    @account_name            = 'Shamrock SMTP', 
    @email_address           = 'noreply@rtsfinancial.com', 
    @display_name            = '', 
    @replyto_address         = '', 
    @description             = '', 
    @mailserver_name         = 'smtp.ryanrts.com', 
    @mailserver_type         = 'SMTP', 
    @port                    = '25', 
    @username                =  NULL , 
    @password                =  NULL ,  
    @use_default_credentials =  0 , 
    @enable_ssl              =  0 ; 
  END --IF EXISTS  account 
   
IF NOT EXISTS(SELECT * 
              FROM msdb.dbo.sysmail_profileaccount pa 
                INNER JOIN msdb.dbo.sysmail_profile p ON pa.profile_id = p.profile_id 
                INNER JOIN msdb.dbo.sysmail_account a ON pa.account_id = a.account_id   
              WHERE p.name = 'Shamrock Mail Profile' 
                AND a.name = 'Shamrock SMTP')  
  BEGIN 
    -- Associate Account [Shamrock SMTP] to Profile [Shamrock Mail Profile] 
    EXECUTE msdb.dbo.sysmail_add_profileaccount_sp 
      @profile_name = 'Shamrock Mail Profile', 
      @account_name = 'Shamrock SMTP', 
      @sequence_number = 1 ; 
  END  
