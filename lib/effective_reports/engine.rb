module EffectiveReports
  class Engine < ::Rails::Engine
    engine_name 'effective_reports'

    # Set up our default configuration options.
    initializer 'effective_reports.defaults', before: :load_config_initializers do |app|
      eval File.read("#{config.root}/config/effective_reports.rb")
    end

    # Include acts_as_reportable concern and allow any ActiveRecord object to call it
    initializer 'effective_reports.active_record' do |app|
      app.config.to_prepare do
        ActiveRecord::Base.extend(ActsAsReportable::Base)
      end
    end

  end
end
