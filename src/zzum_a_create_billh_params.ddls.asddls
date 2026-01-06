@EndUserText.label: 'Bill Header Creation Parameters'
define abstract entity zzum_a_create_billH_params

{
  @EndUserText.label: 'Bill ID'
  BillId: abap.numc(10);
  
  
  @Consumption.valueHelpDefinition: [{ entity: { name: 'zzum_billtype_VH', element: 'BillType'} }]
  @EndUserText.label: 'Bill type'
  Bill_Type : abap.char(4);

  @Consumption.valueHelpDefinition: [ { entity: { name: 'C_SalesOrganizationVH', element: 'CompanyCode' } } ]
  @EndUserText.label: 'Sales organization'
  Sales_Org : abap.char(4);
}
