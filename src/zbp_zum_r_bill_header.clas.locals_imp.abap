CLASS lhc_BillHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR BillHeader RESULT result.
    METHODS ChangeCurrency FOR MODIFY
      IMPORTING keys FOR ACTION billheader~ChangeCurrency RESULT result.
    METHODS CreateBillDocHeader FOR MODIFY
      IMPORTING keys FOR ACTION BillHeader~CreateBillDocHeader.
    METHODS ValidateAmount FOR VALIDATE ON SAVE
      IMPORTING keys FOR BillHeader~ValidateAmount.
    METHODS CalculateTotalAmount FOR DETERMINE ON MODIFY
      IMPORTING keys FOR BillItem~CalculateTotalAmount.

ENDCLASS.


CLASS lhc_BillHeader IMPLEMENTATION.
  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD ChangeCurrency.
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

  METHOD CreateBillDocHeader.
    DATA lt_r_bill_header TYPE TABLE FOR CREATE zzum_R_bill_header.

    APPEND VALUE #( %cid      = keys[ 1 ]-%cid
                    %is_draft = keys[ 1 ]-%param-%is_draft
                    billid    = keys[ 1 ]-%param-BillId
                    billtype  = keys[ 1 ]-%param-Bill_Type
                    SalesOrg  = keys[ 1 ]-%param-Sales_Org
                    billdate  = CONV #( cl_abap_context_info=>get_system_date( ) )
                    %control  = VALUE #( Billid   = if_abap_behv=>mk-on
                                         BillType = if_abap_behv=>mk-on
                                         SalesOrg = if_abap_behv=>mk-on
                                         BillDate = if_abap_behv=>mk-on ) )
           TO lt_r_bill_header.

    MODIFY ENTITIES OF zzum_R_bill_header IN LOCAL MODE
           ENTITY BillHeader
           CREATE FROM lt_r_bill_header
           " TODO: variable is assigned but never used (ABAP cleaner)
           MAPPED DATA(mapped_create)
           " TODO: variable is assigned but never used (ABAP cleaner)
           FAILED DATA(failed_create)
           " TODO: variable is assigned but never used (ABAP cleaner)
           REPORTED DATA(reported_create).

    mapped-billheader = CORRESPONDING #( mapped_create-billheader ).
  ENDMETHOD.

  METHOD ValidateAmount.
    " 1. Read the relevant data from the buffer
    " We only need the ID and the Amount field to check
    READ ENTITIES OF zzum_R_bill_header IN LOCAL MODE
         ENTITY BillHeader
         FIELDS ( NetAmount )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_headers).

    IF lt_headers IS NOT INITIAL.
      " 2. Loop through the records
      LOOP AT lt_headers ASSIGNING FIELD-SYMBOL(<header>) WHERE NetAmount < 1000.

        " 4. Add to FAILED (Prevents the save)
        APPEND VALUE #( %tky = <header>-%tky ) TO failed-billheader.

        " 5. Add to REPORTED (Displays the error message to the user)
        APPEND VALUE #( %tky = <header>-%tky
                        %msg = new_message_with_text( severity = if_abap_behv_message=>severity-error
                                                      text     = 'Billing amount must be at least 1000.' ) )
               TO reported-billheader.

      ENDLOOP.
    ENDIF.

  ENDMETHOD.
  METHOD CalculateTotalAmount.
    " 1. Get all distinct Header IDs from the modified items
    READ ENTITIES OF zzum_R_bill_header IN LOCAL MODE
         ENTITY BillItem
         FIELDS ( BillId )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_items).

    SORT lt_items BY BillId.
    DELETE ADJACENT DUPLICATES FROM lt_items COMPARING BillId.

    LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<item_key>).

      " 2. Read ALL items for this header (from draft buffer)
      READ ENTITIES OF zzum_R_bill_header IN LOCAL MODE
           ENTITY BillHeader BY \_BillItem
           FIELDS ( ItemAmount Currency )
           WITH VALUE #( ( %tky = <item_key>-%tky ) )
           RESULT DATA(lt_all_items).

      " 3. Calculate Sum
      DATA(lv_total) = reduce wrbtr( INIT lv_summ = 0
        for wa in lt_all_items nEXT lv_summ = lv_summ + wa-ItemAmount
      ).

      " 4. Update the Header Draft
      MODIFY ENTITIES OF zzum_R_bill_header IN LOCAL MODE
             ENTITY BillHeader
             UPDATE
             FIELDS ( NetAmount )
             WITH VALUE #( ( %tky               = <item_key>-%tky
                             NetAmount          = lv_total
                             %control-NetAmount = if_abap_behv=>mk-on ) ).

    ENDLOOP.


  ENDMETHOD.

ENDCLASS.
