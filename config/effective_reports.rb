EffectiveReports.setup do |config|
  # Layout Settings
  # Configure the Layout per controller, or all at once
  # config.layout = { application: 'application', admin: 'admin' }

  # Reports Settings
  # Configure the class responsible for the reports.
  # This should extend from Effective::Reports
  # config.reports_class_name = 'Effective::Reports'

  # Additional Reportable Class Names
  # The gem automatically includes the tenant user, common tenant-overridden
  # models, and shared Effective models. Add application-specific models here.
  # They must define acts_as_reportable to be included.
  config.additional_class_names = []

  # Mailer Settings
  # Please see config/initializers/effective_resources.rb for default effective_* gem mailer settings
  #
  # Configure the class responsible to send e-mails.
  # config.mailer = 'Effective::ReportsMailer'
  #
  # Override effective_resource mailer defaults
  #
  # config.parent_mailer = nil      # The parent class responsible for sending emails
  # config.deliver_method = nil     # The deliver method, deliver_later or deliver_now
  # config.mailer_layout = nil      # Default mailer layout
  # config.mailer_sender = nil      # Default From value
  # config.mailer_froms = nil       # Default Froms collection
  # config.mailer_admin = nil       # Default To value for Admin correspondence
  # config.mailer_subject = nil     # Proc.new method used to customize Subject
end
