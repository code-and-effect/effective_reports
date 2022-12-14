require 'effective_resources'
require 'effective_datatables'
require 'effective_reports/engine'
require 'effective_reports/version'

module EffectiveReports

  def self.config_keys
    [
      :layout,
      :mailer, :parent_mailer, :deliver_method, :mailer_layout, :mailer_sender, :mailer_admin, :mailer_subject, :use_effective_email_templates
    ]
  end

  include EffectiveGem

end
