# This renders a datatable based off a report

class EffectiveReportDatatable < Effective::Datatable
  datatable do
    skip_save_state!  # Forgets the previous show/hide columns settings

    report.report_columns.each do |column|
      col(column.name, as: column.as.to_sym)
    end

  end

  collection do
    report.collection()
  end

  def report
    Effective::Report.find(attributes[:report_id])
  end

end
