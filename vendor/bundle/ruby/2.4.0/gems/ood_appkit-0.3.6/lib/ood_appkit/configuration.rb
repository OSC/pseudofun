require 'redcarpet'
require 'ostruct'

module OodAppkit
  # An object that stores and adds configuration options.
  module Configuration
    # Location where app data is stored on local filesystem
    # @return [Pathname, nil] path to app data
    def dataroot
      Pathname.new(@dataroot).expand_path if @dataroot
    end
    attr_writer :dataroot

    # Cluster information for local HPC center
    # @return [OpenStruct] hash of available clusters
    attr_accessor :clusters

    # A markdown renderer used when rendering `*.md` or `*.markdown` views
    # @return [Redcarpet::Markdown] the markdown renderer used
    attr_accessor :markdown

    # Public assets url handler
    # @return [PublicUrl] the url handler for the publicly available assets
    attr_accessor :public

    # System dashboard app url handler
    # @return [DashboardUrl] the url handler for the system dashboard app
    attr_accessor :dashboard

    # System shell app url handler
    # @return [ShellUrl] the url handler for the system shell app
    attr_accessor :shell

    # System files app url handler
    # @return [FilesUrl] the url handler for the system files app
    attr_accessor :files

    # System file editor app url handler
    # @return [EditorUrl] the url handler for the system file editor app
    attr_accessor :editor

    # Whether to auto-generate default routes for helpful apps/features
    # @return [OpenStruct] whether to generate routes for apps
    attr_accessor :routes

    # Override Boostrap SASS variables in app
    # @return [OpenStruct] bootstrap variables to override
    attr_accessor :bootstrap

    # Set to false if you don't want Rails.logger formatter
    # to use LogFormatter and lograge to be enabled automatically
    # @return [boolean] whether to use OodAppkit log formatting in production
    attr_accessor :enable_log_formatter

    # Customize configuration for this object.
    # @yield [self]
    def configure
      yield self
    end

    # Sets the default configuration for this object.
    # @return [void]
    def set_default_configuration
      ActiveSupport::Deprecation.warn("The environment variable RAILS_DATAROOT will be deprecated in an upcoming release, please use OOD_DATAROOT instead.") if ENV['RAILS_DATAROOT']
      self.dataroot = ENV['OOD_DATAROOT'] || ENV['RAILS_DATAROOT']
      self.dataroot ||= "~/#{ENV['OOD_PORTAL'] || "ondemand"}/data/#{ENV['APP_TOKEN']}" if ENV['APP_TOKEN']

      # Initialize list of available clusters
      c_config = Pathname.new(ENV['OOD_CLUSTERS'] || '/etc/ood/config/clusters.d')
      self.clusters = Clusters.new(
        begin
          ConfigParser.parse(config: c_config).map { |k, v| ClusterDecorator.new(id: k.to_sym, **v) }
        rescue ConfigParser::InvalidConfigPath
          STDERR.puts "Invalid cluster config specified: #{c_config}"
          []
        end
      )

      # Add markdown template support
      self.markdown = Redcarpet::Markdown.new(
        Redcarpet::Render::HTML,
        autolink: true,
        tables: true,
        strikethrough: true,
        fenced_code_blocks: true,
        no_intra_emphasis: true
      )

      # Initialize URL handlers for system apps
      self.public    = Urls::Public.new(
        title:    ENV['OOD_PUBLIC_TITLE'] || 'Public Assets',
        base_url: ENV['OOD_PUBLIC_URL']   || '/public'
      )
      self.dashboard = Urls::Dashboard.new(
        title:    ENV['OOD_DASHBOARD_TITLE'] || 'Open OnDemand',
        base_url: ENV['OOD_DASHBOARD_URL']   || '/pun/sys/dashboard'
      )
      self.shell     = Urls::Shell.new(
        title:    ENV['OOD_SHELL_TITLE'] || 'Shell',
        base_url: ENV['OOD_SHELL_URL']   || '/pun/sys/shell'
      )
      self.files     = Urls::Files.new(
        title:    ENV['OOD_FILES_TITLE'] || 'Files',
        base_url: ENV['OOD_FILES_URL']   || '/pun/sys/files'
      )
      self.editor    = Urls::Editor.new(
        title:    ENV['OOD_EDITOR_TITLE'] || 'Editor',
        base_url: ENV['OOD_EDITOR_URL']   || '/pun/sys/file-editor'
      )

      # Add routes for useful features
      self.routes = OpenStruct.new(
        files_rack_app: true,
        wiki: true
      )

      # Override Bootstrap SASS variables
      self.bootstrap = OpenStruct.new(
        bg_inverse_color: '#53565a',  # not an actual Bootstrap variable
        navbar_dark_color: '#ffffff',
        navbar_dark_hover_color: 'darken($navbar-dark-color, 20%)'
      )
      ENV.each {|k, v| /^BOOTSTRAP_(?<name>.+)$/ =~ k ? self.bootstrap[name.downcase] = v : nil}

      self.enable_log_formatter = ::Rails.env.production?
    end
  end
end
