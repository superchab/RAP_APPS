@AccessControl.authorizationCheck: #NOT_REQUIRED

@EndUserText.label: 'Consumption view for Bill item'

@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@VDM.viewType: #TRANSACTIONAL

define view entity zzum_R_bill_itemtp
  as select from zzum_I_bill_item

  association to parent zzum_R_bill_header as _BillHeader on $projection.BillId = _BillHeader.BillId

{
  key BillId,
  key ItemNo,

      MaterialId,
      Description,

      @Semantics.quantity.unitOfMeasure: 'Uom'
      Quantity,

      @Semantics.amount.currencyCode: 'Currency'
      ItemAmount,

      Currency,
      Uom,

      @Semantics.user.createdBy: true
      Createdby,

      @Semantics.systemDateTime.createdAt: true
      Createdat,

      @Semantics.user.lastChangedBy: true
      Lastchangedby,

      @Semantics.systemDateTime.lastChangedAt: true
      Lastchangedat,

      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      Locallastchangedat,

      _BillHeader // Make association public
}
