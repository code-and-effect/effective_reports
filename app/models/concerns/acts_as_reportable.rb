# ActsAsReportable
#
# Mark your model with 'acts_as_reportable' to be included in the reports

module ActsAsReportable
  extend ActiveSupport::Concern

  module Base
    def acts_as_reportable(options = nil)
      include ::ActsAsReportable
    end
  end

  module ClassMethods
    def acts_as_reportable?; true; end
  end

  # Instance Methods

  def reportable_attributes
    (Effective::Resource.new(self).attributes.keys + [self.class.primary_key.to_sym]).sort
  end

  def reportable_scopes
    #[:all, :active, :inactive, with_first_name: :string]
    []
  end

end
