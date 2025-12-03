@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Consumption view for Bill doc'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
@VDM.viewType: #CONSUMPTION
define root view entity zzum_C_bill_header as select from zzum_R_bill_header
//composition of target_data_source_name as _association_name
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
    Locallastchangedat
//    _association_name // Make association public
}
