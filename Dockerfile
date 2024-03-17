# Build image for Vapor Swift project
FROM swift:5.8-jammy as vapor_build

# Install OS updates and dependencies
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y\
    && apt-get -q install -y \
      python3 \
      python3-pip \
      python3-dev \
      build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set up the working directory
WORKDIR /app

# Copy only the Swift package files to leverage Docker caching
COPY Package.* ./

# Resolve Swift package dependencies
RUN swift package resolve

# Copy the entire source code
COPY . .

# Build the Vapor project
RUN swift build -c release --static-swift-stdlib

# ================================
# Final Docker image for Vapor
# ================================
FROM ubuntu:jammy

# Install essential system packages
RUN export DEBIAN_FRONTEND=noninteractive DEBCONF_NONINTERACTIVE_SEEN=true \
    && apt-get -q update \
    && apt-get -q dist-upgrade -y \
    && apt-get -q install -y \
      ca-certificates \
      tzdata \
      libcurl4 \
      libxml2 \
    && rm -r /var/lib/apt/lists/*

# Create a user for running the Vapor app
RUN useradd --user-group --create-home --system --skel /dev/null --home-dir /app vapor

# Switch to the new home directory
WORKDIR /app

# Copy the built executable from the builder
COPY --from=vapor_build /app/.build/release /app

# Ensure all further commands run as the vapor user
USER vapor:vapor

# Expose port for Vapor app
EXPOSE 8080

# Start the Vapor service
CMD ["./Run"]
