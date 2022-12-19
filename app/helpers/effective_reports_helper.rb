module EffectiveReportsHelper

  def reportable_boolean_collection
    [['Yes', true], ['No', false]]
  end

  def reportable_attributes_collection(attributes)
    attributes.keys.sort
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
    else
      raise("unexpected type: #{type || 'nil'}")
    end
  end

end
