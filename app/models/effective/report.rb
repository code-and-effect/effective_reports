module Effective
  class Report < ActiveRecord::Base
    self.table_name = EffectiveReports.reports_table_name.to_s

    belongs_to :created_by, polymorphic: true

    has_many :report_columns, -> { ReportColumn.sorted }, inverse_of: :report, dependent: :delete_all
    accepts_nested_attributes_for :report_columns, allow_destroy: true, reject_if: proc { |atts| atts['name'].blank? }

    has_many :report_scopes, -> { ReportScope.sorted }, inverse_of: :report, dependent: :delete_all
    accepts_nested_attributes_for :report_scopes, allow_destroy: true, reject_if: proc { |atts| atts['name'].blank? }

    log_changes if respond_to?(:log_changes)

    DATATYPES = [:boolean, :date, :decimal, :integer, :price, :string, :belongs_to, :belongs_to_polymorphic, :has_many, :has_one]

    # Arel::Predications.instance_methods
    OPERATIONS = [:eq, :not_eq, :matches, :does_not_match, :starts_with, :ends_with, :gt, :gteq, :lt, :lteq, :sql]

    effective_resource do
      title                     :string
      reportable_class_name     :string

      timestamps
    end

    scope :deep, -> { includes(:report_columns, :report_scopes) }
    scope :sorted, -> { order(:title) }

    validates :title, presence: true, uniqueness: true
    validates :reportable_class_name, presence: true

    def to_s
      title.presence || 'report'
    end

    def reportable
      reportable_class_name.constantize if reportable_class_name.present?
    end

    def filtered_report_columns
      report_columns.select(&:filter?)
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
        raise("#{reportable} must respond to reportable scope :#{name}") unless reportable.respond_to?(scope)
      end

      scopes
    end

    # The klass to base the collection from
    def collection
      collection = reportable.all

      # Apply Scopes
      report_scopes.each do |scope|
        collection = (scope.value.nil? ? collection.send(scope.name) : collection.send(scope.name, scope.value))
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
