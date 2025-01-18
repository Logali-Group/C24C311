@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Travel - Consumption'
@Metadata.ignorePropagatedAnnotations: true

@Search.searchable: true
@Metadata.allowExtensions: true

define root view entity z_c_travel_lgl
  provider contract transactional_query
  as projection on z_r_travel_lgl
{
  key     TravelUUID,
          TravelID,

          @Search.defaultSearchElement: true
          @Search.fuzzinessThreshold: 0.8
          @Search.ranking: #MEDIUM
          @ObjectModel.text.element: [ 'AgencyName' ]
          AgencyID,
          _Agency.Name              as AgencyName,


          @Search.defaultSearchElement: true
          @Search.fuzzinessThreshold: 0.8
          @Search.ranking: #MEDIUM
          @ObjectModel.text.element: [ 'CustomerName' ]
          CustomerID,
          _Customer.LastName        as CustomerName,

          BeginDate,
          EndDate,
          @Semantics.amount.currencyCode: 'CurrencyCode'
          BookingFee,
          @Semantics.amount.currencyCode: 'CurrencyCode'
          TotalPrice,
          @EndUserText.label: 'VAT Included'
          @Semantics.amount.currencyCode: 'CurrencyCode'
          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_VIRT_ELEM_SADL_LGL'
  virtual PriceWithVAT : /dmo/total_price,
          CurrencyCode,
          Description,

          @ObjectModel.text.element: [ 'OverallStatusText' ]
          OverallStatus,
          _OverallStatus._Text.Text as OverallStatusText : localized,
          //_OverallStatus._Text[1: Language = $session.system_language].Text as OverallStatusText,

          @Semantics.systemDateTime.localInstanceLastChangedAt: true
          LocalLastChangedAt,
          @Semantics.systemDateTime.lastChangedAt: true
          LastChangedAt,
          /* Associations */
          _Agency,
          _Currency,
          _Customer,
          _OverallStatus
}
