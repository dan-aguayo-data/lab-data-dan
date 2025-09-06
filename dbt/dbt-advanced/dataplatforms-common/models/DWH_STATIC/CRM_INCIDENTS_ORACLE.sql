
--temporary static table, this can be deleted once the Power BI models have been cleaned up from it. 

select 
* 
from 
{{ source('CES_REFERENCE', 'CRM_INCIDENTS_ORACLE') }} 
