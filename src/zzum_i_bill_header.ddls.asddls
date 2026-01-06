@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Basic view for Bill Header'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
define view entity zzum_I_bill_header
  as select from zzum_bill_header
  
{
  key bill_id                 as BillId,
      bill_type               as BillType,
      bill_date               as BillDate,
      customer_id             as CustomerId,
      @Semantics.amount.currencyCode: 'Currency'
      net_amount as NetAmount,
      currency                as Currency,
      sales_org               as SalesOrg,
      createdby               as Createdby,
      createdat               as Createdat,
      lastchangedby           as Lastchangedby,
      lastchangedat           as Lastchangedat,
      locallastchangedat      as Locallastchangedat
}
