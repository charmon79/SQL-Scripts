select distinct
    left(physical_name, len(physical_name) - charindex('\', reverse(physical_name)))
from
    sys.master_files