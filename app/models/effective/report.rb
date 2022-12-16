module Effective
  class Report < ActiveRecord::Base
    self.table_name = EffectiveReports.reports_table_name.to_s

    belongs_to :created_by, polymorphic: true

    has_many :report_columns, -> { ReportColumn.sorted }, inverse_of: :report, dependent: :delete_all
    accepts_nested_attributes_for :report_columns, allow_destroy: true

    has_many :report_scopes, -> { ReportScope.sorted }, inverse_of: :report, dependent: :delete_all
    accepts_nested_attributes_for :report_scopes, allow_destroy: true

    log_changes if respond_to?(:log_changes)

    DATATYPES = [:boolean, :date, :integer, :price, :string, :belongs_to]
    OPERATIONS = [:equals, :includes, :starts_with, :ends_with, :greater_than, :greater_than_or_equal_to, :less_than, :less_than_or_equal_to]

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
