module Effective
  class ReportColumn < ActiveRecord::Base
    self.table_name = EffectiveReports.report_columns_table_name.to_s

    belongs_to :report
    belongs_to :value_belongs_to, polymorphic: true, optional: true

    log_changes(to: :report) if respond_to?(:log_changes)

    effective_resource do
      name          :string
      position      :integer

      filter         :boolean
      operation      :string

      value_boolean  :boolean
      value_date     :date
      value_integer  :integer
      value_price    :integer
      value_string   :string

      timestamps
    end

    scope :deep, -> { includes(:report) }
    scope :sorted, -> { order(:position) }

    before_validation(if: -> { report.present? }) do
      self.position ||= (report.report_columns.map(&:position).compact.max || -1) + 1
    end

    validates :name, presence: true
    validates :position, presence: true

    validate(if: -> { filter? }) do
      self.errors.add(:name, 'filtered columns must include a value') unless value.present? || (value == false)
      self.errors.add(:operation, "can't be blank") unless operation.present?
    end

    def to_s
      name.presence || 'report column'
    end

    def value
      value_date || value_integer || value_price || value_string.presence || value_belongs_to || value_boolean
    end

  end
end
