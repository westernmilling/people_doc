[![CircleCI](https://circleci.com/gh/westernmilling/people_doc.svg?style=svg&circle-token=f5b3c58d525d1d975f632b779221c1588cfeba97)](https://circleci.com/gh/westernmilling/people_doc)
[![Maintainability](https://api.codeclimate.com/v1/badges/6ade98502a90fe627e29/maintainability)](https://codeclimate.com/github/westernmilling/people_doc/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/6ade98502a90fe627e29/test_coverage)](https://codeclimate.com/github/westernmilling/people_doc/test_coverage)

# PeopleDoc
Basic Ruby client library for the PeopleDoc REST APIs


## Installation

Add this line to your application's Gemfile:

```ruby
gem 'people_doc'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install people_doc

## Usage

### RESTv1

```ruby
client = PeopleDoc::V1::Client.new(
  api_key: 'api_key'
  base_url: 'https://api.staging.us.people-doc.com'
  logger: Logger.new(STDOUT)
)

response = client.get('???')
```

### RESTv2

```ruby
client = PeopleDoc::V2::Client.new(
  config.application_id = 'application_id'
  config.application_secret = 'application_secret'
  config.base_url = 'https://apis.staging.us.people-doc.com'
  config.client_id = 'client_id'
  config.logger = Logger.new(STDOUT)
)
```

## Supported Functionality

### RESTv1

### RESTv2

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/westernmilling/adp_client. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the AdpClient project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/westernmilling/adp_client/blob/master/CODE_OF_CONDUCT.md).
