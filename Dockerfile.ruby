FROM ruby:2.7.8

# Install dependencies
RUN apt-get update && apt-get install -y \
    nodejs \
    libxml2-dev \
    libxslt-dev \
    yarn \
    libc-dev \
    rsync \
    nginx \
    puma \
    default-mysql-client \
    ca-certificates \
    curl \
    git \
    gnupg \
    imagemagick \
    libffi-dev \
    openssh-client \
    tzdata

# Set environment variables
ENV APP_PATH /var/www/shoppn_spree
ENV PORT 8000
ENV RAILS_ENV development
ENV NODE_ENV development

WORKDIR $APP_PATH

# Copy Gemfile and Gemfile.lock
COPY Gemfile $APP_PATH/Gemfile
COPY Gemfile.lock $APP_PATH/Gemfile.lock

# Install Bundler
RUN gem install bundler -v 2.4.22

# Install gems
RUN bundle install --without production staging

# Expose the port
EXPOSE $PORT

# Default command to run Rails server
CMD ["bundle", "exec", "rails", "server", "-p", "8000", "-b", "0.0.0.0"]
