# frozen_string_literal: true

module LazyInitializers
  def self.load_all!
    Dir["#{APP_ROOT}/initializers/*.rb"].sort.each { |file| require file } if Dir.exist?("#{APP_ROOT}/initializers")
  end
end
