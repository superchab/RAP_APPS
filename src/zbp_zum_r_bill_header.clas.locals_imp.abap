CLASS lhc_BillHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR BillHeader RESULT result.

ENDCLASS.

CLASS lhc_BillHeader IMPLEMENTATION.

  METHOD get_instance_authorizations.


  ENDMETHOD.

ENDCLASS.
