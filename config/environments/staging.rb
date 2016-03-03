Hrguru::Application.configure do
  config.cache_classes = true
  config.eager_load = true
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true
  config.serve_static_files = false
  config.assets.js_compressor = :uglifier
  config.assets.css_compressor = :sass
  config.assets.compress = true
  config.assets.compile = false
  config.assets.digest = true
  config.assets.version = '1.0'
  config.log_level = :info
  config.i18n.fallbacks = true
  config.active_support.deprecation = :notify
  config.action_mailer.default_url_options = { host: AppConfig.domain }
  GA.tracker = 'UA-35395053-13'
  config.active_record.raise_in_transactional_callbacks = true

  config.lograge.enabled = true
  config.lograge.custom_options = lambda do |event|
    { params: event.payload[:params].reject { |k| %w(controller action).include? k } }
  end

  ActionMailer::Base.smtp_settings = {
    :address        => 'smtp.sendgrid.net',
    :port           => '587',
    :authentication => :plain,
    :user_name      => AppConfig.sendgrid.login,
    :password       => AppConfig.sendgrid.password,
    :domain         => AppConfig.sendgrid.domain,
    :enable_starttls_auto => true
  }
end
