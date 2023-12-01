# This renders a datatable based off a report

class EffectiveReportDatatable < Effective::Datatable
  datatable do
    skip_save_state!  # Forgets the previous show/hide columns settings

    order :id, :desc

    col :id, visible: false

    if report.reportable.column_names.include?('token')
      col :token, visible: false
    end

    report.report_columns.each do |column|
      col(column.name, as: column.as.to_sym)
    end

  end

  collection do
    report.collection()
  end

  def report
    Effective::Report.deep.find(attributes[:report_id])
  end

end
