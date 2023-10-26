require 'effective_resources'
require 'effective_datatables'
require 'effective_reports/engine'
require 'effective_reports/version'

module EffectiveReports

  def self.config_keys
    [
      # Database Tables
      :reports_table_name, :report_columns_table_name, :report_scopes_table_name,

      :reportable_class_names,

      # Effective Gem
      :layout,
      :mailer, :parent_mailer, :deliver_method, :mailer_layout, :mailer_sender, :mailer_froms, :mailer_admin, :mailer_subject
    ]
  end

  include EffectiveGem

  def self.reportable_classes
    Array(reportable_class_names).map(&:safe_constantize).select { |klass| klass.try(:acts_as_reportable?) }
  end

end
