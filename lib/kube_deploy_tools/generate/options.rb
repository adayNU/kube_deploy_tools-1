require 'optparse'

module KubeDeployTools
  class Generate::Optparser
    class Options
      attr_accessor :manifest_file, :input_path, :output_path, :file_filters, :print_flags_only, :literals

      def initialize
        self.input_path = File.join('kubernetes/')
        self.output_path = File.join('build', 'kubernetes')
        self.file_filters = []
        self.literals = {}
      end

      def define_options(parser)
        parser.on('-mMANIFEST', '--manifest MANIFEST', 'The configuration MANIFEST to render deploys with.') do |f|
          self.manifest_file = f
        end

        parser.on('-iPATH', '--input-path PATH', 'Path where Kubernetes manifests and manifest templates (.erb) are located.') do |p|
          self.input_path = p
        end

        parser.on('-oPATH', '--output-path PATH', 'Path where rendered manifests should be written.') do |p|
          self.output_path = p
        end

        parser.on('-p', '--print', 'Print all available ERB config values only.') do |p|
          self.print_flags_only = p
        end

        parser.on('--from-literal KEY=VALUE', "Specify a key and literal value in the ERB context e.g. mykey=myvalue") do |p|
          parts = p.split('=')
          raise ArgumentError, "Expected --from-literal to be in the format key=value, but got '#{p}'" if parts.length != 2
          key, value = parts
          self.literals[key] = value
        end

        parser.on('--include INCLUDE', "Include glob pattern. Example: --include=**/* will include every file. Default is ''.") do |p|
          self.file_filters.push(["include_files", p])
        end

        parser.on('--exclude EXCLUDE', "Exclude glob pattern. Example: --exclude=**/gazette/* will exclude every file in gazette folder. Default is ''.") do |p|
          self.file_filters.push(["exclude_files", p])
        end

        parser.on('--include-dir INCLUDE', "Recursively include all files in a directory and its subdirectories. Example: --include-dir=gazette/ (equivalent of --include=**/gazette/**/*)") do |p|
          self.file_filters.push(["include_dir", p])
        end

        parser.on('--exclude-dir EXCLUDE', "Recursively exclude all files in a directory and its subdirectories. Example: --exclude-dir=gazette/ (equivalent of --exclude=**/gazette/**/*)") do |p|
          self.file_filters.push(["exclude_dir", p])
        end
      end
    end

    def parse(args)
      @options = Options.new
      OptionParser.new do |parser|
        @options.define_options(parser)
        parser.parse(args)
      end
      @options
    end
  end
end
