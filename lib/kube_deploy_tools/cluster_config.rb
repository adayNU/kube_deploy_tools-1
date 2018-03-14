require 'digest'
require 'etc'
require 'time'
require 'erb'

module KubeDeployTools
  # Default method to derive a tag name based on the current environment.
  # An image is tagged for the current branch, git sha, and Jenkins build id.
  def self.tag_from_local_env
    codestamp = (ENV['GIT_COMMIT'] || `git rev-parse HEAD`.rstrip)[0...7]

    branch = ENV['GIT_BRANCH'] || `git rev-parse --abbrev-ref HEAD`.rstrip
    if branch.start_with?('origin/')
      branch = branch['origin/'.size..-1]
    end

    # From the Docker docs:
    # "A tag name must be valid ASCII and may contain lowercase and uppercase
    # letters, digits, underscores, periods and dashes. A tag name may not
    # start with a period or a dash and may contain a maximum of 128
    # characters."
    branch = branch.gsub(/[^A-Za-z0-9_\.\-\.]/, '_')
    if branch[0] == '.' || branch[0] == '-'
      # We could do something more clever here. Not worth it right now.
      raise "First char of branch name must be alphanumeric: #{branch}"
    end

    # Include the Jenkins build ID, in the case that there are
    # multiple builds at the same git branch and git commit,
    # but with different dependencies.
    build = ENV.fetch('BUILD_ID', 'dev')[0...5]

    # Docker maximum tag length is 128 characters long.
    # Kubernetes maximum label length is 63 characters long. Go with that.
    # 63 >= max 49 char branch + 1 char hyphen + 7 char codestamp + max 5 char build id
    "#{branch[0...49]}-#{codestamp}-#{build}"
  end

  REGISTRIES = {
    'aws' => {
      'driver' => 'aws',
      'prefix' => '***REMOVED***',
      'region' => 'us-west-2',
    },
    'local' => {
      'driver' => 'noop',
      'prefix' => 'local-registry',
    },
    'gcp' => {
      'driver' => 'gcp',
      'prefix' => 'gcr.io/pippio-production',
    }
  }.freeze

  PREFIX_TO_REGISTRY = Hash[REGISTRIES.map {|reg, info| [info['prefix'], reg]}]

  DEFAULT_REGISTRY = REGISTRIES['aws']['prefix']

  CLUSTERS = {
    'local' => {
      'staging' => {
        'kube_context' => 'minikube',
        'flags' => {
          'cloud' => 'local',
          'image_registry' => 'local-registry',
          'kubernetes_major_version' => '1',
          'kubernetes_minor_version' => '7',
          'pull_policy' => 'IfNotPresent',
        }
      },
    },
    'gcp' => {
      'prod' => {
        'kube_context' => 'production',
        'flags' => {
          'cloud' => 'gcp',
          'image_registry' => 'gcr.io/pippio-production',
          'kubernetes_major_version' => '1',
          'kubernetes_minor_version' => '6',
          'pull_policy' => 'Always',
        }
      }
    },
    'us-east-1' => {
      'prod_kops' => {
        'kube_context' => '<%= username %>@prod.us-east-1.k8s.***REMOVED***',
        'flags' => {
          'cloud' => 'aws',
          'kubernetes_major_version' => '1',
          'kubernetes_minor_version' => '7',
          'pull_policy' => 'Always',
        }
      },
      'prod' => {
        'kube_context' => '<%= username %>@us-east-1-prod.k8s.***REMOVED***',
        'flags' => {
          'cloud' => 'aws',
          'kubernetes_major_version' => '1',
          'kubernetes_minor_version' => '8',
          'pull_policy' => 'Always',
        }
      },
      'staging' => {
        'kube_context' => '<%= username %>@us-east-1-staging.k8s.***REMOVED***',
        'flags' => {
          'cloud' => 'aws',
          'kubernetes_major_version' => '1',
          'kubernetes_minor_version' => '8',
          'pull_policy' => 'Always',
        }
      }
    },
    'us-west-2' => {
      'prod' => {
        'kube_context' => '<%= username %>@us-west-2-prod.k8s.***REMOVED***',
        'flags' => {
          'cloud' => 'aws',
          'kubernetes_major_version' => '1',
          'kubernetes_minor_version' => '8',
          'pull_policy' => 'Always',
        }
      },
      'staging' => {
        'kube_context' => '<%= username %>@us-west-2-staging.k8s.***REMOVED***',
        'flags' => {
          'cloud' => 'aws',
          'kubernetes_major_version' => '1',
          'kubernetes_minor_version' => '8',
          'pull_policy' => 'Always',
        }
      }
    },
    'eu-west-1' => {
      'prod' => {
        'kube_context' => '<%= username %>@prod.eu-west-1.k8s.eu.***REMOVED***',
        'flags' => {
          'cloud' => 'aws',
          'kubernetes_major_version' => '1',
          'kubernetes_minor_version' => '7',
          'pull_policy' => 'Always',
        }
      },
      'staging' => {
        'kube_context' => '<%= username %>@staging.eu-west-1.k8s.eu.***REMOVED***',
        'flags' => {
          'cloud' => 'aws',
          'kubernetes_major_version' => '1',
          'kubernetes_minor_version' => '7',
          'pull_policy' => 'Always',
        }
      }
    },
    'colo-service' => {
      'prod' => {
        'kube_context' => '<%= username %>@prod.service',
        'flags' => {
          'cloud' => 'colo',
          'kubernetes_major_version' => '1',
          'kubernetes_minor_version' => '7',
          'pull_policy' => 'Always',
        }
      },
      'staging' => {
        'kube_context' => '<%= username %>@staging.service',
        'flags' => {
          'cloud' => 'colo',
          'kubernetes_major_version' => '1',
          'kubernetes_minor_version' => '7',
          'pull_policy' => 'Always',
        }
      }
    }
  }.freeze

  def self.kube_context(target:, environment:)
    b = binding
    b.local_variable_set(:username, Etc.getlogin)
    renderer = ERB.new(CLUSTERS[target][environment]['kube_context'])

    renderer.result(b)
  end

end

