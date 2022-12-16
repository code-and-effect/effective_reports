# This renders a datatable based off a report

class EffectiveReportDatatable < Effective::Datatable

  datatable do

    report.report_columns.each do |column|
      col(column.name)
    end

  end

  collection do
    report.collection()
  end

  def report
    Effective::Report.find(attributes[:report_id])
  end

end
