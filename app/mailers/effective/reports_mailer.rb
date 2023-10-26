module Effective
  class ReportsMailer < EffectiveReports.parent_mailer_class

    include EffectiveMailer
    #include EffectiveEmailTemplatesMailer

    # def reports_submitted(resource, opts = {})
    #   @assigns = assigns_for(resource)
    #   @applicant = resource

    #   subject = subject_for(__method__, "Reports Submitted - #{resource}", resource, opts)
    #   headers = headers_for(resource, opts)

    #   mail(to: resource.user.email, subject: subject, **headers)
    # end

    protected

    def assigns_for(resource)
      if resource.kind_of?(Effective::Reports)
        return reports_assigns(resource)
      end

      raise('unexpected resource')
    end

    def reports_assigns(resource)
      raise('expected an reports') unless resource.class.respond_to?(:effective_reports_resource?)

      values = {
        date: reports.created_at.strftime('%F')
      }.compact

      { reports: values }
    end

  end
end
