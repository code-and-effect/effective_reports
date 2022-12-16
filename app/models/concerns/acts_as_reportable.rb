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

  # { id: :integer, price: :price, created_at: :date }
  def reportable_attributes
    all_reportable_attributes || {}
  end

  # { active: nil, inactive: nil, with_first_name: :string, not_in_good_standing: :boolean }
  def reportable_scopes
    {}
  end

  private

  def all_reportable_attributes
    columns = (self.class.columns_hash rescue {})
    names = (self.attributes rescue {})

    atts = names.inject({}) do |h, (name, _)|
      type = columns[name].type

      type = case type
        when :datetime then :date
        when :integer then (name.include?('price') ? :price : :integer)
        when :text then :string
        else type
      end

      h[name.to_sym] = type; h
    end

    # TODO: figure out belongs_to datatypes
    atts
  end

end
