@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Value Help for Bill Type'
@Metadata.ignorePropagatedAnnotations: true
@Search.searchable: true
define view entity zzum_billtype_VH
  as select from I_BillingDocumentTypeText
{
      @Search.defaultSearchElement: true
  key BillingDocumentType     as BillType,
      @UI.hidden: true
  key Language,
      BillingDocumentTypeName as BillTypeName,
      /* Associations */
      _BillingDocumentType,
      _Language
}
where
  Language = $session.system_language
