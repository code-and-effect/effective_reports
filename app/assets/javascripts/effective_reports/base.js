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
});
