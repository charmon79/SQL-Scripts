
select
    a.account_id
,   a.name
,   s.servername
,   a.email_address
from msdb..sysmail_account a
join msdb..sysmail_server s on s.account_id = a.account_id
where 1=1
    --a.name = 'SQL Agent SMTP'
    and s.servername = 'smtp.foobar.com'

