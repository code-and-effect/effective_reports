module Effective
  class ReportScope < ActiveRecord::Base
    self.table_name = EffectiveReports.report_scopes_table_name.to_s

    belongs_to :report

    log_changes(to: :report) if respond_to?(:log_changes)

    effective_resource do
      name          :string
      advanced      :boolean      # The scope is a 0 arity symbol when false, or a 1 arity hash when true

      value_boolean  :boolean
      value_date     :date
      value_decimal  :decimal
      value_integer  :integer
      value_price    :integer
      value_string   :string

      timestamps
    end

    scope :deep, -> { includes(:report) }
    scope :sorted, -> { order(:name) }

    validates :name, presence: true

    validate(if: -> { advanced? }) do
      if value.blank? && (value != false)
        self.errors.add(:value_date, "can't be blank")
        self.errors.add(:value_decimal, "can't be blank")
        self.errors.add(:value_integer, "can't be blank")
        self.errors.add(:value_price, "can't be blank")
        self.errors.add(:value_string, "can't be blank")
        self.errors.add(:value_boolean, "can't be blank")
      end
    end

    def to_s
      [name, operation_label, value].compact.join(' ').presence || 'report scope'
    end

    def value
      value_date || value_decimal || value_integer || value_price || value_string.presence || value_boolean
    end

    def operation_label
      return '=' if advanced?
    end

  end
end
