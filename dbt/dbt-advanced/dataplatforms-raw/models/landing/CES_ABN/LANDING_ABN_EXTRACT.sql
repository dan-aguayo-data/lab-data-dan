{%- set trimmed_source_rel = model.name | replace("LANDING_","") -%}

{{  
    config(
        alias=trimmed_source_rel
    )
}}

WITH SOURCE as (
  
    SELECT MESSAGE FROM {{ source('SNOWPIPE_PROD', 'CES_ABN_PROD') }}
    where 
    split_part(FILE_NAME, '_', 1) =
    (
      select split_part(FILE_NAME, '_', 1) from {{ source('SNOWPIPE_PROD', 'CES_ABN_PROD') }}
      QUALIFY row_number() OVER (PARTITION BY 'ABN' ORDER BY LANDED_DATETIME DESC) = 1
    ) 

), topLevel as (

    select    
         XMLGET( MESSAGE, 'ABN' ):"$"::INTEGER AS ABN
        ,GET(MESSAGE, '@recordLastUpdatedDate')::string as ABR_recordLastUpdatedDate
        ,GET(MESSAGE, '@replaced')::string as ABR_replaced           
        ,GET( XMLGET( MESSAGE, 'ABN'), '@ABNStatusFromDate')::string as ABNStatusFromDate
        ,GET( XMLGET( MESSAGE, 'ABN'), '@status')::string as ABNStatus
        ,GET( XMLGET( MESSAGE, 'GST'), '@GSTStatusFromDate')::string as GSTStatusFromDate
        ,GET( XMLGET( MESSAGE, 'GST'), '@status')::string as GSTStatus
        ,GET( XMLGET( MESSAGE, 'ASICNumber'), '@ASICNumberType')::string as ASICNumberType
        ,XMLGET( MESSAGE, 'ASICNumber' ):"$"::INTEGER AS ASICNumber
        ,XMLGET(EntityType.VALUE, 'EntityTypeInd' ):"$"::string AS EntityTypeInd 
        ,XMLGET(EntityType.VALUE, 'EntityTypeText' ):"$"::string AS EntityTypeText
        ,MESSAGE
    from SOURCE
         ,lateral FLATTEN(source.MESSAGE:"$") EntityType
    where XMLGET( source.MESSAGE, 'ABN' ):"$"::INTEGER is not null
    and GET( EntityType.value, '@') = 'EntityType'
  
) 
, OtherEntity as (

    select
         topLevel.ABN
        ,GET(XMLGET(OtherEntity.VALUE, 'NonIndividualName' ), '@type')::string AS OE_NonIndividualName_type
        ,OtherEntity.VALUE as OE_VALUE
    from
    topLevel
   ,lateral FLATTEN(topLevel.MESSAGE:"$") OtherEntity
    where GET( OtherEntity.value, '@') ='OtherEntity'

) 
, OtherEntity_NonIndividualName as (

    select 
         OtherEntity.ABN
        ,listagg(OtherEntity.OE_NonIndividualName_type, ', ') WITHIN GROUP (ORDER BY OtherEntity.OE_NonIndividualName_type DESC) OE_NonIndividualName_type
        ,listagg(XMLGET(OtherEntity_NonIndividualName.THIS, 'NonIndividualNameText' ):"$"::string, ', ') WITHIN GROUP (ORDER BY OtherEntity.OE_NonIndividualName_type DESC) OE_NonIndividualNameText
        --,OtherEntity.OE_NonIndividualName_type
        --,XMLGET(OtherEntity_NonIndividualName.THIS, 'NonIndividualNameText' ):"$"::string AS OE_NonIndividualNameText
    from
    OtherEntity
   ,lateral FLATTEN(OtherEntity.OE_VALUE:"$") OtherEntity_NonIndividualName
    where GET( OtherEntity_NonIndividualName.value, '@') ='NonIndividualNameText'
    group by OtherEntity.ABN

) 
, LegalEntity as (

    select
         topLevel.ABN
        ,GET(XMLGET(LegalEntity.VALUE, 'IndividualName' ), '@type')::string AS IndividualName_type
        ,GET(XMLGET(LegalEntity.VALUE, 'NonIndividualName' ), '@type')::string AS NonIndividualName_type
        ,LegalEntity.VALUE as LE_VALUE
    from
    topLevel
   ,lateral FLATTEN(topLevel.MESSAGE:"$") LegalEntity
    where GET( LegalEntity.value, '@') in ('LegalEntity','MainEntity')

) 
, IndividualName as (

    select
         LegalEntity.ABN
        ,XMLGET(IndividualName.VALUE, 'GivenName' ):"$"::string AS GivenName
        ,XMLGET(IndividualName.VALUE, 'FamilyName' ):"$"::string AS FamilyName
        ,XMLGET(IndividualName.VALUE, 'NonIndividualNameText' ):"$"::string AS NonIndividualNameText  
        --,LegalEntity.LE_VALUE
    from
    LegalEntity
   ,lateral FLATTEN(LegalEntity.LE_VALUE:"$") IndividualName
    where GET( IndividualName.value, '@') in ('IndividualName','NonIndividualName')

) 
, BusinessAddress as (

    select
         LegalEntity.ABN
        ,BusinessAddress.VALUE as BA_VALUE
    from
    LegalEntity
   ,lateral FLATTEN(LegalEntity.LE_VALUE:"$") BusinessAddress
    where GET( BusinessAddress.value, '@') = 'BusinessAddress'

) 
, AddressDetails as (

    select 
         BusinessAddress.ABN
        ,XMLGET(AddressDetails.THIS, 'State' ):"$"::string AS State
        ,XMLGET(AddressDetails.THIS, 'Postcode' ):"$"::string AS Postcode
    from
    BusinessAddress
   ,lateral FLATTEN(BusinessAddress.BA_VALUE:"$") AddressDetails
    where AddressDetails.VALUE  = 'AddressDetails'

)
, final as (

  select 
     topLevel.ABN
    ,to_date(nullif(topLevel.ABR_recordLastUpdatedDate,''), 'YYYYMMDD') as ABR_recordLastUpdatedDate
    ,topLevel.ABR_replaced
    ,to_date(nullif(topLevel.ABNStatusFromDate,''), 'YYYYMMDD') as ABNStatusFromDate
    ,topLevel.ABNStatus
    ,to_date(nullif(topLevel.GSTStatusFromDate,''), 'YYYYMMDD') as GSTStatusFromDate
    ,topLevel.GSTStatus
    ,topLevel.EntityTypeInd
    ,topLevel.EntityTypeText
    ,topLevel.ASICNumberType
    ,topLevel.ASICNumber
    ,LegalEntity.IndividualName_type
    ,LegalEntity.NonIndividualName_type
    ,IndividualName.GivenName
    ,IndividualName.FamilyName
    ,IndividualName.NonIndividualNameText
    ,OtherEntity_NonIndividualName.OE_NonIndividualName_type
    ,OtherEntity_NonIndividualName.OE_NonIndividualNameText
    ,AddressDetails.State
    ,AddressDetails.Postcode
    ,topLevel.MESSAGE
  from topLevel 
  left join LegalEntity on topLevel.ABN = LegalEntity.ABN
  left join IndividualName on topLevel.ABN = IndividualName.ABN
  left join OtherEntity_NonIndividualName on topLevel.ABN = OtherEntity_NonIndividualName.ABN
  left join AddressDetails on topLevel.ABN = AddressDetails.ABN

) select * from final