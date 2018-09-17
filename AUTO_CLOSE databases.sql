select name, 'ALTER DATABASE '+quotename(name)+' SET AUTO_CLOSE OFF' AS sql_command
from sys.databases
where is_auto_close_on = 1
and state = 0