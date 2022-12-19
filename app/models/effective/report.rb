module Effective
  class Report < ActiveRecord::Base
    self.table_name = EffectiveReports.reports_table_name.to_s

    belongs_to :created_by, polymorphic: true

    has_many :report_columns, -> { ReportColumn.sorted }, inverse_of: :report, dependent: :delete_all
    accepts_nested_attributes_for :report_columns, allow_destroy: true, reject_if: proc { |atts| atts['name'].blank? }

    has_many :report_scopes, -> { ReportScope.sorted }, inverse_of: :report, dependent: :delete_all
    accepts_nested_attributes_for :report_scopes, allow_destroy: true, reject_if: proc { |atts| atts['name'].blank? }

    log_changes if respond_to?(:log_changes)

    DATATYPES = [:boolean, :date, :decimal, :integer, :price, :string, :belongs_to, :has_many, :has_one]

    # Arel::Predications.instance_methods
    OPERATIONS = [
      :eq, :not_eq, :matches, :does_not_match, :starts_with, :ends_with, :gt, :gteq, :lt, :lteq,
      :associated_ids, :associated_matches, :associated_does_not_match, :associated_sql
    ]

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
    # def report_columns_attributes=(atts)
    #   report_columns.clear
    #   super(EffectiveResources.replace_nested_attributes(atts))
    # end

    # def report_scopes_attributes=(atts)
    #   report_scopes.clear
    #   super(EffectiveResources.replace_nested_attributes(atts))
    # end

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

      # Apply Attributes
      report_columns.select(&:filter?).each do |column|
        attribute = collection.arel_table[column.name]

        collection = case column.operation.to_sym
          when :eq then collection.where(attribute.eq(column.value))
          when :not_eq then collection.where(attribute.not_eq(column.value))
          when :matches then collection.where(attribute.matches("%#{column.value}%"))
          when :does_not_match then collection.where(attribute.does_not_match("%#{column.value}%"))
          when :starts_with then collection.where(attribute.matches("#{column.value}%"))
          when :ends_with then collection.where(attribute.matches("%#{column.value}"))
          when :gt then collection.where(attribute.gt(column.value))
          when :gteq then collection.where(attribute.gteq(column.value))
          when :lt then collection.where(attribute.lt(column.value))
          when :lteq then collection.where(attribute.lteq(column.value))
          when :associated_ids then search_associated(collection, column)
          when :associated_sql then search_associated(collection, column)
          when :associated_matches then search_associated(collection, column)
          when :associated_does_not_match then search_associated(collection, column)
          else raise("Unexpected operation: #{operation}")
        end
      end

      collection
    end

    def search_associated(collection, column)
      name = column.name.to_sym
      operation = column.operation.to_sym

      value = column.value.to_s
      value_ids = (value.split(/,|\s|\|/) - [nil, '', ' '])
      value_sql = Arel.sql(value)

      reflection = collection.klass.reflect_on_all_associations.find { |reflection| reflection.name == name }
      raise("expected to find #{collection.klass.name} reflection on #{name}") unless reflection

      foreign_id = reflection.foreign_key
      foreign_type = reflection.foreign_key.to_s.chomp('_id') + '_type'
      foreign_collection = reflection.klass.all
      foreign_collection = reflection.klass.where(foreign_type => collection.klass.name) if reflection.klass.new.respond_to?(foreign_type)

      case reflection
      when ActiveRecord::Reflection::BelongsToReflection
        raise('not yet')
      when ActiveRecord::Reflection::HasManyReflection, ActiveRecord::Reflection::HasOneReflection
        case operation
        when :associated_ids
          associated = foreign_collection.where(id: value_ids)
          collection = collection.where(id: associated.select(foreign_id))
        when :associated_matches
          associated = Resource.new(foreign_collection).search_any(value)
          collection = collection.where(id: associated.select(foreign_id))
        when :associated_does_not_match
          associated = Resource.new(foreign_collection).search_any(value)
          collection = collection.where.not(id: associated.select(foreign_id))
        when :associated_sql
          if (foreign_collection.where(value_sql).present? rescue :invalid) != :invalid
            associated = foreign_collection.where(value_sql)
            collection = collection.where(id: associated.select(foreign_id))
          end
        end
      else
        raise("unsupported reflection: #{reflection}")
      end

      collection
    end

  end
end
