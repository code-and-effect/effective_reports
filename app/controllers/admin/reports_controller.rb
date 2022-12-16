module Admin
  class ReportsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_reports) }

    include Effective::CrudController

    private

    def permitted_params
      model = (params.key?(:effective_report) ? :effective_report: :report)
      params.require(model).permit!
    end

  end
end
