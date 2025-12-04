@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption view for Bill item'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@VDM.viewType: #CONSUMPTION
define view entity zzum_C_bill_itemtp
   as projection on zzum_R_bill_itemtp
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
    Createdby,
    Createdat,
    Lastchangedby,
    Lastchangedat,
    Locallastchangedat,
    /* Associations */
    _BillHeader: redirected to parent zzum_C_bill_headerTP
}
