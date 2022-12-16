module EffectiveReportsHelper

  def reportable_scopes_collection(scopes)
    {
      'Basic' => scopes.select { |scope| scope.kind_of?(Symbol) }.map { |scope| [scope, scope] },
      'Advanced' => scopes.select { |scope| scope.kind_of?(Hash) }.map { |scope| [scope.keys.first, scope.keys.first] }
    }
  end

end
