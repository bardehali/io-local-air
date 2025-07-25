# The test environment is used exclusively to run your application's
# test suite. You never need to work with it otherwise. Remember that
# your test database is "scratch space" for the test suite and is wiped
# and recreated between test runs. Don't rely on the data there!

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  config.cache_classes = false
  config.action_view.cache_template_loading = true

  # Do not eager load code on boot. This avoids loading your whole application
  # just for the purpose of running a single test. If you are using a tool that
  # preloads Rails for running tests, you may have to set it to true.
  config.eager_load = false

  # Configure public file server for tests with Cache-Control for performance.
  config.public_file_server.enabled = true
  config.public_file_server.headers = {
    'Cache-Control' => "public, max-age=#{1.hour.to_i}"
  }

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false
  config.cache_store = :null_store

  # Raise exceptions instead of rendering exception templates.
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment.
  config.action_controller.allow_forgery_protection = false

  # Store uploaded files on the local file system in a temporary directory.
  config.active_storage.service = :test

  # ActionMailer
  config.action_mailer.perform_caching = false
  config.action_mailer.perform_deliveries = true
  config.action_mailer.raise_delivery_errors = true
  # mailcatcher
  config.action_mailer.smtp_settings = { :address => '127.0.0.1', :port => 1025 }
  config.action_mailer.default_url_options = {:host => 'http://127.0.0.1', :port => '3000', :protocol => 'http'}
  config.action_mailer.preview_path = "#{Rails.root}/tmp/mailers/previews"

  ActionMailer::Base.register_interceptor 'DynamicSmtpSettingsInterceptor'
  config.dynamic_smtp_settings = {
    'aliyun' => { :address => 'mail.aliyun.com', :port => 1025, user_name:'noreply@aliyun.ioffer.com' },
    'gmail' => { :address => 'gmail.google.com', :port => 1025, user_name:'noreply@gmail.ioffer.com' }
  }

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.

  config.action_mailer.delivery_method = :test

  # Print deprecation notices to the stderr.
  config.active_support.deprecation = :stderr

  # Raises error for missing translations.
  # config.action_view.raise_on_missing_translations = true
  config.middleware.insert_before Warden::Manager, ActionDispatch::Cookies
  config.middleware.insert_before Warden::Manager, ActionDispatch::Session::CookieStore
end
