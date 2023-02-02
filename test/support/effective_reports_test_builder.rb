module EffectiveReportsTestBuilder

  def build_report
    user = build_user()

    report = Effective::Report.new(title: 'Test Report', reportable_class_name: 'User')

    user.reportable_attributes.slice(:email, :first_name, :last_name).each do |name, as|
      report.report_columns.build(name: name, as: as)
    end

    report
  end

  def create_user!
    build_user.tap { |user| user.save! }
  end

  def build_user
    @user_index ||= 0
    @user_index += 1

    User.new(
      email: "user#{@user_index}@example.com",
      password: 'rubicon2020',
      password_confirmation: 'rubicon2020',
      first_name: 'Test',
      last_name: 'User'
    )
  end

  def build_user_with_address
    user = build_user()

    user.addresses.build(
      addressable: user,
      category: 'billing',
      full_name: 'Test User',
      address1: '1234 Fake Street',
      city: 'Victoria',
      state_code: 'BC',
      country_code: 'CA',
      postal_code: 'H0H0H0'
    )

    user.save!
    user
  end


end
