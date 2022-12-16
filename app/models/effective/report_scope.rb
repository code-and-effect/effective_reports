module Effective
  class ReportScope < ActiveRecord::Base
    self.table_name = EffectiveReports.report_scopes_table_name.to_s

    belongs_to :report

    log_changes(to: :report) if respond_to?(:log_changes)

    VALID_TYPES = [:date, :integer, :price, :string]

    effective_resource do
      name          :string

      value_date     :date
      value_integer  :integer
      value_price    :integer
      value_string   :string

      timestamps
    end

    scope :deep, -> { includes(:report) }
    scope :sorted, -> { order(:name) }

    validates :name, presence: true

    def to_s
      name.presence || 'report scope'
    end

    def value
      value_date || value_integer || value_price || value_string
    end

  end
end
