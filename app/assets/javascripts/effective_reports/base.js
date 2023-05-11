// Show and hide the filter values when click filter by column
// This additional JS is required because the f.show_if doesn't work quite right
$(document).on('change', "[name^='effective_report[report_columns_attributes]'][name$='[filter]']", function(event) {
  let $filter = $(event.currentTarget);
  let $values = $filter.closest('.row').find('.effective-report-filter');

  let $inputs = $values.find('input,textarea,select,button');

  if($filter.is(':checked')) {
    $values.show();
    $inputs.removeAttr('disabled');
  } else {
    $values.hide();
    $inputs.prop('disabled', true);
  }

  $values.find("[data-effective-reports-date-operation]").trigger('change');
});

// The date operation can be either a date or an integet days field
$(document).on('change', "[data-effective-reports-date-operation]", function(event) {
  let $select = $(event.currentTarget);
  let $dateValues = $select.closest('.row').find('.effective-report-filter');

  let value = $select.val() || ''

  if(value.includes('days')) {
    // Enable days (integer) and disable date
    $dateValues.filter('.effective-report-days-filter').show().find('input').removeAttr('disabled');
    $dateValues.filter('.effective-report-date-filter').hide().find('input').prop('disabled', true);
  } else {
    // Enable date and disable days (integer)
    $dateValues.filter('.effective-report-date-filter').show().find('input').removeAttr('disabled');
    $dateValues.filter('.effective-report-days-filter').hide().find('input').prop('disabled', true);
  }
});
