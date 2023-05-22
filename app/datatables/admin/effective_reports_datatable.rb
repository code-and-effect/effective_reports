module Admin
  class EffectiveReportsDatatable < Effective::Datatable

    datatable do
      order :id
      col :id, visible: false

      col :created_at, visible: false
      col :created_by, visible: false

      col :title
      col :description

      col :reportable_class_name, label: 'Resource', search: EffectiveReports.reportable_classes.map(&:to_s), visible: false

      col :report_columns, label: 'Columns', visible: false
      col :report_scopes, label: 'Scopes', visible: false

      if defined?(EffectiveMessaging)
        col :notifications, label: 'Notifications'
      end

      col(:current_rows_count) do |report|
        report.collection().count
      end

      actions_col
    end

    collection do
      Effective::Report.deep.all
    end

  end
end
