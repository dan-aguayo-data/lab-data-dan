select 
ID
,VALUE
,TICKET_CUSTOM_FIELD_ID
,NAME
,CASE 
    WHEN NAME in ('General public','Member','Registered customer') THEN 'Consumer'
    WHEN NAME in ('Community Group','Charity') THEN 'Not For Profit'
    WHEN NAME in ('Community Business') THEN 'Business/Commercial'
    ELSE 'Unmapped'
 END AS CUSTOMER_TYPE_MAPPING
from {{ source('CES_ZENDESK', 'TICKET_FIELD_OPTION') }}
where TICKET_CUSTOM_FIELD_ID = 7614369633423