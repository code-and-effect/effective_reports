module Effective
  class ReportColumn < ActiveRecord::Base
    self.table_name = EffectiveReports.report_columns_table_name.to_s

    belongs_to :report

    log_changes(to: :report) if respond_to?(:log_changes)

    effective_resource do
      name          :string
      position      :integer

      timestamps
    end

    scope :deep, -> { includes(:report) }
    scope :sorted, -> { order(:position) }

    validates :name, presence: true
    validates :position, presence: true

    before_validation(if: -> { report.present? }) do
      self.position ||= (report.report_columns.map(&:position).compact.max || -1) + 1
    end

    def to_s
      name.presence || 'report column'
    end

  end
end
