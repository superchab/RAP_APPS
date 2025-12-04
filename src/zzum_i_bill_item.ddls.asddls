@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Basic view for Bill Doc item'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #BASIC
define view entity zzum_I_bill_item
  as select from zzum_bill_item
{
  key bill_id            as BillId,
  key item_no            as ItemNo,
      material_id        as MaterialId,
      description        as Description,
      @Semantics.quantity.unitOfMeasure: 'Uom'
      quantity           as Quantity,
      @Semantics.amount.currencyCode: 'Currency'
      item_amount        as ItemAmount,
      currency           as Currency,
      uom                as Uom,
      createdby          as Createdby,  
      createdat          as Createdat,   
      lastchangedby      as Lastchangedby,
      lastchangedat      as Lastchangedat,
      locallastchangedat as Locallastchangedat
}
