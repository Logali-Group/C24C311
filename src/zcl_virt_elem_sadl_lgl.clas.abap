class zcl_virt_elem_sadl_lgl definition
  public
  final
  create public .

  public section.
    interfaces if_sadl_exit_calc_element_read.

  protected section.
  private section.
endclass.


class zcl_virt_elem_sadl_lgl implementation.

  method if_sadl_exit_calc_element_read~get_calculation_info.

    case iv_entity.
      when 'z_c_travel_lgl'.

        loop at it_requested_calc_elements into data(ls_requested_calc_elem).

          if ls_requested_calc_elem eq 'PRICEWITHVAT'.
            insert conv #( 'TOTALPRICE' ) into table et_requested_orig_elements.
          endif.

        endloop.
    endcase.

  endmethod.

  method if_sadl_exit_calc_element_read~calculate.

      data lt_original_data type standard table of z_c_travel_lgl with default key.

      lt_original_data = corresponding #( it_original_data ).

      loop at lt_original_data assigning field-symbol(<fs_original_data>).
         <fs_original_data>-PriceWithVAT = <fs_original_data>-TotalPrice * '1.21'.
      endloop.

      ct_calculated_data = corresponding #( lt_original_data ).

  endmethod.



endclass.
