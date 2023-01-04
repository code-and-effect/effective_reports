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
    when :integer, :price, :date, :decimal
      [
        ['Equals =', :eq],
        ['Does Not Equal !=', :not_eq],
        ['Greater than >', :gt],
        ['Greater than or equal to >=', :gteq],
        ['Less than <', :lt],
        ['Less than or equal to <', :lteq],
      ]
    when :belongs_to_polymorphic
      [
        ['Matches', :associated_matches],
      ]
    when :belongs_to, :has_many, :has_one
      [
        ['ID(s) Equals =', :associated_ids],
        ['Matches', :associated_matches],
        ['Does Not Match', :associated_does_not_match],
        ['SQL', :associated_sql],
      ]
    else
      raise("unexpected reportable operations collection type: #{type || 'nil'}")
    end
  end

end
