require "thor"
require "dotenv"
require "kamal_easy/config"

module KamalEasy
  class CLI < Thor
    check_unknown_options!

    class_option :uat, type: :boolean, desc: "Run command in UAT environment", default: false
    class_option :staging, type: :boolean, desc: "Run command in Staging environment", default: false
    class_option :prod, type: :boolean, desc: "Run command in Production environment", default: false
    class_option :production, type: :boolean, desc: "Alias for --prod", default: false

    desc "install", "Generate configuration file"
    def install
      config_path = "config/kamal-easy.yml"
      if File.exist?(config_path)
        puts "⚠️  #{config_path} already exists."
      else
        template = <<~YAML
          environments:
            uat:
              env_file: .env.uat
              credentials_file: config/credentials/uat.yml.enc
            staging:
              env_file: .env.staging
              credentials_file: config/credentials/staging.yml.enc
            production:
              env_file: .env.production
              credentials_file: config/credentials/production.yml.enc

          components:
            backend:
              path: .
              kamal_cmd: "bundle exec kamal"
              container_name_pattern: "your-app-backend-api"
              mandatory_files:
                - config/deploy.yml
                - Dockerfile
            frontend:
              path: ../your-app-frontend
              kamal_cmd: "kamal"
              mandatory_files:
                - config/deploy.yml
        YAML
        File.write(config_path, template)
        puts "✅ Created #{config_path}"
      end
    end

    desc "deploy [COMPONENT]", "Deploy specific component or everything"
    method_option :all, type: :boolean, desc: "Deploy all components"
    method_option :backend, type: :boolean, desc: "Deploy backend"
    method_option :frontend, type: :boolean, desc: "Deploy frontend"
    method_option :db, type: :boolean, desc: "Restart database"
    def deploy
      config = KamalEasy::Config.load
      env_key, env_vars = load_environment(config)
      
      if options[:all]
        deploy_backend(config, env_vars)
        deploy_frontend(config, env_vars)
        restart_db(config, env_vars)
      else
        deploy_backend(config, env_vars) if options[:backend]
        deploy_frontend(config, env_vars) if options[:frontend]
        restart_db(config, env_vars) if options[:db]
      end

      if !options[:all] && !options[:backend] && !options[:frontend] && !options[:db]
        help("deploy")
        exit(1)
      end
    end

    desc "logs", "View remote logs"
    method_option :follow, aliases: "-f", type: :boolean, desc: "Follow logs", default: false
    method_option :lines, aliases: "-n", type: :numeric, desc: "Number of lines", default: 100
    method_option :grep, aliases: "-g", type: :string, desc: "Filter pattern"
    def logs
      config = KamalEasy::Config.load
      env_key, env_vars = load_environment(config)
      
      backend_config = config.components["backend"]
      abort "❌ Backend component not configured" unless backend_config

      cmd = "#{backend_config['kamal_cmd']} app logs"
      cmd += " --lines #{options[:lines]}"
      cmd += " --follow" if options[:follow]
      cmd += " --grep '#{options[:grep]}'" if options[:grep]

      puts "📋 Fetching logs from #{env_key.upcase}..."
      exec_in_dir(backend_config["path"], env_vars, cmd)
    end

    desc "console", "Access remote Rails console"
    map ["c", "rails_console"] => :console
    def console
      config = KamalEasy::Config.load
      env_key, env_vars = load_environment(config)
      
      backend_config = config.components["backend"]
      abort "❌ Backend component not configured" unless backend_config
      
      container_name = backend_config["container_name_pattern"]
      
      cmd = "#{backend_config['kamal_cmd']} server exec -i 'docker exec -it $(docker ps -q -f name=#{container_name} | head -n1) bin/rails console'"
      
      puts "🔌 Connecting to #{env_key.upcase} Rails Console..."
      exec_in_dir(backend_config["path"], env_vars, cmd)
    end

    private

    def load_environment(config)
      is_prod = options[:prod] || options[:production]
      is_uat = options[:uat]
      is_staging = options[:staging]

      if [is_prod, is_uat, is_staging].count(true) > 1
        abort "❌ Error: Cannot target multiple environments simultaneously."
      end

      unless is_prod || is_uat || is_staging
        puts "ℹ️  No environment flag provided. Using current process environment..."
        return [nil, {}] 
      end

      env_key = if is_prod
                  "production"
                elsif is_staging
                  "staging"
                else
                  "uat"
                end

      env_config = config.env_config(env_key)
      env_file = env_config["env_file"]

      unless File.exist?(env_file)
         abort "❌ Error: Environment file #{env_file} not found."
      end

      puts "📖 Loading configuration from #{env_file}..."
      [env_key, Dotenv.parse(env_file)]
    end

    def deploy_backend(config, env_vars)
      puts "🚀 Deploying Backend..."
      comp = config.components["backend"]
      validate_mandatory_files(comp, comp["path"])
      exec_in_dir(comp["path"], env_vars, "#{comp['kamal_cmd']} deploy")
    end

    def deploy_frontend(config, env_vars)
      puts "🚀 Deploying Frontend..."
      comp = config.components["frontend"]
      validate_mandatory_files(comp, comp["path"])
      exec_in_dir(comp["path"], env_vars, "#{comp['kamal_cmd']} deploy")
    end

    def restart_db(config, env_vars)
      puts "🔄 Restarting Database..."
      comp = config.components["backend"]
      exec_in_dir(comp["path"], env_vars, "#{comp['kamal_cmd']} accessory reboot db")
    end

    def validate_mandatory_files(component_config, path)
      return unless component_config["mandatory_files"]
      
      Dir.chdir(path) do
        component_config["mandatory_files"].each do |file|
          unless File.exist?(file)
            abort "❌ Error: Mandatory file '#{file}' missing in #{path}"
          end
        end
      end
    end

    def exec_in_dir(dir, env_vars, cmd)
      Dir.chdir(dir) do
        unless system(env_vars, cmd)
          abort "❌ Command failed: #{cmd}"
        end
      end
    end
  end
end
