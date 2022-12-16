module Effective
  class Report < ActiveRecord::Base
    self.table_name = EffectiveReports.reports_table_name.to_s

    belongs_to :created_by, polymorphic: true

    has_many :report_columns, -> { ReportColumn.sorted }, inverse_of: :report, dependent: :delete_all
    accepts_nested_attributes_for :report_columns, allow_destroy: true

    has_many :report_scopes, -> { ReportScope.sorted }, inverse_of: :report, dependent: :delete_all
    accepts_nested_attributes_for :report_scopes, allow_destroy: true

    log_changes if respond_to?(:log_changes)

    effective_resource do
      title                     :string
      reportable_class_name     :string

      timestamps
    end

    scope :deep, -> { includes(:report_columns) }
    scope :sorted, -> { order(:title) }

    validates :title, presence: true, uniqueness: true
    validates :reportable_class_name, presence: true

    def to_s
      title.presence || 'report'
    end

    def reportable
      reportable_class_name.constantize if reportable_class_name.present?
    end

    # Used to build the Reports form
    def reportable_attributes
      attributes = Array((reportable.new.reportable_attributes if reportable))

      attributes.each do |attribute|
        raise("#{reportable}.reportable_attribute #{attribute} is invalid. Must be a Symbol") unless attribute.kind_of?(Symbol)
      end

      attributes
    end

    # [:all, :active, :inactive, with_first_name: :string]
    def reportable_scopes
      scopes = Array((reportable.new.reportable_scopes if reportable))

      scopes.each do |scope|
        unless scope.kind_of?(Symbol) || (scope.kind_of?(Hash) && scope.length == 1 && ReportScope::VALID_TYPES.include?(scope.values.first))
          raise("#{reportable}.reportable_scopes #{scope} is invalid. Must be a Symbol or Hash with value #{ReportScope::VALID_TYPES.map { |s| ":#{s}"}.join(', ')}")
        end

        if scope.kind_of?(Symbol) && !reportable.respond_to?(scope)
          raise("#{reportable} must respond to reportable scope :#{scope}")
        elsif scope.kind_of?(Hash) && !reportable.respond_to?(scope.keys.first)
          raise("#{reportable} must respond to reportable scope :#{scope.keys.first}")
        end
      end

      scopes
    end

    # Replace the report_columns entirely
    def report_columns_attributes=(atts)
      report_columns.clear
      super(EffectiveResources.replace_nested_attributes(atts))
    end

    def report_scopes_attributes=(atts)
      report_scopes.clear
      super(EffectiveResources.replace_nested_attributes(atts))
    end

    # The klass to base the collection from
    def collection
      collection = reportable.all

      # Apply Scopes
      report_scopes.each do |scope|
        collection = if scope.value.present?
          collection.send(scope.name, scope.value)
        else
          collection.send(scope.name)
        end
      end

      collection
    end

  end
end
