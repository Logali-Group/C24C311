class lhc_Travel definition inheriting from cl_abap_behavior_handler.
  private section.

    constants:
      begin of travel_status,
        open     type c length 1 value 'O', "Open
        accepted type c length 1 value 'A', "Accepted
        rejected type c length 1 value 'X', "Rejected
      end of travel_status.

    methods get_instance_features for instance features
      importing keys request requested_features for Travel result result.

    methods get_instance_authorizations for instance authorization
      importing keys request requested_authorizations for Travel result result.

    methods get_global_authorizations for global authorization
      importing request requested_authorizations for Travel result result.

    methods acceptTravel for modify
      importing keys for action Travel~acceptTravel result result.

    methods deductDiscount for modify
      importing keys for action Travel~deductDiscount result result.

    methods reCaclTotalPrice for modify
      importing keys for action Travel~reCaclTotalPrice.

    methods rejectTravel for modify
      importing keys for action Travel~rejectTravel result result.

    methods calculateTotalPrice for determine on modify
      importing keys for Travel~calculateTotalPrice.

    methods setStatusToOpen for determine on modify
      importing keys for Travel~setStatusToOpen.

    methods setTravelNumber for determine on save
      importing keys for Travel~setTravelNumber.

    methods validateAgency for validate on save
      importing keys for Travel~validateAgency.

    methods validateCustomer for validate on save
      importing keys for Travel~validateCustomer.

    methods validateDateRange for validate on save
      importing keys for Travel~validateDateRange.

endclass.

class lhc_Travel implementation.

  method get_instance_features.

    read entities of z_r_travel_lgl in local mode
         entity Travel
         fields ( OverallStatus )
         with corresponding #( keys )
         result data(travels)
         failed failed.

    result = value #( for travel in travels (
                             %tky = travel-%tky
                             %field-BookingFee = cond #( when travel-OverallStatus = travel_status-accepted
                                                         then if_abap_behv=>fc-f-read_only
                                                         else if_abap_behv=>fc-f-unrestricted )
                             %action-acceptTravel = cond #( when travel-OverallStatus = travel_status-accepted
                                                            then if_abap_behv=>fc-o-disabled
                                                            else if_abap_behv=>fc-o-enabled )
                             %action-rejectTravel = cond #( when travel-OverallStatus = travel_status-rejected
                                                            then if_abap_behv=>fc-o-disabled
                                                            else if_abap_behv=>fc-o-enabled )
                             %action-deductDiscount = cond #( when travel-OverallStatus = travel_status-accepted
                                                              then if_abap_behv=>fc-o-disabled
                                                              else if_abap_behv=>fc-o-enabled )
    ) ).

  endmethod.

  method get_instance_authorizations.

    data: update_requested type abap_bool,
          update_granted   type abap_bool,
          delete_requested type abap_bool,
          delete_granted   type abap_bool.

    read entities of z_r_travel_lgl in local mode
         entity Travel
         fields ( AgencyID )
         with corresponding #( keys )
         result data(travels)
         failed failed.

    update_requested = cond #( when requested_authorizations-%update = if_abap_behv=>mk-on
                                 or requested_authorizations-%action-Edit = if_abap_behv=>mk-on
                               then abap_true
                               else abap_false ).

    delete_requested = cond #( when requested_authorizations-%delete = if_abap_behv=>mk-on
                               then abap_true
                               else abap_false ).

    data(lv_technical_name) = cl_abap_context_info=>get_user_technical_name(  ).

    loop at travels into data(travel). "70021

      if travel-AgencyID is not initial.

        if update_requested eq abap_true.
          if lv_technical_name eq 'CB9980007575' and travel-AgencyID ne '70021'. "REPLACE WITH BUSINESS LOGIC
            update_granted = abap_true.
          else.

            update_granted = abap_false.

            append value #( %tky = travel-%tky
                            %msg = new /dmo/cm_flight_messages( textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                                agency_id = travel-AgencyID
                                                                severity  = if_abap_behv_message=>severity-error )
                            %element-AgencyID = if_abap_behv=>mk-on ) to reported-travel.
          endif.
        endif.

        if delete_requested eq abap_true.
          if lv_technical_name eq 'CB9980007575' and travel-AgencyID ne '70021'.
            delete_granted = abap_true.
          else.

            delete_granted = abap_false.

            append value #( %tky = travel-%tky
                            %msg = new /dmo/cm_flight_messages( textid    = /dmo/cm_flight_messages=>not_authorized_for_agencyid
                                                                agency_id = travel-AgencyID
                                                                severity  = if_abap_behv_message=>severity-error )
                            %element-AgencyID = if_abap_behv=>mk-on ) to reported-travel.

          endif.
        endif.

      else.

        if lv_technical_name eq 'CB9980007575'.
          update_granted = abap_true.
        endif.

        if update_granted = abap_false.

          append value #( %tky = travel-%tky
                          %msg = new /dmo/cm_flight_messages( textid    = /dmo/cm_flight_messages=>not_authorized
                                                              severity  = if_abap_behv_message=>severity-error )
                          %element-AgencyID = if_abap_behv=>mk-on ) to reported-travel.

        endif.

      endif.

      append value #( let upd_auth = cond #( when update_granted eq abap_true
                                             then if_abap_behv=>auth-allowed
                                             else if_abap_behv=>auth-unauthorized )
                          del_auth = cond #( when delete_granted eq abap_true
                                             then if_abap_behv=>auth-allowed
                                             else if_abap_behv=>auth-unauthorized )
                      in
                      %tky         = travel-%tky
                      %update      = upd_auth
                      %action-Edit = upd_auth
                      %delete      = del_auth ) to result.

    endloop.


  endmethod.

  method get_global_authorizations.

    data(lv_technical_name) = cl_abap_context_info=>get_user_technical_name(  ).

    "lv_technical_name = 'DIFFERENT_USER'.

    if requested_authorizations-%create eq if_abap_behv=>mk-on.

      if lv_technical_name eq 'CB9980007575'.
        result-%create = if_abap_behv=>auth-allowed.
      else.
        result-%create = if_abap_behv=>auth-unauthorized.

        append value #( %msg   = new /dmo/cm_flight_messages( textid = /dmo/cm_flight_messages=>not_authorized
                                                            severity = if_abap_behv_message=>severity-error )
                        %global = if_abap_behv=>mk-on ) to reported-travel.

      endif.

    endif.

    if requested_authorizations-%update      eq if_abap_behv=>mk-on or
       requested_authorizations-%action-Edit eq if_abap_behv=>mk-on.

      if lv_technical_name eq 'CB9980007575'.
        result-%update      = if_abap_behv=>auth-allowed.
        result-%action-Edit = if_abap_behv=>auth-allowed.
      else.
        result-%update      = if_abap_behv=>auth-unauthorized.
        result-%action-Edit = if_abap_behv=>auth-unauthorized.

        append value #( %msg = new /dmo/cm_flight_messages( textid = /dmo/cm_flight_messages=>not_authorized
                                                            severity = if_abap_behv_message=>severity-error )
                                   %global = if_abap_behv=>mk-on ) to reported-travel.

      endif.

    endif.

    if requested_authorizations-%delete eq if_abap_behv=>mk-on.

      if lv_technical_name eq 'CB9980007575'.
        result-%delete = if_abap_behv=>auth-allowed.
      else.
        result-%delete = if_abap_behv=>auth-unauthorized.

        append value #( %msg = new /dmo/cm_flight_messages( textid = /dmo/cm_flight_messages=>not_authorized
                                                            severity = if_abap_behv_message=>severity-error )
                                   %global = if_abap_behv=>mk-on ) to reported-travel.
      endif.

    endif.

  endmethod.

  method deductDiscount.

    data travels_for_update type table for update z_r_travel_lgl.

    data(keys_valid_discount) = keys.

    loop at keys_valid_discount assigning field-symbol(<key_valid_discount>)
         where %param-discount_percent is initial
            or %param-discount_percent > 100
            or %param-discount_percent <= 0.

      append value #( %tky = <key_valid_discount>-%tky ) to failed-travel.

      append value #( %tky = <key_valid_discount>-%tky
                      %msg = new /dmo/cm_flight_messages( textid = /dmo/cm_flight_messages=>discount_invalid
                                                          severity = if_abap_behv_message=>severity-error )
                      %op-%action-deductDiscount = if_abap_behv=>mk-on ) to reported-travel.

      data(lv_error) = abap_true.

    endloop.

    check lv_error ne abap_true.

    read entities of z_r_travel_lgl in local mode
           entity Travel
           fields ( BookingFee )
           with corresponding #( keys )
           result data(travels).

    data percentage type decfloat16.

    loop at travels assigning field-symbol(<travel>).

      data(discount_percentage) = keys[ key id %tky = <travel>-%tky ]-%param-discount_percent.
      percentage = discount_percentage / 100.
      data(reduced_fee) = <travel>-BookingFee * ( 1 - percentage ).

      append value #( %tky       = <travel>-%tky
                      BookingFee = reduced_fee ) to travels_for_update.

    endloop.

    modify entities of z_r_travel_lgl in local mode
           entity Travel
           update
           fields ( BookingFee )
           with travels_for_update.

    read entities of z_r_travel_lgl in local mode
          entity Travel
          all fields
          with corresponding #( keys )
          result data(travels_with_dicount).

    result = value #( for travel in travels_with_dicount ( %tky   = travel-%tky
                                                           %param = travel ) ).


  endmethod.

  method reCaclTotalPrice.

    read entities of z_r_travel_lgl in local mode
         entity Travel
         fields ( BookingFee CurrencyCode )
         with corresponding #( keys )
         result data(travels).

    delete travels where CurrencyCode is initial.

    loop at travels assigning field-symbol(<travel>).

      clear <travel>-TotalPrice.

      select single from /dmo/booking
             fields flight_price
             where currency_code eq @<travel>-CurrencyCode
             into @data(lv_flight_price).

      if sy-subrc eq 0.
        <travel>-TotalPrice += lv_flight_price.
      endif.

      <travel>-TotalPrice += <travel>-BookingFee.

    endloop.

    modify entities of z_r_travel_lgl in local mode
           entity Travel
           update
           fields ( TotalPrice )
           with corresponding #( travels ).

  endmethod.

  method rejectTravel.

    modify entities of z_r_travel_lgl in local mode
         entity Travel
         update
         fields ( OverallStatus )
         with value #( for key in keys ( %tky          = key-%tky
                                         OverallStatus = travel_status-rejected ) ).


    read entities of z_r_travel_lgl in local mode
         entity Travel
         all fields
         with corresponding #( keys )
         result data(travels).

    result = value #( for travel in travels ( %tky   = travel-%tky
                                              %param = travel ) ).

  endmethod.

  method calculateTotalPrice.

    modify entities of z_r_travel_lgl in local mode
           entity Travel
           execute reCaclTotalPrice
           from corresponding #( keys ).

  endmethod.

  method setStatusToOpen.

    read entities of z_r_travel_lgl in local mode
         entity Travel
         fields ( OverallStatus )
         with corresponding #( keys )
         result data(travels).

    delete travels where OverallStatus is not initial.

    check travels is not initial.

    modify entities of z_r_travel_lgl in local mode
           entity Travel
           update fields ( OverallStatus )
           with value #( for travel in travels ( %tky          = travel-%tky
                                                 OverallStatus = travel_status-open ) ).


  endmethod.

  method setTravelNumber.

    read entities of z_r_travel_lgl in local mode
         entity Travel
         fields ( TravelID )
         with corresponding #( keys )
         result data(travels).

    delete travels where TravelID is not initial.

    check travels is not initial.

    select single from ztravel_lgl
           fields max( travel_id )
           into @data(lv_max_travel_id).

    modify entities of z_r_travel_lgl in local mode
           entity Travel
           update fields ( TravelID )
           with value #( for travel in travels index into i
                                ( %tky     = travel-%tky
                                  TravelID = lv_max_travel_id + i ) ).

  endmethod.

  method validateAgency.

    read entities of z_r_travel_lgl in local mode
         entity Travel
         fields ( AgencyID )
         with corresponding #( keys )
         result data(travels).

    data agencies type sorted table of /dmo/agency with unique key client agency_id.

    agencies = corresponding #( travels discarding duplicates mapping agency_id = AgencyID except * ).
    delete agencies where agency_id is initial.

    if agencies is not initial.

      select from /dmo/agency as ddbb
             inner join @agencies as http_req on ddbb~agency_id eq http_req~agency_id
             fields ddbb~agency_id
             into table @data(valid_agencies).

    endif.

    loop at travels into data(travel).

      append value #(  %tky                 = travel-%tky
                       %state_area          = 'VALIDATE_AGENCY'
                     ) to reported-travel.

      if travel-AgencyID is initial.

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky        = travel-%tky
                        %state_area = 'VALIDATE_AGENCY'
                        %msg = new /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_agency_id
                                                            severity = if_abap_behv_message=>severity-error )
                        %element-AgencyID = if_abap_behv=>mk-on
                               ) to reported-travel.

      elseif travel-AgencyID is not initial and not line_exists( valid_agencies[ agency_id = travel-AgencyID ] ).

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky = travel-%tky
                        %state_area = 'VALIDATE_AGENCY'
                        %msg = new /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>agency_unkown
                                                            agency_id = travel-AgencyID
                                                            severity = if_abap_behv_message=>severity-error )
                        %element-AgencyID = if_abap_behv=>mk-on
                                  ) to reported-travel.

      endif.

    endloop.

  endmethod.

  method validateCustomer.

    read entities of z_r_travel_lgl in local mode
           entity Travel
           fields ( CustomerID )
           with corresponding #( keys )
           result data(travels).

    data customers type sorted table of /dmo/customer with unique key client customer_id.

    customers = corresponding #( travels discarding duplicates mapping customer_id = CustomerID except * ).
    delete customers where customer_id is initial.

    if customers is not initial.

      select from /dmo/customer as ddbb
             inner join @customers as http_req on ddbb~customer_id eq http_req~customer_id
             fields ddbb~customer_id
             into table @data(valid_customers).

    endif.

    loop at travels into data(travel).

      append value #(  %tky                 = travel-%tky
                       %state_area          = 'VALIDATE_CUSTOMER'
                     ) to reported-travel.

      if travel-CustomerID is initial.

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky = travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg = new /dmo/cm_flight_messages( textid   = /dmo/cm_flight_messages=>enter_customer_id
                                                            severity = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on
                                  ) to reported-travel.

      elseif travel-CustomerID is not initial and not line_exists( valid_customers[ customer_id = travel-CustomerID ] ).

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky = travel-%tky
                        %state_area = 'VALIDATE_CUSTOMER'
                        %msg = new /dmo/cm_flight_messages( textid      = /dmo/cm_flight_messages=>customer_unkown
                                                            customer_id = travel-CustomerID
                                                            severity    = if_abap_behv_message=>severity-error )
                        %element-CustomerID = if_abap_behv=>mk-on
                                  ) to reported-travel.

      endif.

    endloop.

  endmethod.

  method validateDateRange.

    read entities of z_r_travel_lgl in local mode
         entity Travel
         fields ( BeginDate
                  EndDate )
         with corresponding #( keys )
         result data(travels).

    loop at travels into data(travel).

      if travel-BeginDate is initial.

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky = travel-%tky
                        %state_area = 'VALIDATE_DATES'
                        %msg = new /dmo/cm_flight_messages( textid      = /dmo/cm_flight_messages=>enter_begin_date
                                                            severity    = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on
                          ) to reported-travel.

      endif.

      if travel-EndDate is initial.

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky = travel-%tky
                        %state_area = 'VALIDATE_DATES'
                        %msg = new /dmo/cm_flight_messages( textid      = /dmo/cm_flight_messages=>enter_end_date
                                                            severity    = if_abap_behv_message=>severity-error )
                        %element-EndDate = if_abap_behv=>mk-on
                          ) to reported-travel.

      endif.

      if travel-EndDate < travel-BeginDate and travel-BeginDate is not initial
                                           and travel-EndDate is not initial.

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky = travel-%tky
                        %state_area = 'VALIDATE_DATES'
                        %msg = new /dmo/cm_flight_messages( textid      = /dmo/cm_flight_messages=>begin_date_bef_end_date
                                                            begin_date  = travel-BeginDate
                                                            end_date    = travel-EndDate
                                                            severity    = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate   = if_abap_behv=>mk-on
                          ) to reported-travel.

      endif.

      if travel-BeginDate < cl_abap_context_info=>get_system_date(  ) and travel-BeginDate is not initial.

        append value #( %tky = travel-%tky ) to failed-travel.

        append value #( %tky = travel-%tky
                        %state_area = 'VALIDATE_DATES'
                        %msg = new /dmo/cm_flight_messages( textid      = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                                            begin_date  = travel-BeginDate
                                                            severity    = if_abap_behv_message=>severity-error )
                         %element-BeginDate = if_abap_behv=>mk-on
                          ) to reported-travel.

      endif.

    endloop.


  endmethod.

  method acceptTravel.

* EML - Entity Manipulation Language
    modify entities of z_r_travel_lgl in local mode
           entity Travel
           update
           fields ( OverallStatus )
           with value #( for key in keys ( %tky          = key-%tky
                                           OverallStatus = travel_status-accepted ) ).


    read entities of z_r_travel_lgl in local mode
         entity Travel
         all fields
         with corresponding #( keys )
         result data(travels).

    result = value #( for travel in travels ( %tky   = travel-%tky
                                              %param = travel ) ).

  endmethod.

endclass.
