CLASS lhc_BillHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR BillHeader RESULT result.
    METHODS change_currency FOR MODIFY
      IMPORTING keys FOR ACTION billheader~change_currency RESULT result.

ENDCLASS.


CLASS lhc_BillHeader IMPLEMENTATION.
  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD Change_Currency.
    READ ENTITIES OF zzum_R_bill_header IN LOCAL MODE
         ENTITY BillHeader
         ALL FIELDS
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_salesorg).

    SELECT SalesOrganization,
           SalesOrganizationCurrency
      FROM C_SalesOrganizationVH
      FOR ALL ENTRIES IN @lt_salesorg
      WHERE SalesOrganization = @lt_salesorg-SalesOrg
      INTO TABLE @DATA(lt_SalOrgCurrency).
    IF lt_salorgcurrency IS NOT INITIAL.

      LOOP AT lt_salesorg ASSIGNING FIELD-SYMBOL(<fs_sales>).

        <fs_sales>-Currency = lt_salorgcurrency[ SalesOrganization = <fs_sales>-SalesOrg ]-SalesOrganizationCurrency.

      ENDLOOP.

    ENDIF.
    MODIFY ENTITIES OF zzum_R_bill_header IN LOCAL MODE
           ENTITY BillHeader
           UPDATE FIELDS ( Currency )
           WITH VALUE #( FOR currency IN lt_salesorg
                         ( %tky     = currency-%tky
                           Currency = currency-Currency ) )
           REPORTED reported
           FAILED failed
           MAPPED mapped.

    result = VALUE #( FOR sales IN lt_salesorg
                      ( %tky = sales-%tky %param = sales ) ).
  ENDMETHOD.
ENDCLASS.
