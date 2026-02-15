require "yaml"
require "thor"

module KamalEasy
  class Config
    CONFIG_FILE = "config/kamal-easy.yml"

    def self.load
      unless File.exist?(CONFIG_FILE)
        abort "❌ Error: Configuration file #{CONFIG_FILE} not found. Run `kamal-easy install`."
      end
      new(YAML.load_file(CONFIG_FILE))
    end

    def initialize(data)
      @data = data
    end

    def environments
      @data["environments"] || {}
    end

    def components
      @data["components"] || {}
    end

    def env_config(env_name)
      config = environments[env_name.to_s]
      abort "❌ Error: Environment '#{env_name}' not defined in #{CONFIG_FILE}" unless config
      config
    end
  end
end
