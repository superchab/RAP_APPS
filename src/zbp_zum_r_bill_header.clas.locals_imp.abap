CLASS lhc_BillHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR BillHeader RESULT result.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR BillHeader RESULT result.

    METHODS ChangeCurrency FOR MODIFY
      IMPORTING keys FOR ACTION billheader~ChangeCurrency RESULT result.
    METHODS CreateBillDocHeader FOR MODIFY
      IMPORTING keys FOR ACTION BillHeader~CreateBillDocHeader.
    METHODS ValidateAmount FOR VALIDATE ON SAVE
      IMPORTING keys FOR BillHeader~ValidateAmount.
    METHODS CalculateTotalAmount FOR DETERMINE ON MODIFY
      IMPORTING keys FOR BillItem~CalculateTotalAmount.
    METHODS FillItemDetails FOR DETERMINE ON MODIFY
      IMPORTING keys FOR BillItem~FillItemDetails.

ENDCLASS.


CLASS lhc_BillHeader IMPLEMENTATION.
  METHOD get_instance_authorizations.

    " 1. Read the Bill Date
    READ ENTITIES OF zzum_R_bill_header IN LOCAL MODE
         ENTITY BillHeader
         FIELDS ( BillDate )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_headers).

    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).

    " 2. Loop through records to set authorization status
    LOOP AT lt_headers INTO DATA(ls_header).

      " Determine Status: Unauthorized if Past Dated
      DATA(lv_auth_status) = COND #( WHEN ls_header-BillDate < lv_today
                                     THEN if_abap_behv=>auth-unauthorized
                                     ELSE if_abap_behv=>auth-allowed ).

      " 3. Fill the Result Structure
      " We explicitly check if 'Update' was requested by the framework
      APPEND VALUE #(
          %tky    = ls_header-%tky
          %action-edit = COND #( WHEN requested_authorizations-%action-Edit = if_abap_behv=>mk-on
                                 THEN lv_auth_status
          )
*          " If Update is unauthorized, the EDIT button disappears
*          %update = COND #( WHEN requested_authorizations-%update = if_abap_behv=>mk-on
*                            THEN lv_auth_status )
*
*          " Optional: Also disable Delete for past records
*          %delete = COND #( WHEN requested_authorizations-%delete = if_abap_behv=>mk-on
*                            THEN lv_auth_status )


       ) TO result.


    ENDLOOP.

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

    lt_r_bill_header = VALUE #( BASE lt_r_bill_header
                                ( %cid       = keys[ 1 ]-%cid
                                  %is_draft  = keys[ 1 ]-%param-%is_draft

                                  billid     = keys[ 1 ]-%param-BillId
                                  customerID = CONV #( keys[ 1 ]-%param-customerid )
                                  billtype   = keys[ 1 ]-%param-Bill_Type
                                  SalesOrg   = keys[ 1 ]-%param-Sales_Org
                                  billdate   = CONV #( cl_abap_context_info=>get_system_date( ) )
                                  %control   = VALUE #( Billid     = if_abap_behv=>mk-on
                                                        CustomerId = if_abap_behv=>mk-on
                                                        BillType   = if_abap_behv=>mk-on
                                                        SalesOrg   = if_abap_behv=>mk-on
                                                        BillDate   = if_abap_behv=>mk-on ) ) ).
*    APPEND VALUE #( %cid      = keys[ 1 ]-%cid
*                    %is_draft = keys[ 1 ]-%param-%is_draft
*
*                    billid    = keys[ 1 ]-%param-BillId
*                    customerID = keys[ 1 ]-%param-customerid
*                    billtype  = keys[ 1 ]-%param-Bill_Type
*                    SalesOrg  = keys[ 1 ]-%param-Sales_Org
*                    billdate  = CONV #( cl_abap_context_info=>get_system_date( ) )
*                    %control  = VALUE #( Billid   = if_abap_behv=>mk-on
*                                         customerID = if_abap_behv=>mk-on
*                                         BillType = if_abap_behv=>mk-on
*                                         SalesOrg = if_abap_behv=>mk-on
*                                         BillDate = if_abap_behv=>mk-on ) )
*           TO lt_r_bill_header.

    MODIFY ENTITIES OF zzum_R_bill_header IN LOCAL MODE
           ENTITY BillHeader
           CREATE FROM lt_r_bill_header
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
      DATA(lv_total) = REDUCE wrbtr( INIT lv_summ = 0
        FOR wa IN lt_all_items NEXT lv_summ = lv_summ + wa-ItemAmount
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


  METHOD get_instance_features.
*    READ ENTITIES OF zzum_R_bill_header IN LOCAL MODE
*         ENTITY BillHeader
*         FIELDS ( BillDate )
*         WITH CORRESPONDING #( keys )
*         RESULT DATA(lt_result).
*
*    DATA(lv_today) = cl_abap_context_info=>get_system_date( ).
*
*    LOOP AT lt_result ASSIGNING FIELD-SYMBOL(<FS_result>).
*
*      result = VALUE #(
*          BASE result
*          ( %tky              = <fs_result>-%tky
*            %features-%update = COND #( WHEN <fs_result>-BillDate < lv_today
*                                        THEN if_abap_behv=>fc-o-disabled
*                                        ELSE if_abap_behv=>fc-o-enabled ) ) ).
*
*    ENDLOOP.

    result = VALUE #( FOR ls IN keys (
            %tky = ls-%tky
            %features-%update = if_abap_behv=>fc-o-disabled
            %update = if_abap_behv=>fc-o-disabled

    ) ).

  ENDMETHOD.

  METHOD FillItemDetails.

    " 1. Read the Item to get the entered Material ID
    READ ENTITIES OF zzum_R_bill_header IN LOCAL MODE
         ENTITY BillItem
         FIELDS ( ItemNo )
         WITH CORRESPONDING #( keys )
         RESULT DATA(lt_items).

    SELECT description AS Description,
           quantity    AS Quantity,
           ItemAmount  AS ItemAmount,
           currency    AS Currency,
           uom         AS Uom
      FROM zzum_I_bill_item
      FOR ALL ENTRIES IN @lt_items
      WHERE ItemNo = @lt_items-ItemNo
      INTO TABLE @DATA(lt_db_items).

    IF lt_db_items IS NOT INITIAL.
      LOOP AT lt_items ASSIGNING FIELD-SYMBOL(<item>).

        IF sy-subrc <> 0.
          CONTINUE.
        ENDIF.

        MODIFY ENTITIES OF zzum_R_bill_header IN LOCAL MODE
               ENTITY BillItem
               UPDATE
               FIELDS ( Description Quantity ItemAmount Currency Uom )
               WITH VALUE #( ( %tky        = <item>-%tky
                               Description = lt_db_items[ 1 ]-description
                               Quantity    = lt_db_items[ 1 ]-quantity
                               ItemAmount  = lt_db_items[ 1 ]-itemamount
                               Currency    = lt_db_items[ 1 ]-currency
                               Uom         = lt_db_items[ 1 ]-uom

                               " Tell RAP to overwrite these fields
                               %control    = VALUE #( Description = if_abap_behv=>mk-on
                                                      Quantity    = if_abap_behv=>mk-on
                                                      ItemAmount  = if_abap_behv=>mk-on
                                                      Currency    = if_abap_behv=>mk-on
                                                      Uom         = if_abap_behv=>mk-on ) ) ).
        " 4. If NOT found (sy-subrc <> 0), we do nothing.
        " The fields remain empty, and the user can type them manually.

      ENDLOOP.
    ELSE.
      RETURN.
    ENDIF.

  ENDMETHOD.

ENDCLASS.
