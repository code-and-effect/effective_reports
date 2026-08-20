require 'effective_resources'
require 'effective_datatables'
require 'effective_reports/engine'
require 'effective_reports/version'

module EffectiveReports

  def self.config_keys
    [
      # Database Tables
      :reports_table_name, :report_columns_table_name, :report_scopes_table_name,

      :additional_class_names,

      # Effective Gem
      :layout,
      :mailer, :parent_mailer, :deliver_method, :mailer_layout, :mailer_sender, :mailer_froms, :mailer_admin, :mailer_subject
    ]
  end

  include EffectiveGem

  def self.reportable_classes
    names = []

    tenant = Tenant.module_name if defined?(Tenant)

    if defined?(Devise)
      names += [[tenant, 'User'].compact.join('::')]
    end

    if defined?(EffectiveMemberships)
      names += [
        ([tenant, 'Applicant'].compact.join('::')),
        ([tenant, 'ApplicantReference'].compact.join('::')),
        ([tenant, 'ApplicantReview'].compact.join('::')),
        "Effective::Fee",
        "Effective::Membership",
        "Effective::MembershipHistory"
      ]
    end

    if defined?(EffectiveCpd)
      names += [
        ([tenant, 'CpdAudit'].compact.join('::')),
        ([tenant, 'CpdAuditReview'].compact.join('::')),
        ([tenant, 'CpdStatement'].compact.join('::')),
        "Effective::CpdCategory",
        "Effective::CpdStatementActivity"
      ]
    end

    if defined?(EffectiveOrders)
      names += ['Effective::Order']
    end

    if additional_class_names.present?
      names += Array(additional_class_names)
    end

    # All Names into klasses
    klasses = names.uniq.sort.map(&:safe_constantize).compact

    klasses.select { |klass| klass.try(:acts_as_reportable?) }
  end

end
