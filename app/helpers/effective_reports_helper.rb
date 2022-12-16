module EffectiveReportsHelper

  def reportable_attributes_collection(attributes)
    attributes.keys.sort
  end

  def reportable_scopes_collection(scopes)
    {
      'Basic' => scopes.select { |_, type| type.blank? }.map { |scope, _| [scope, scope] },
      'Advanced' => scopes.select { |_, type| type.present? }.map { |scope, _| [scope, scope] }
    }
  end

  # [:equals, :includes, :greater_than, :greater_than_or_equal_to, :less_than, :less_than_or_equal_to]
  def reportable_operations_collection()
    [
      ['Equals =', :equals],
      ['Includes *', :includes],
      ['Greater than >', :greater_than],
      ['Greater than or equal to >=', :greater_than_or_equal_to],
      ['Less than <', :less_than],
      ['Less than or equal to <', :less_than_or_equal_to],
    ]
  end

end
