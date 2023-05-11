module EffectiveReportsHelper

  def reportable_boolean_collection
    [['Yes', true], ['No', false]]
  end

  def reportable_attributes_collection(attributes)
    macros = [:belongs_to, :belongs_to_polymorphic, :has_many, :has_one]

    {
      'Attributes' => attributes.select { |_, type| macros.exclude?(type) }.map { |att, _| [att, att] }.sort,
      'Associations' => attributes.select { |_, type| macros.include?(type) }.map { |att, _| [att, att] }.sort,
    }
  end

  def reportable_scopes_collection(scopes)
    {
      'Basic' => scopes.select { |_, type| type.blank? }.map { |scope, _| [scope, scope] }.sort,
      'Advanced' => scopes.select { |_, type| type.present? }.map { |scope, _| [scope, scope] }.sort
    }
  end

  def reportable_operations_collection(type)
    case type
    when :boolean
      [
        ['Equals', :eq],
        ['Does Not Equal', :not_eq]
      ]
    when :string
      [
        ['Equals =', :eq],
        ['Does Not Equal !=', :not_eq],
        ['Includes', :matches],
        ['Does Not Include', :does_not_match],
        ['Starts with', :starts_with],
        ['Ends with', :ends_with]
      ]
    when :date
      [
        ['Days ago Equals =', :days_ago_eq],
        ['Days ago Greater than or equal to >=', :days_ago_gteq],
        ['Days ago Less than or equal to <=', :days_ago_lteq],
        ['Date Equals =', :eq],
        ['Date Does Not Equal !=', :not_eq],
        ['Date Greater than >', :gt],
        ['Date Greater than or equal to >=', :gteq],
        ['Date Less than <', :lt],
        ['Date Less than or equal to <=', :lteq],
      ]
    when :integer, :price, :decimal
      [
        ['Equals =', :eq],
        ['Does Not Equal !=', :not_eq],
        ['Greater than >', :gt],
        ['Greater than or equal to >=', :gteq],
        ['Less than <', :lt],
        ['Less than or equal to <=', :lteq],
      ]
    when :belongs_to, :belongs_to_polymorphic, :has_many, :has_one
      [
        ['ID(s) Equals =', :eq],
        ['Matches', :matches],
        ['Does Not Match', :does_not_match],
        ['SQL', :sql],
      ]
    else
      raise("unexpected reportable operations collection type: #{type || 'nil'}")
    end
  end

end
