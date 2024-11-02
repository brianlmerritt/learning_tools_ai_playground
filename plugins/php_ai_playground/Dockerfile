FROM php:8.2-cli

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Create and set the working directory
WORKDIR /home/phpdev/workspace

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    nano \
    libzip-dev \
    libxml2-dev \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libicu-dev \
    libonig-dev \
    libxslt1-dev \
    unzip \
    librabbitmq-dev \
    libssh-dev \
    gosu \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions required for Moodle and Laravel
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    intl \
    mysqli \
    pdo_mysql \
    zip \
    soap \
    xsl \
    opcache \
    gd \
    exif \
    bcmath \
    calendar \
    pcntl \
    sockets

# Install Redis and Xdebug
RUN pecl install redis \
    && pecl install xdebug \
    && docker-php-ext-enable redis xdebug

# Create a non-root user
RUN useradd -m -s /bin/bash phpdev

# Change ownership of the working directory to phpdev
RUN chown -R phpdev:phpdev /home/phpdev

# Switch to phpdev user
USER phpdev

CMD ["/bin/bash"]