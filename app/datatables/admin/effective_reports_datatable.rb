module Admin
  class EffectiveReportsDatatable < Effective::Datatable

    datatable do
      order :id
      col :id, visible: false

      col :created_at
      col :created_by

      col :title
      col :description

      col :reportable_class_name, label: 'Resource', search: EffectiveReports.reportable_classes.map(&:to_s)

      col :report_columns, label: 'Columns'
      col :report_scopes, label: 'Scopes'

      col(:rows_count, visible: false) do |report|
        report.collection().count
      end

      actions_col
    end

    collection do
      Effective::Report.deep.all
    end

  end
end
