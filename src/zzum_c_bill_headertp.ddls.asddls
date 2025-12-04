@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Consumption view for Bill doc'

@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true

@VDM.viewType: #CONSUMPTION

define root view entity zzum_C_bill_headerTP
provider contract transactional_query
  as projection on zzum_R_bill_header

{
  key BillId,

      BillType,
      BillDate,
      CustomerId,

      @Semantics.amount.currencyCode: 'Currency'
      NetAmount,

      NetIndicator,
      Currency,
      SalesOrg,
      Createdby,
      Createdat,
      Lastchangedby,
      Lastchangedat,
      Locallastchangedat,

      /* Associations */
      _BillItem: redirected to composition child zzum_C_bill_itemtp
}
