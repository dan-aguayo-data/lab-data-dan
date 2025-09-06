SELECT
A.MULTI_SCHEME_ID AS MULTI_SCHEME_ID
, SCHEME.NAME AS SCHEME
, A.POS_TXN_NUM AS POS_TXN_NUM
, A.CONSUMER_ID AS CONSUMER_ID
, A.PAYMENT_METHOD AS PAYMENT_METHOD
, A.TRANSACTION_DATE AS TRANSACTION_DATE_UTC
, A.AMOUNT AS AMOUNT
, A.TRANSACTION_STATUS AS TRANSACTION_STATUS
, A.PAY_REF_NUMBER AS PAY_REF_NUMBER
, A.BANK_DETAILS_UPDATED_ON AS BANK_DETAILS_UPDATED_ON
, A.ACTION AS ACTION
, I.CLAIMSTATUS AS CLAIMSTATUS
, CONVERT_TIMEZONE('UTC',SCHEME.TIMEZONE,CAST(A.TRANSACTION_DATE AS TIMESTAMP)) AS TRANSACTION_DATE
, TO_CHAR(CONVERT_TIMEZONE('UTC',SCHEME.TIMEZONE,CAST(A.TRANSACTION_DATE AS TIMESTAMP)),'YYYYMMDD') AS TRANSACTION_DATE_KEY
FROM
(
    SELECT pth.pos_txn_num
         , pth.participant_number                     as CONSUMER_ID
         , pth.payment_method
         , pth.created_on                             as TRANSACTION_DATE
         , pth.amount
         , pss.status                                 as TRANSACTION_STATUS
         , pth.multi_scheme_id
         , pth.pay_ref_number
         , ppp.last_modified_on                       as bank_details_updated_on
         , 'Customer need to update the Bank Details' as Action
    FROM {{ source('CES_MSCM', 'PYMT_TRANSACTION_HEADERS') }} AS PTH
        inner join (SELECT DISTINCT
        PYMT_TRXN_HEADER_ID,
        STATUS
        FROM  {{ source('CES_MSCM', 'PYMT_PAYMENT_STATUS')}} 
        where  status IN ( 'ERROR_PAID', 'ERROR_PROCESSING' ))AS PSS
            on pth.pymt_trxn_header_id = pss.pymt_trxn_header_id
              
        inner join
        (
            SELECT phd.pos_txn_num
                 , MAX(phd.pymt_trxn_header_id) pymt_trxn_header_id
            FROM {{ source('CES_MSCM', 'PYMT_TRANSACTION_HEADERS') }} AS PHD
            GROUP BY phd.pos_txn_num
        )                                           ph
            on pth.pymt_trxn_header_id = ph.pymt_trxn_header_id
        INNER JOIN (
            SELECT
            P.MULTI_SCHEME_ID, 
            P.PARTICIPANT_SITE_ID,
            P.LAST_MODIFIED_ON
            FROM {{ source('CES_MSCM', 'PYMT_PAY_PARTY_PROFILES') }} AS P
            WHERE CAST(SYSDATE() AS DATE) BETWEEN P.START_DATE_ACTIVE AND nvl(P.END_DATE_ACTIVE, CAST(SYSDATE() AS DATE))
            QUALIFY ROW_NUMBER() OVER (PARTITION BY P.MULTI_SCHEME_ID, P.PARTICIPANT_SITE_ID ORDER BY LAST_MODIFIED_ON DESC) = 1
        ) PPP
            on ppp.participant_site_id = pth.participant_site_id
        left join
        (
            select distinct
                pps.pymt_trxn_header_id
            from {{ source('CES_MSCM', 'PYMT_PAYMENT_STATUS') }} AS PPS
            where pps.status = 'PAID'
        )                                           p
            on p.pymt_trxn_header_id = ph.pymt_trxn_header_id
    where p.pymt_trxn_header_id is null
    UNION ALL
    SELECT hdr1.id                  as pos_txn_num
         , hdr1.consumer_id
         , hdr1.payment_method
         , hdr1.transacted_on       as TRANSACTION_DATE
         , SUM(dtl1.gross_amount)   as AMOUNT
         , hdr1.status              as TRANSACTION_STATUS
         , hdr1.multi_scheme_id
         , null                     as pay_ref_number
         , max(pp.last_modified_on) as bank_details_updated_on
         , case
               when count(pp.scheme_participant_id) = 0 then
                   'No Bank Details in PAAS'
               else
                   'Bank Details Available in PAAS,need to reprocess the payment'
           end                      as Action
    FROM {{ source('CES_MSCM', 'CONSUMER_REFUND_TXN_HDR') }} AS HDR1
        inner join {{ source('CES_MSCM', 'CONSUMER_REFUND_TXN_DTL') }} AS DTL1
            on dtl1.transaction_id = hdr1.id
         LEFT JOIN (
            SELECT
            P.MULTI_SCHEME_ID, 
            P.SCHEME_PARTICIPANT_ID,
            P.LAST_MODIFIED_ON
            FROM {{ source('CES_MSCM', 'PYMT_PAY_PARTY_PROFILES') }} AS P
            WHERE CAST(SYSDATE() AS DATE) BETWEEN P.START_DATE_ACTIVE AND nvl(P.END_DATE_ACTIVE, CAST(SYSDATE() AS DATE))
            QUALIFY ROW_NUMBER() OVER (PARTITION BY P.MULTI_SCHEME_ID, P.SCHEME_PARTICIPANT_ID ORDER BY LAST_MODIFIED_ON DESC) = 1
         ) PP
            on (pp.scheme_participant_id = hdr1.consumer_id OR pp.scheme_participant_id = hdr1.consumer_id || '002')
            AND PP.MULTI_SCHEME_ID = HDR1.MULTI_SCHEME_ID
    where hdr1.payment_method = 'SCHEME'
          and hdr1.status = 'FINAL'
    GROUP BY hdr1.id
           , hdr1.consumer_id
           , hdr1.payment_method
           , hdr1.transacted_on
           , hdr1.status
           , hdr1.multi_scheme_id
    UNION ALL
    SELECT pth.pos_txn_num
         , pth.participant_number                                                   as consumer_id
         , pth.payment_method
         , pth.created_on                                                           as transaction_date
         , pth.amount
         , pss.status                                                               as transaction_status
         , pth.multi_scheme_id
         , pth.pay_ref_number
         , ppp.last_modified_on                                                     as bank_details_updated_on
         , 'Return Payments from bank,Waiting from customer to update bank details' as Action
    FROM {{ source('CES_MSCM', 'PYMT_TRANSACTION_HEADERS') }} AS PTH
        inner join (
            SELECT
            PPS.PAYMENT_STATUS_ID
            , PPS.PYMT_TRXN_HEADER_ID
            , PPS.STATUS
            , PPS.EFFECTIVE_FROM
            FROM
            {{ source('CES_MSCM', 'PYMT_PAYMENT_STATUS') }} AS PPS
            QUALIFY ROW_NUMBER() OVER (PARTITION BY PPS.PYMT_TRXN_HEADER_ID, PPS.STATUS ORDER BY PPS.PAYMENT_STATUS_ID DESC) = 1
            ) PSS
            on pth.pymt_trxn_header_id = pss.pymt_trxn_header_id
        inner join
        (
            SELECT pos_txn_num
                 , MAX(pymt_trxn_header_id) pymt_trxn_header_id
            FROM {{ source('CES_MSCM', 'PYMT_TRANSACTION_HEADERS') }} AS P
            GROUP BY pos_txn_num
        )                                           ph
            on pth.pymt_trxn_header_id = ph.pymt_trxn_header_id
        INNER JOIN (
            SELECT
            P.MULTI_SCHEME_ID, 
            P.PARTICIPANT_SITE_ID,
            P.LAST_MODIFIED_ON
            FROM {{ source('CES_MSCM', 'PYMT_PAY_PARTY_PROFILES') }} AS P
            WHERE CAST(SYSDATE() AS DATE) BETWEEN P.START_DATE_ACTIVE AND nvl(P.END_DATE_ACTIVE, CAST(SYSDATE() AS DATE))
            QUALIFY ROW_NUMBER() OVER (PARTITION BY P.MULTI_SCHEME_ID, P.PARTICIPANT_SITE_ID ORDER BY LAST_MODIFIED_ON DESC) = 1
        ) PPP
            on ppp.participant_site_id = pth.participant_site_id
               AND pss.status = 'VOID'
        left join
        (
            select pth1.pos_txn_num
                 , max(pps.effective_from) as effective_from
            from {{ source('CES_MSCM', 'PYMT_PAYMENT_STATUS') }} AS PPS
                inner join {{ source('CES_MSCM', 'PYMT_TRANSACTION_HEADERS') }} AS PTH1
                    ON pps.pymt_trxn_header_id = pth1.pymt_trxn_header_id
                       and pps.STATUS = 'PAID'
            group by pth1.pos_txn_num
        )                                           x
            on x.pos_txn_num = ph.pos_txn_num
    WHERE x.effective_from < pss.effective_from
)                                                A
left join {{ source('CRM', 'EXPORTREPORTINCIDENTS') }} AS I
on I.PAYMENTS_POSTRANSACTIONID = A.POS_TXN_NUM
INNER JOIN {{ source('CES_MSCM', 'SCHEME') }} AS SCHEME
ON A.MULTI_SCHEME_ID = SCHEME.MULTI_SCHEME_ID