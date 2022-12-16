module EffectiveReportsHelper

  def reportable_boolean_collection
    [['Yes', true], ['No', false]]
  end

  def reportable_attributes_collection(attributes)
    attributes.keys.sort
  end

  def reportable_scopes_collection(scopes)
    {
      'Basic' => scopes.select { |_, type| type.blank? }.map { |scope, _| [scope, scope] },
      'Advanced' => scopes.select { |_, type| type.present? }.map { |scope, _| [scope, scope] }
    }
  end

  def reportable_operations_collection(type)
    case type
    when :boolean
      [
        ['Equals', :equals]
      ]
    when :string
      [
        ['Equals', :equals],
        ['Includes', :includes],
        ['Starts with', :starts_with],
        ['Ends with', :ends_with]
      ]
    when :integer, :price, :date
      [
        ['Equals =', :equals],
        ['Greater than >', :greater_than],
        ['Greater than or equal to >=', :greater_than_or_equal_to],
        ['Less than <', :less_than],
        ['Less than or equal to <', :less_than_or_equal_to],
      ]
    else
      raise("unexpected type: #{type || 'nil'}")
    end
  end

end
