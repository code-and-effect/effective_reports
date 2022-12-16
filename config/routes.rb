# frozen_string_literal: true

Rails.application.routes.draw do
  mount EffectiveReports::Engine => '/', as: 'effective_reports'
end

EffectiveReports::Engine.routes.draw do
  # Public routes
  scope module: 'effective' do
  end

  namespace :admin do
    resources :reports
  end

end
