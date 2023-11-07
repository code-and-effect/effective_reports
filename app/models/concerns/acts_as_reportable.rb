# ActsAsReportable
#
# Mark your model with 'acts_as_reportable' to be included in the reports

module ActsAsReportable
  extend ActiveSupport::Concern

  PRICE_NAME_ATTRIBUTES = ['price', 'subtotal', 'tax', 'total', 'current_revenue', 'current_revenue_subtotal', 'current_revenue_tax', 'deferred_revenue', 'deferred_revenue_subtotal', 'deferred_revenue_tax', 'amount_owing', 'surcharge']
  DENY_LIST = [:logged_changes, :password, :encrypted_password]

  module Base
    def acts_as_reportable(options = nil)
      include ::ActsAsReportable
    end
  end

  module ClassMethods
    def acts_as_reportable?; true; end
  end

  # Instance Methods

  # { id: :integer, price: :price, created_at: :date }
  def reportable_attributes
    all_reportable_attributes || {}
  end

  # { active: nil, inactive: nil, with_first_name: :string, not_in_good_standing: :boolean }
  def reportable_scopes
    {}
  end

  # Something that returns an email
  def reportable_email
    try(:email) || try(:user).try(:email) || try(:owner).try(:email) || raise("No reportable_email found")
  end

  # Used for the notifications mailer
  # This should be a view_context that you can call urls on
  # But it's a bit weird and sometimes it's just nil (like on an update action in the validation)
  # Be careful when you code stuff for it
  # Always return all the keys, and leave the value blank if view is blank
  def reportable_view_assigns(view = nil)
    {}
  end

  private

  def all_reportable_attributes
    columns = (self.class.columns_hash rescue {})
    names = (self.attributes rescue {})
    reflections = (self.class.reflect_on_all_associations rescue [])

    atts = names.inject({}) do |h, (name, _)|
      type = columns[name].type

      type = case type
        when :datetime then :date
        when :integer then ((PRICE_NAME_ATTRIBUTES.include?(name) || name.include?('price')) ? :price : :integer)
        when :text then :string
        else type
      end

      h[name.to_sym] = type; h
    end

    associated = reflections.inject({}) do |h, reflection|
      case reflection
      when ActiveRecord::Reflection::BelongsToReflection
        if reflection.options[:polymorphic]
          h[reflection.name.to_sym] = :belongs_to_polymorphic
        else
          h[reflection.name.to_sym] = :belongs_to
        end
      when ActiveRecord::Reflection::HasManyReflection
        h[reflection.name.to_sym] = :has_many
      when ActiveRecord::Reflection::HasOneReflection
        h[reflection.name.to_sym] = :has_one
      when ActiveRecord::Reflection::ThroughReflection
        h[reflection.name.to_sym] = :has_many
      end; h
    end

    atts.merge(associated).except(*DENY_LIST)
  end

end
