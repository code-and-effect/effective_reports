module Effective
  class Report < ActiveRecord::Base
    self.table_name = (EffectiveReports.reports_table_name || :reports).to_s

    belongs_to :created_by, polymorphic: true, optional: true

    has_many :report_columns, -> { ReportColumn.sorted }, inverse_of: :report, dependent: :delete_all
    accepts_nested_attributes_for :report_columns, allow_destroy: true, reject_if: proc { |atts| atts['name'].blank? }

    has_many :report_scopes, -> { ReportScope.sorted }, inverse_of: :report, dependent: :delete_all
    accepts_nested_attributes_for :report_scopes, allow_destroy: true, reject_if: proc { |atts| atts['name'].blank? }

    if defined?(EffectiveMessaging)
      has_many :notifications, inverse_of: :report, dependent: :delete_all
      accepts_nested_attributes_for :notifications, allow_destroy: true
    end

    log_changes if respond_to?(:log_changes)

    DATATYPES = [:boolean, :date, :decimal, :integer, :price, :string, :belongs_to, :belongs_to_polymorphic, :has_many, :has_one]

    # Arel::Predications.instance_methods
    OPERATIONS = [:eq, :not_eq, :matches, :does_not_match, :starts_with, :ends_with, :gt, :gteq, :lt, :lteq, :sql]

    effective_resource do
      title                     :string
      reportable_class_name     :string

      timestamps
    end

    scope :deep, -> { 
      base = includes(:report_columns, :report_scopes) 
      base = base.includes(:notifications) if defined?(EffectiveMessaging)
      base
    }

    scope :sorted, -> { order(:title) }
    scope :notifiable, -> { where(id: ReportColumn.notifiable.select(:report_id)) }

    validates :title, presence: true, uniqueness: true
    validates :reportable_class_name, presence: true

    validate do
      error = begin
        collection().to_sql; nil
      rescue StandardError => e
        e.message
      end

      errors.add(:base, "Invalid Report: #{error}") if error.present?
    end

    def to_s
      title.presence || 'report'
    end

    def reportable
      reportable_class_name.constantize if reportable_class_name.present?
    end

    # Find or build
    def col(name, atts = {})
      atts[:name] ||= name.to_sym
      atts[:as] ||= reportable_attributes[name]

      report_columns.find { |col| atts.all? { |k, v| col.send(k).to_s == v.to_s } } || report_columns.build(atts)
    end

    def scope(name, atts = {})
      atts[:name] ||= name.to_sym
      report_scopes.find { |scope| scope.name == name.to_s } || report_scopes.build(atts)
    end

    def notification(atts = {})
      notifications.find { |col| atts.all? { |k, v| col.send(k).to_s == v.to_s } } || notifications.build(atts)
    end

    def filtered_report_columns
      report_columns.select(&:filter?)
    end

    def email_report_column
      report_columns.find { |column| column.name == 'email' } || report_columns.find { |column| column.name.include?('email') }
    end

    def user_report_column
      report_columns.find { |column| column.name == 'user' } ||
      report_columns.find { |column| column.name == 'owner' } ||
      report_columns.find { |column| column.name.include?('user') }
    end

    # Used to build the Reports form
    # { id: :integer, archived: :boolean }
    def reportable_attributes
      attributes = Hash((reportable.new.reportable_attributes if reportable))

      attributes.each do |attribute, type|
        raise("#{reportable}.reportable_attributes #{attribute} => #{type || 'nil'} is invalid. Key must be a symbol") unless attribute.kind_of?(Symbol)
        raise("#{reportable}.reportable_attributes :#{attribute} => #{type || 'nil'} is invalid. Value must be one of #{DATATYPES.map { |s| ":#{s}"}.join(', ')}") unless DATATYPES.include?(type)
      end

      attributes
    end

    # { active: nil, inactive: nil, with_first_name: :string, not_in_good_standing: :boolean }
    def reportable_scopes
      scopes = Hash((reportable.new.reportable_scopes if reportable))

      scopes.each do |scope, type|
        raise("#{reportable}.reportable_scopes #{scope} => #{type || 'nil'} is invalid. Key must be a symbol") unless scope.kind_of?(Symbol)
        raise("#{reportable}.reportable_scopes :#{scope} => #{type || 'nil'} is invalid. Value must be one of #{DATATYPES.map { |s| ":#{s}"}.join(', ')}") if type.present? && !DATATYPES.include?(type)
        raise("#{reportable} must respond to reportable scope :#{scope}") unless reportable.respond_to?(scope)
      end

      scopes
    end

    # The klass to base the collection from
    def collection
      collection = reportable.all

      # Apply Scopes
      report_scopes.each do |scope|
        collection = scope.apply_scope(collection)
      end

      # Apply Includes
      report_columns.select(&:as_associated?).each do |column|
        collection = collection.includes(column.name)
      end

      # Apply Filters
      report_columns.select(&:filter?).each do |column|
        collection = Resource.new(collection).search(column.name, column.value, operation: column.operation)
      end

      collection
    end

  end
end
