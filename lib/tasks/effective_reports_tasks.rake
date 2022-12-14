namespace :effective_reports do

  # bundle exec rake effective_reports:seed
  task seed: :environment do
    load "#{__dir__}/../../db/seeds.rb"
  end

end
