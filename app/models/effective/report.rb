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
        collection().first; nil
      rescue StandardError => e
        e.message.gsub('<', '').gsub('>', '')
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

    def emailable_report_column
      report_columns.find { |column| column.name == 'user' } ||
      report_columns.find { |column| column.name == 'owner' } ||
      report_columns.find { |column| column.name.include?('user') } || 
      report_columns.find { |column| column.name == 'organization' } ||
      report_columns.find { |column| column.name.include?('organization') }
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

    # Return a string you can copy and paste into a seeds file
    def seeds
      seeds = [
        "report = Effective::Report.where(title: \"#{title}\", reportable_class_name: \"#{reportable_class_name}\").first_or_initialize",
        ("report.assign_attributes(description: \"#{description}\")" if description.present?),
      ].compact

      seeds += report_columns.map do |column|
        attributes = column.dup.attributes.except('name', 'report_id', 'position', 'as').compact
        attributes.delete('filter') unless attributes['filter']

        if attributes.present?
          attributes = attributes.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
          "report.col(:#{column.name}, #{attributes})"
        else
          "report.col(:#{column.name})"
        end
      end

      seeds += report_scopes.map do |scope|
        attributes = scope.dup.attributes.except('name', 'report_id', 'position').compact

        if attributes.present?
          attributes = attributes.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')
          "report.scope(:#{scope.name}, #{attributes})"
        else
          "report.scope(:#{scope.name})"
        end
      end

      seeds += [
        "report.save!"
      ]

      seeds.join("\n")
    end

    def duplicate
      Effective::Report.new(attributes.except('id', 'updated_at', 'created_at')).tap do |report|
        report.title = title + ' (Copy)'

        report_columns.each do |report_column|
          report.report_columns.build(report_column.attributes.except('id', 'updated_at', 'created_at'))
        end

        report_scopes.each do |report_scope|
          report.report_scopes.build(report_scope.attributes.except('id', 'updated_at', 'created_at'))
        end
      end
    end

    def duplicate!
      duplicate.tap { |event| event.save! }
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
