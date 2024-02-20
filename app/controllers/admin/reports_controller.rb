module Admin
  class ReportsController < ApplicationController
    before_action(:authenticate_user!) if defined?(Devise)
    before_action { EffectiveResources.authorize!(self, :admin, :effective_reports) }

    include Effective::CrudController

    submit :save, 'Save'
    submit :save, 'Save and View', redirect: -> { effective_reports.admin_report_path(resource) }
    submit :save, 'Duplicate', only: :edit, redirect: -> { effective_reports.new_admin_report_path(duplicate_id: resource.id) }

    private

    def permitted_params
      model = (params.key?(:effective_report) ? :effective_report: :report)
      params.require(model).permit!
    end

  end
end
