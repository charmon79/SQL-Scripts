 
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

-- make display name for sent emails look like ServerName <noreply@foo.com>
DECLARE @display_name nvarchar(128) = cast(serverproperty('ServerName') as nvarchar(128))
 
-------------------------------------------------------------------------------------------------- 
-- BEGIN Mail Settings
-------------------------------------------------------------------------------------------------- 
IF NOT EXISTS(SELECT * FROM msdb.dbo.sysmail_profile WHERE  name = 'SQL Agent Mail Profile')  
  BEGIN 
    --CREATE Profile
    EXECUTE msdb.dbo.sysmail_add_profile_sp 
      @profile_name = 'SQL Agent Mail Profile', 
      @description  = ''; 
  END --IF EXISTS profile 
   
  IF NOT EXISTS(SELECT * FROM msdb.dbo.sysmail_account WHERE  name = 'SQL Agent SMTP') 
  BEGIN 
    --CREATE Account
    EXECUTE msdb.dbo.sysmail_add_account_sp 
    @account_name            = 'SQL Agent SMTP', 
    @email_address           = 'noreply@foo.com', 
    @display_name            = '', 
    @replyto_address         = '', 
    @description             = '', 
    @mailserver_name         = 'smtp.foo.com', 
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
              WHERE p.name = 'SQL Agent Mail Profile' 
                AND a.name = 'SQL Agent SMTP')  
  BEGIN 
    -- Associate Account
    EXECUTE msdb.dbo.sysmail_add_profileaccount_sp 
      @profile_name = 'SQL Agent Mail Profile', 
      @account_name = 'SQL Agent SMTP', 
      @sequence_number = 1 ; 
  END  
