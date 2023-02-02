require 'test_helper'

class ReportsTest < ActiveSupport::TestCase
  test 'user factory' do
    user = build_user()
    assert user.valid?

    assert user.class.acts_as_reportable?
    assert user.reportable_attributes.kind_of?(Hash)

    assert user.reportable_attributes.present?

    assert_equal :string, user.reportable_attributes[:first_name]
    assert_equal :string, user.reportable_attributes[:last_name]
    assert_equal :has_many, user.reportable_attributes[:addresses]
  end

  test 'report factory' do
    report = build_report()
    assert report.valid?
  end

  test 'report rows' do
    report = build_report()

    users = 5.times.map { create_user! }
    assert_equal 5, report.collection.count
  end

  test 'report email column' do
    report = build_report()

    column = report.email_report_column
    assert column.present?

    assert_equal 'email', column.name
  end

  test 'filter by report email column' do
    report = build_report()

    users = 5.times.map { create_user! }
    assert_equal 5, report.collection.count

    column = report.email_report_column
    assert_equal 'email', column.name

    column.update!(filter: true, operation: :eq, value_string: users.first.email)

    assert_equal 1, report.collection.count
    assert_equal users.first, report.collection.first
  end

end
