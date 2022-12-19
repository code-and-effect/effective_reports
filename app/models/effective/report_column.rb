module Effective
  class ReportColumn < ActiveRecord::Base
    self.table_name = EffectiveReports.report_columns_table_name.to_s

    belongs_to :report
    belongs_to :value_belongs_to, polymorphic: true, optional: true

    log_changes(to: :report) if respond_to?(:log_changes)

    effective_resource do
      name            :string
      as              :string
      position        :integer

      filter          :boolean
      operation       :string

      value_boolean   :boolean
      value_date      :date
      value_decimal   :decimal
      value_integer   :integer
      value_price     :integer
      value_string    :string

      timestamps
    end

    scope :deep, -> { includes(:report) }
    scope :sorted, -> { order(:position) }

    before_validation(if: -> { report.present? }) do
      self.position ||= (report.report_columns.map(&:position).compact.max || -1) + 1
    end

    before_validation(if: -> { filter? == false }) do
      assign_attributes(operation: nil, value_boolean: nil, value_date: nil, value_decimal: nil, value_integer: nil, value_price: nil, value_string: nil, value_belongs_to: nil)
    end

    validates :name, presence: true
    validates :as, presence: true, inclusion: { in: Report::DATATYPES.map(&:to_s) }
    validates :position, presence: true
    validates :operation, presence: true, if: -> { filter? }

    validate(if: -> { filter? }) do
      if value.blank? && (value != false)
        self.errors.add(:value_date, "can't be blank")
        self.errors.add(:value_decimal, "can't be blank")
        self.errors.add(:value_integer, "can't be blank")
        self.errors.add(:value_price, "can't be blank")
        self.errors.add(:value_string, "can't be blank")
        self.errors.add(:value_belongs_to_id, "can't be blank")
        self.errors.add(:value_boolean, "can't be blank")
      end
    end

    def to_s
      name.presence || 'report column'
    end

    def value
      value_date || value_decimal || value_integer || value_price || value_string.presence || value_belongs_to || value_boolean
    end

  end
end
