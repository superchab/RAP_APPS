@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Transactional view for Bill Header'

@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true

@VDM.viewType: #COMPOSITE

define root view entity zzum_R_bill_header
  as select from zzum_I_bill_header

  composition [0..*] of zzum_R_bill_itemtp as _BillItem

{
  key BillId,

      BillType,
      BillDate,
      CustomerId,

      @Semantics.amount.currencyCode: 'Currency'
      NetAmount,

      case when NetAmount < 0 then 1
      when NetAmount >= 0 and NetAmount < 1000 then 2
      else 3 end          as NetIndicator,

      Currency,
      SalesOrg,

      @Semantics.user.createdBy: true
      Createdby,

      @Semantics.systemDateTime.createdAt: true
      Createdat,

      @Semantics.user.lastChangedBy: true
      Lastchangedby,

      @Semantics.systemDateTime.lastChangedAt: true
      Lastchangedat,

      @Semantics.systemDate.localInstanceLastChangedAt: true
      Locallastchangedat,

      _BillItem // Make association public
}
